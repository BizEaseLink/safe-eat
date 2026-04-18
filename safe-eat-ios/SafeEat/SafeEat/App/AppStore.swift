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
    @Published var session: AuthSession?
    @Published var profile: UserProfile?
    @Published var localHistory: [LocalHistoryItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRootTab: AppRootTab = .home

    let api: SafeEatAPI
    private let sessionStore: AuthSessionStore
    private let historyStore: LocalHistoryStore

    init(
        api: SafeEatAPI,
        sessionStore: AuthSessionStore,
        historyStore: LocalHistoryStore
    ) {
        self.api = api
        self.sessionStore = sessionStore
        self.historyStore = historyStore
    }

    convenience init() {
        self.init(
            api: SafeEatAPI(),
            sessionStore: AuthSessionStore(),
            historyStore: LocalHistoryStore()
        )
    }

    func bootstrap() async {
        session = sessionStore.load()
        reloadLocalHistory()

        if session != nil {
            await refreshProfile()
        }
    }

    func sendSMS(phone: String) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone)
    }

    func login(phone: String, code: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let logged = try await api.login(phone: phone, code: code)
            session = logged
            sessionStore.save(logged)
            #if DEBUG
            print("[AppStore] login success, session updated")
            #endif
            await refreshProfile()
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
        session = nil
        profile = nil
        selectedRootTab = .home
        sessionStore.clear()
        if let message {
            errorMessage = message
        }
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
            throw APIError.server(status: 0, message: "原图保存失败，请重试。")
        }
        guard let rawImageData = (rawImage ?? originalImage).jpegDataForUpload() else {
            throw APIError.server(status: 0, message: "隐藏原图保存失败，请重试。")
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
            throw APIError.server(status: 0, message: "本地记录不存在。")
        }
        guard let originalImage = LocalImageLoader.loadOriginalImage(for: item)?.rotated(clockwise: true) else {
            throw APIError.server(status: 0, message: "本地原图丢失，无法旋转。")
        }

        let rotatedPreview = LocalImageLoader.loadImage(from: item.previewImageUri)?.rotated(clockwise: true)
        guard let originalImageData = originalImage.jpegDataForUpload() else {
            throw APIError.server(status: 0, message: "旋转后的原图保存失败。")
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
        guard let token = session?.accessToken else {
            let expiredError = APIError.server(status: 401, message: "登录已过期，请重新登录。")
            logout(message: expiredError.localizedDescription)
            throw expiredError
        }

        do {
            return try await operation(token)
        } catch {
            if isUnauthorizedError(error) {
                logout(message: "登录已过期，请重新登录。")
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

    private func updateHistoryItem(_ item: LocalHistoryItem) {
        historyStore.update(item)
        reloadLocalHistory()
    }

    private func reloadLocalHistory() {
        localHistory = historyStore.loadItems().sorted { $0.createdAt > $1.createdAt }
    }
}
