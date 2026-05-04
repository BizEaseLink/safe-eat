import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import StoreKit

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
    @Published var allowsGuestHome: Bool
    @Published var showLoginPrompt = false
    @Published var loginPromptFeature: String?
    @Published var isNewUser: Bool = false
    @Published private(set) var localCacheUsageBytes: Int64 = 0

    // MARK: - 会员购买新增状态
    @Published var membershipProducts: [Product] = []
    @Published var isPurchasingMembership = false
    @Published var purchaseError: String?
    @Published var isRestoringPurchases = false

    let api: SafeEatAPI
    private let sessionStore: AuthSessionStore
    private let historyStore: LocalHistoryStore
    private let storeKitService: StoreKitServiceProtocol
    private var refreshTask: Task<AuthSession, Error>?

    private var transactionListener: Task<Void, Never>?

    private static let onboardingKey = "safe-eat.onboarding.completed"
    private static let guestHomeKey = "safe-eat.onboarding.guest-home"

    init(
        api: SafeEatAPI,
        sessionStore: AuthSessionStore,
        historyStore: LocalHistoryStore,
        storeKitService: StoreKitServiceProtocol = StoreKitService.shared
    ) {
        self.api = api
        self.sessionStore = sessionStore
        self.historyStore = historyStore
        self.storeKitService = storeKitService
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.allowsGuestHome = UserDefaults.standard.bool(forKey: Self.guestHomeKey)
    }

    convenience init() {
        self.init(
            api: SafeEatAPI(),
            sessionStore: AuthSessionStore(),
            historyStore: LocalHistoryStore(),
            storeKitService: StoreKitService.shared
        )
    }

    func completeOnboarding(allowsGuestHome: Bool = false) {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        self.allowsGuestHome = allowsGuestHome
        UserDefaults.standard.set(allowsGuestHome, forKey: Self.guestHomeKey)
        selectedRootTab = .home
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
        allowsGuestHome = false
        UserDefaults.standard.set(false, forKey: Self.guestHomeKey)
    }

    func requireLogin(featureHint: String? = nil) {
        guard session == nil else { return }
        loginPromptFeature = featureHint
        showLoginPrompt = true
    }

    func goToLogin() {
        allowsGuestHome = false
        UserDefaults.standard.set(false, forKey: Self.guestHomeKey)
        showLoginPrompt = false
        loginPromptFeature = nil
        selectedRootTab = .home
    }

    func dismissLoginPrompt() {
        showLoginPrompt = false
        loginPromptFeature = nil
    }

    func bootstrap() async {
        defer { hasBootstrapped = true }
        session = sessionStore.load()
        reloadLocalHistory()

        if session != nil, !requiresPhoneBinding {
            await refreshProfile()
        }

        // 启动 Transaction 监听，订阅状态变更时自动刷新 profile
        startTransactionListener()
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
        isNewUser = false
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

    func createMembershipOrder(planId: String, channel: String, discountId: String? = nil) async throws -> MembershipOrderResult {
        try await authorizedRequest { token in
            try await api.createMembershipOrder(
                accessToken: token,
                payload: MembershipOrderPayload(planId: planId, channel: channel, discountId: discountId)
            )
        }
    }

    func clearLocalCache() {
        historyStore.clearAll()
        LocalImageLoader.clearAllCaches()
        reloadLocalHistory()
    }

    var localCacheSizeText: String {
        ByteCountFormatter.string(fromByteCount: localCacheUsageBytes, countStyle: .file)
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

    // MARK: - 会员购买（StoreKit 2）

    func loadMembershipProducts() async {
        do {
            membershipProducts = try await storeKitService.loadProducts()
        } catch {
            purchaseError = SafeEatL10n.text(L10nKey.Errors.invalidResponse)
        }
    }

    func purchaseMembership(product: Product, planId: String, discountId: String? = nil) async {
        isPurchasingMembership = true
        purchaseError = nil

        var orderId: String?

        do {
            // 1. 先创建后端订单
            let order = try await createMembershipOrder(planId: planId, channel: "apple_iap", discountId: discountId)
            orderId = order.id

            // 2. 发起 StoreKit 购买
            let result = try await storeKitService.purchase(product)

            switch result {
            case .success(let transaction):
                // 3. 购买成功，发送收据到后端验证
                await handleSuccessfulPurchase(transaction: transaction, orderId: order.id)

            case .userCancelled:
                // 用户取消，通知后端标记订单失败（静默失败）
                await markOrderFailedSilently(orderId: order.id)

            case .pending:
                purchaseError = SafeEatL10n.text(L10nKey.Membership.purchasePending)

            case .failed(let error):
                // 购买失败，通知后端标记订单失败（静默失败）
                purchaseError = error.localizedDescription
                await markOrderFailedSilently(orderId: order.id)
            }
        } catch {
            purchaseError = error.localizedDescription
            // 创建订单后的异常也需要标记失败
            if let orderId {
                await markOrderFailedSilently(orderId: orderId)
            }
        }

        isPurchasingMembership = false
    }

    func restorePurchases() async {
        isRestoringPurchases = true
        purchaseError = nil

        do {
            let transactions = try await storeKitService.restorePurchases()
            if transactions.isEmpty {
                purchaseError = SafeEatL10n.text(L10nKey.Membership.restoreEmpty)
            } else {
                // 对每个恢复的 transaction 发送到后端验证收据
                for transaction in transactions {
                    await verifyRestoredTransaction(transaction)
                }
                // 恢复购买：刷新 profile 获取最新会员状态
                await refreshProfile()
            }
        } catch {
            purchaseError = error.localizedDescription
        }

        isRestoringPurchases = false
    }

    private func verifyRestoredTransaction(_ transaction: Transaction) async {
        let transactionID = String(transaction.id)
        do {
            _ = try await authorizedRequest { token in
                try await api.verifyIAPReceipt(
                    accessToken: token,
                    payload: IAPVerifyReceiptPayload(
                        transactionId: transactionID,
                        productId: transaction.productID
                    )
                )
            }
        } catch {
            // 静默失败，后端可能已通过 Apple Server Notifications 处理
            #if DEBUG
            print("[AppStore] verifyRestoredTransaction failed: \(error)")
            #endif
        }
    }

    private func handleSuccessfulPurchase(transaction: Transaction, orderId: String) async {
        let transactionID = String(transaction.id)

        // 发送收据到后端验证
        do {
            let result = try await authorizedRequest { token in
                try await api.verifyIAPReceipt(
                    accessToken: token,
                    payload: IAPVerifyReceiptPayload(
                        transactionId: transactionID,
                        orderId: orderId,
                        productId: transaction.productID
                    )
                )
            }

            if result.success {
                // 验证通过，刷新 profile 获取最新会员状态
                await refreshProfile()
            } else {
                purchaseError = SafeEatL10n.text(L10nKey.Membership.verifyFailed)
            }
        } catch {
            // 收据验证失败，仍然刷新 profile（后端可能已通过 Apple 通知处理）
            purchaseError = SafeEatL10n.text(L10nKey.Membership.verifyError)
            await refreshProfile()
        }
    }

    // MARK: - 私有方法

    private func markOrderFailedSilently(orderId: String) async {
        do {
            try await authorizedRequest { token in
                try await api.markOrderFailed(accessToken: token, orderId: orderId)
            }
        } catch {
            // 静默失败，不阻塞用户操作
            #if DEBUG
            print("[AppStore] markOrderFailed failed: \(error)")
            #endif
        }
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
                requiresPhoneBinding: currentSession.requiresPhoneBinding,
                isNewUser: nil
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
        isNewUser = session.isNew
        allowsGuestHome = true
        UserDefaults.standard.set(true, forKey: Self.guestHomeKey)
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
        let items = historyStore.loadItems().sorted { $0.createdAt > $1.createdAt }
        let usageBytes = historyStore.storageUsageBytes()
        localHistory = items
        localCacheUsageBytes = usageBytes
    }

    // MARK: - Transaction 监听

    private func startTransactionListener() {
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.checkVerifiedTransaction(result) else { continue }
                await transaction.finish()

                // 订阅状态变更（续费/退款/取消等），刷新 profile
                await self.refreshProfile()
            }
        }
    }

    private func checkVerifiedTransaction<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    var requiresPhoneBinding: Bool {
        session?.requiresPhoneBinding == true
    }

    var shouldShowLoginAfterOnboarding: Bool {
        if requiresPhoneBinding {
            return true
        }
        return session == nil && !allowsGuestHome
    }
}
