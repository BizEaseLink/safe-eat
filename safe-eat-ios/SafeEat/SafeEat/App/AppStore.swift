import Foundation
import Combine
import UIKit

enum AppRootTab: Hashable {
    case home
    case history
    case profile
}

@MainActor
final class AppStore: ObservableObject {
    @Published var hasBootstrapped = false
    @Published var session: AuthSession?
    @Published var profile: UserProfile?
    @Published var localHistory: [LocalHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRootTab: AppRootTab = .home
    @Published var hasCompletedOnboarding: Bool
    @Published var showLoginPrompt = false

    let api: SafeEatAPI
    private let sessionStore: AuthSessionStore
    private let historyStore: LocalHistoryStore
    private var refreshTask: Task<AuthSession, Error>?

    private static let onboardingKey = "safe-eat.onboarding.completed"

    init(
        api: SafeEatAPI,
        sessionStore: AuthSessionStore,
        historyStore: LocalHistoryStore
    ) {
        self.api = api
        self.sessionStore = sessionStore
        self.historyStore = historyStore
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
    }

    convenience init() {
        self.init(
            api: SafeEatAPI(),
            sessionStore: AuthSessionStore(),
            historyStore: LocalHistoryStore()
        )
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
    }

    func requireLogin() {
        guard session == nil else { return }
        showLoginPrompt = true
    }

    func bootstrap() async {
        defer { hasBootstrapped = true }
        session = sessionStore.load()
        reloadLocalHistory()

        if session != nil, !requiresPhoneBinding {
            await refreshProfile()
        }
    }

    func sendSMS(phone: String) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone)
    }

    func login(phone: String, code: String) async {
        await handleLoginTask {
            try await api.login(phone: phone, code: code)
        }
    }

    func loginWithPassword(phone: String, password: String) async {
        await handleLoginTask {
            try await api.loginWithPassword(phone: phone, password: password)
        }
    }

    func registerWithPassword(phone: String, code: String, password: String) async {
        await handleLoginTask {
            try await api.setPassword(phone: phone, code: code, password: password)
        }
    }

    func loginWithApple(appleSub: String, displayName: String?) async {
        await handleLoginTask {
            try await api.appleLogin(appleSub: appleSub, displayName: displayName)
        }
    }

    func bindApplePhone(phone: String, code: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let boundSession = try await authorizedRequest { token in
                try await api.bindApplePhone(accessToken: token, phone: phone, code: code)
            }
            finishLogin(with: boundSession)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshProfile() async {
        do {
            profile = try await authorizedRequest { token in
                try await api.getProfile(accessToken: token)
            }
        } catch {
            handleAPIError(error)
        }
    }

    func logout(message: String? = nil) {
        refreshTask = nil
        session = nil
        profile = nil
        selectedRootTab = .home
        sessionStore.clear()
        if let message {
            errorMessage = message
        }
    }

    func performLogout() async {
        let refreshToken = session?.refreshToken
        logout()

        guard let refreshToken else { return }
        try? await api.logout(refreshToken)
    }

    func updateUserProfile(_ payload: UserProfileUpdatePayload) async throws -> UserProfile {
        let updated = try await authorizedRequest { token in
            try await api.updateProfile(accessToken: token, payload: payload)
        }
        profile = updated
        return updated
    }

    func updateUserHealthProfile(_ payload: UserHealthProfileUpdatePayload) async throws -> UserProfile {
        let updated = try await authorizedRequest { token in
            try await api.updateHealthProfile(accessToken: token, payload: payload)
        }
        profile = updated
        return updated
    }

    func updateAvatar(_ image: UIImage) async throws -> UserProfile {
        guard let imageData = image.avatarUploadData() else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.avatarCompressionFailed))
        }

        let updated = try await authorizedRequest { token in
            try await api.updateAvatar(accessToken: token, imageData: imageData)
        }
        profile = updated
        return updated
    }

    func createMembershipOrder(planId: String, channel: String) async throws -> MembershipOrderResult {
        try await authorizedRequest { token in
            try await api.createMembershipOrder(
                accessToken: token,
                payload: MembershipOrderPayload(planId: planId, channel: channel)
            )
        }
    }

    func clearLocalCache() {
        historyStore.clearAll()
        LocalImageLoader.clearAllCaches()
        reloadLocalHistory()
    }

    var localCacheSizeText: String {
        ByteCountFormatter.string(fromByteCount: historyStore.storageUsageBytes(), countStyle: .file)
    }

    var localCacheCount: Int {
        localHistory.count
    }

    func appendHistoryItem(_ item: LocalHistoryItem) {
        historyStore.append(item)
        reloadLocalHistory()
    }

    func removeHistoryItem(_ item: LocalHistoryItem) {
        historyStore.remove(item)
        reloadLocalHistory()
    }

    func recordRecognition(
        _ recognition: RecognitionRecord,
        originalImage: UIImage,
        previewImage: UIImage?,
        rawImage: UIImage? = nil
    ) throws -> LocalHistoryItem {
        guard let originalImageData = originalImage.jpegDataForUpload() else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveOriginalFailed))
        }
        guard let rawImageData = (rawImage ?? originalImage).jpegDataForUpload() else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveHiddenOriginalFailed))
        }

        let previewImageData = previewImage?.pngDataForPreview()
        let saved = try historyStore.saveRecognitionImages(
            recognitionId: recognition.id,
            originalImageData: originalImageData,
            previewImageData: previewImageData,
            rawImageData: rawImageData
        )
        let item = LocalHistoryItem(
            recognitionId: recognition.id,
            originalImageUri: saved.originalImageUri,
            previewImageUri: saved.previewImageUri,
            rawImageUri: saved.rawImageUri,
            recognizedName: recognition.recognizedName,
            adviceLevel: recognition.adviceLevel ?? "unknown",
            adviceText: recognition.adviceText,
            foodScore: recognition.foodScore ?? 0,
            createdAt: recognition.createdAt ?? Date(),
            cachedRecognition: recognition,
            imageRotationQuarterTurns: 0
        )
        appendHistoryItem(item)
        return item
    }

    func historyItem(id: LocalHistoryItem.ID) -> LocalHistoryItem? {
        localHistory.first(where: { $0.id == id })
    }

    func cacheRecognition(_ recognition: RecognitionRecord, for itemID: LocalHistoryItem.ID) {
        guard var item = historyItem(id: itemID) else { return }
        item.cachedRecognition = recognition
        item.recognizedName = recognition.recognizedName
        item.adviceLevel = recognition.adviceLevel ?? item.adviceLevel
        item.adviceText = recognition.adviceText ?? item.adviceText
        item.foodScore = recognition.foodScore ?? item.foodScore
        updateHistoryItem(item)
    }

    func fetchRecognitionDetailIfNeeded(for itemID: LocalHistoryItem.ID) async -> RecognitionRecord? {
        guard let item = historyItem(id: itemID) else { return nil }
        if let cached = item.cachedRecognition {
            return cached
        }

        do {
            let detail = try await authorizedRequest { token in
                try await api.getRecognition(accessToken: token, recognitionId: item.recognitionId)
            }
            cacheRecognition(detail, for: itemID)
            return detail
        } catch {
            handleAPIError(error)
            return nil
        }
    }

    func rotateHistoryItemClockwise(_ itemID: LocalHistoryItem.ID) throws {
        guard var item = historyItem(id: itemID) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.localRecordMissing))
        }
        guard let originalImage = LocalImageLoader.loadOriginalImage(for: item)?.rotated(clockwise: true) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.localOriginalMissing))
        }

        let rotatedPreview = LocalImageLoader.loadImage(from: item.previewImageUri)?.rotated(clockwise: true)
        guard let originalImageData = originalImage.jpegDataForUpload() else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveRotatedOriginalFailed))
        }

        let previewImageData = rotatedPreview?.pngDataForPreview()
        try historyStore.replaceRecognitionImages(
            for: item,
            originalImageData: originalImageData,
            previewImageData: previewImageData
        )

        item.imageRotationQuarterTurns = (item.imageRotationQuarterTurns + 1) % 4
        updateHistoryItem(item)
        LocalImageLoader.invalidateCache(for: item)
        reloadLocalHistory()
    }

    func authorizedRequest<T>(_ operation: (String) async throws -> T) async throws -> T {
        let token = try currentAccessToken()

        do {
            return try await operation(token)
        } catch {
            if isUnauthorizedError(error) {
                let refreshedSession = try await refreshSessionIfNeeded()
                return try await operation(refreshedSession.accessToken)
            }
            throw error
        }
    }

    func handleAPIError(_ error: Error) {
        guard !isUnauthorizedError(error) else { return }
        errorMessage = error.localizedDescription
    }

    private func isUnauthorizedError(_ error: Error) -> Bool {
        guard case let APIError.server(status, _) = error else {
            return false
        }
        return status == 401
    }

    private func currentAccessToken() throws -> String {
        guard let token = session?.accessToken else {
            showLoginPrompt = true
            throw APIError.server(status: 401, message: SafeEatL10n.text(L10nKey.Errors.sessionExpired))
        }
        return token
    }

    private func refreshSessionIfNeeded() async throws -> AuthSession {
        if let refreshTask {
            return try await refreshTask.value
        }

        guard let currentSession = session else {
            let expiredError = APIError.server(status: 401, message: SafeEatL10n.text(L10nKey.Errors.sessionExpired))
            logout(message: expiredError.localizedDescription)
            throw expiredError
        }

        let task = Task<AuthSession, Error> { [api] in
            let refreshed = try await api.refreshToken(currentSession.refreshToken)
            return AuthSession(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                requiresPhoneBinding: currentSession.requiresPhoneBinding
            )
        }
        refreshTask = task

        do {
            let refreshedSession = try await task.value
            applySession(refreshedSession)
            refreshTask = nil
            return refreshedSession
        } catch {
            refreshTask = nil

            if isUnauthorizedError(error) {
                logout(message: SafeEatL10n.text(L10nKey.Errors.sessionExpired))
            }

            throw error
        }
    }

    private func applySession(_ session: AuthSession) {
        self.session = session
        sessionStore.save(session)
    }

    private func handleLoginTask(_ operation: () async throws -> AuthSession) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let logged = try await operation()
            finishLogin(with: logged)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishLogin(with session: AuthSession) {
        applySession(session)
        #if DEBUG
        print("[AppStore] login success, session updated")
        #endif
        if session.requiresPhoneBinding == true {
            profile = nil
        } else {
            Task {
                await refreshProfile()
            }
        }
    }

    private func updateHistoryItem(_ item: LocalHistoryItem) {
        historyStore.update(item)
        reloadLocalHistory()
    }

    private func reloadLocalHistory() {
        localHistory = historyStore.loadItems().sorted { $0.createdAt > $1.createdAt }
    }

    var requiresPhoneBinding: Bool {
        session?.requiresPhoneBinding == true
    }
}
