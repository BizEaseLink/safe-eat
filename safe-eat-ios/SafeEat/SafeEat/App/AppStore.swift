import Foundation
import Combine
#if canImport(UIKit)
import UIKit
#endif
import StoreKit

enum AppRootTab: Hashable {
    case home
    case history
    // case trend  // v1.3.0 启用
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
    @Published var pendingSignupBonus: Bool = false
    @Published private(set) var localCacheUsageBytes: Int64 = 0
    @Published var pendingNotificationDate: Date?
    @Published var dailyQuota: DailyQuotaSnapshot?

    // MARK: - 服务器历史记录（MOB-2）
    @Published var serverHistory: [RecognitionRecord] = []
    @Published var serverHistoryTotal: Int = 0
    @Published var serverHistoryPage: Int = 1
    @Published var isLoadingServerHistory = false
    @Published var serverHistoryLimitReached = false

    // MARK: - 会员购买新增状态
    @Published var membershipProducts: [Product] = []
    @Published var isPurchasingMembership = false
    @Published var purchaseError: String?
    @Published var isRestoringPurchases = false

    // MARK: - 会员与活动状态（C2-C5）
    @Published var membershipPlans: [MembershipPlan] = []
    @Published var campaignBenefits: [CampaignBenefit] = []
    @Published var membershipStatus: MembershipMeResult?
    @Published var trialAvailable: Bool = false
    @Published var trialEligibleFromStoreKit: Bool? = nil

    // MARK: - 首购赠送计算属性
    /// 从 campaigns 中获取 type=first_purchase 的活动
    var firstPurchaseCampaign: CampaignBenefit? {
        campaignBenefits.first(where: { $0.type == "first_purchase" })
    }

    /// 判断是否已获得首购赠送（通过后端 firstPurchaseBonusClaimed 字段判断）
    var hasFirstPurchaseBonusClaimed: Bool {
        guard let status = membershipStatus else { return false }
        return status.firstPurchaseBonusClaimed == true
    }

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
            // profile 加载后切换到该用户的历史文件
            historyStore.switchUser(userId: profile?.id)
            reloadLocalHistory()
            // 启动时检查待审核反馈是否已审批
            await checkPendingFeedbacks()
        }

        // 启动 Transaction 监听，订阅状态变更时自动刷新 profile
        startTransactionListener()
    }

    func sendSMS(phone: String) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone)
    }

    func sendSMS(phone: String, captchaId: String, captchaCode: String) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone, captchaId: captchaId, captchaCode: captchaCode)
    }

    func getCaptcha() async throws -> CaptchaResponse {
        try await api.getCaptcha()
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

    func refreshDailyQuota() async {
        do {
            if session != nil {
                dailyQuota = try await authorizedRequest { token in
                    try await api.getDailyQuota(accessToken: token)
                }
            } else {
                dailyQuota = try await api.getPublicDailyQuota()
            }
        } catch {
            // 请求被取消（如 Tab 切换）是正常行为，不处理
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            if (error as NSError).code == NSURLErrorCancelled { return }
            #if DEBUG
            print("[AppStore] refreshDailyQuota failed: \(error)")
            #endif
        }
    }

    func logout(message: String? = nil) {
        refreshTask = nil
        session = nil
        profile = nil
        selectedRootTab = .home
        sessionStore.clear()
        historyStore.switchUser(userId: nil)
        localHistory = []
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

    // MARK: - 会员与活动 API（C2-C5）

    func loadPlansWithCampaigns() async {
        do {
            let result = try await api.getPlans()
            membershipPlans = result.items
            // 从分页结果的 extra 字段提取 campaigns 和 trialAvailable
            if let campaigns = result.extra["campaigns"] as? [[String: Any]] {
                let campaignsJSON = try JSONSerialization.data(withJSONObject: campaigns)
                campaignBenefits = try api.decodeJSON(campaignsJSON, as: [CampaignBenefit].self)
            }
            trialAvailable = result.extra["trialAvailable"] as? Bool ?? false

            // 加载 StoreKit 商品后检查试用资格
            await loadMembershipProducts()
            await checkTrialEligibility()
        } catch {
            #if DEBUG
            print("[AppStore] loadPlansWithCampaigns failed: \(error)")
            #endif
        }
    }

    func loadMembershipStatus() async {
        do {
            membershipStatus = try await authorizedRequest { token in
                try await api.getMembershipMe(accessToken: token)
            }
        } catch {
            #if DEBUG
            print("[AppStore] loadMembershipStatus failed: \(error)")
            #endif
        }
    }

    // MARK: - 服务器历史记录（MOB-2）

    /// 当前套餐的历史记录限制数（nil = 无限）
    var maxHistoryRecords: Int? {
        let tier = profile?.currentPlanTier ?? "free"
        let plan = membershipPlans.first(where: { $0.tier == tier && $0.billingCycle == "monthly" })
        return plan?.maxHistoryRecords
    }

    /// 是否达到历史记录条数限制
    var isHistoryLimitReached: Bool {
        guard let limit = maxHistoryRecords, limit > 0 else { return false }
        return serverHistoryTotal >= limit
    }

    func loadServerHistory(refresh: Bool = true) async {
        guard session != nil else { return }
        isLoadingServerHistory = true
        defer { isLoadingServerHistory = false }

        let page = refresh ? 1 : serverHistoryPage + 1

        do {
            let result = try await authorizedRequest { token in
                try await api.listMyHistory(accessToken: token, page: page, pageSize: 20)
            }
            if refresh {
                serverHistory = result.items
            } else {
                serverHistory.append(contentsOf: result.items)
            }
            serverHistoryTotal = result.total
            serverHistoryPage = page
            serverHistoryLimitReached = isHistoryLimitReached
        } catch {
            #if DEBUG
            print("[AppStore] loadServerHistory failed: \(error)")
            #endif
        }
    }

    func redeemCode(_ code: String) async throws -> RedeemCodeResult {
        try await authorizedRequest { token in
            try await api.redeemCode(accessToken: token, code: code)
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
        // 原图缩小到 720 再编码，减少磁盘写入量
        let uploadSource = originalImage.scaledDown(maxDimension: 720)
        guard let originalImageData = uploadSource.jpegData(compressionQuality: 0.78) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveOriginalFailed))
        }
        // raw 图进一步缩小和质量降低，仅用于旋转等降级场景
        let rawSource = (rawImage ?? originalImage).scaledDown(maxDimension: 540)
        guard let rawImageData = rawSource.jpegData(compressionQuality: 0.72) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveHiddenOriginalFailed))
        }

        // 预览图有透明背景（背景去除），必须用 PNG 保留 alpha 通道
        let previewImageData = previewImage?.pngData()
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
            imageRotationQuarterTurns: 0,
            userId: profile?.id
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
        // 如果已有完整缓存数据则直接返回
        if let cached = item.cachedRecognition,
           cached.nutritionSnapshot != nil || cached.nutritionMetrics != nil {
            return cached
        }

        // 缓存不存在或不完整，尝试请求一次
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
        // 请求被取消（如 Tab 切换导致前一个请求 cancel）不应弹窗
        if let urlError = error as? URLError, urlError.code == .cancelled { return }
        if (error as NSError).code == NSURLErrorCancelled { return }
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

    /// 检查 StoreKit Introductory Offer 试用资格
    /// 优先使用后端 trialAvailable，StoreKit 资格检查作为补充
    func checkTrialEligibility() async {
        // 检查第一个付费套餐的 StoreKit 试用资格
        let firstPaidPlan = membershipPlans.first(where: { $0.tier != "free" && $0.appleProductId != nil })
        if let plan = firstPaidPlan, let productID = plan.appleProductId {
            trialEligibleFromStoreKit = await storeKitService.checkIntroOfferEligibility(for: productID)
        }
        // 综合判断：后端标记可用 + StoreKit 资格检查
        // nil 表示无法判断（产品未加载），此时不覆盖后端结果
        if trialAvailable && trialEligibleFromStoreKit == false {
            // 后端说可用但 StoreKit 明确说不可用（可能已用过试用），以 StoreKit 为准
            trialAvailable = false
        }
    }

    func purchaseMembership(product: Product, planId: String) async {
        isPurchasingMembership = true
        purchaseError = nil

        var orderId: String?

        do {
            // 1. 先创建后端订单
            let order = try await createMembershipOrder(planId: planId, channel: "apple_iap")
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
                try await api.verifyTransaction(
                    accessToken: token,
                    payload: IAPVerifyTransactionPayload(
                        transactionId: transactionID,
                        productId: transaction.productID
                    )
                )
            }
        } catch {
            #if DEBUG
            print("[AppStore] verifyRestoredTransaction failed: \(error)")
            #endif
        }
    }

    // C5: 购买后权益发放对接
    func verifyTransaction(transaction: Transaction) async throws -> IAPVerifyTransactionResult {
        try await authorizedRequest { token in
            try await api.verifyTransaction(
                accessToken: token,
                payload: IAPVerifyTransactionPayload(
                    transactionId: String(transaction.id),
                    productId: transaction.productID
                )
            )
        }
    }

    private func handleSuccessfulPurchase(transaction: Transaction, orderId: String) async {
        let transactionID = String(transaction.id)

        // C5: 使用新的 verify-transaction 接口发放权益
        do {
            let result = try await authorizedRequest { token in
                try await api.verifyTransaction(
                    accessToken: token,
                    payload: IAPVerifyTransactionPayload(
                        transactionId: transactionID,
                        orderId: orderId,
                        productId: transaction.productID
                    )
                )
            }

            if result.success {
                // 验证通过，刷新 profile + 会员状态
                await refreshProfile()
                await loadMembershipStatus()
            } else {
                purchaseError = SafeEatL10n.text(L10nKey.Membership.verifyFailed)
            }
        } catch {
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
        pendingSignupBonus = session.isNew
        allowsGuestHome = true
        UserDefaults.standard.set(true, forKey: Self.guestHomeKey)
        #if DEBUG
        print("[AppStore] login success, session updated")
        #endif
        if session.requiresPhoneBinding == true {
            profile = nil
            historyStore.switchUser(userId: nil)
            reloadLocalHistory()
        } else {
            Task {
                await refreshProfile()
                // profile 加载后切换到该用户的历史文件
                historyStore.switchUser(userId: profile?.id)
                reloadLocalHistory()
            }
        }
    }

    func updateLocalRecognizedName(_ newName: String, for itemID: LocalHistoryItem.ID) {
        guard var item = historyItem(id: itemID) else { return }
        item.recognizedName = newName
        updateHistoryItem(item)
    }

    /// 反馈匹配成功时，全量替换识别结果（名称、分数、指标等全部替换）
    func replaceRecognitionData(for itemID: LocalHistoryItem.ID, with updated: RecognitionRecord) {
        guard var item = historyItem(id: itemID) else { return }
        item.recognizedName = updated.recognizedName
        item.feedbackPending = false
        item.foodScore = updated.foodScore ?? item.foodScore
        item.cachedRecognition = updated
        updateHistoryItem(item)
    }

    /// 反馈待审核时，标记该记录
    func setFeedbackPending(for itemID: LocalHistoryItem.ID, pending: Bool) {
        guard var item = historyItem(id: itemID) else { return }
        item.feedbackPending = pending
        updateHistoryItem(item)
    }

    /// 检查待审核反馈：对比本地 pending 标记与后端 pending 列表
    /// 如果某个本地 pending 的 recognitionId 不在后端 pending 列表中，说明已审批
    /// 此时拉取最新 recognition 数据并更新本地
    func checkPendingFeedbacks() async {
        guard session != nil else { return }

        let pendingItems = localHistory.filter { $0.feedbackPending }
        if pendingItems.isEmpty { return }

        do {
            let serverPending = try await authorizedRequest { token in
                try await api.getPendingFeedbacks(accessToken: token)
            }
            let serverPendingIds = Set(serverPending.map { $0.recognitionId })

            for item in pendingItems {
                if !serverPendingIds.contains(item.recognitionId) {
                    // 后端已审批，拉取最新数据
                    if let updated = try? await authorizedRequest { token in
                        try await api.getRecognition(accessToken: token, recognitionId: item.recognitionId)
                    } {
                        var newItem = item
                        newItem.feedbackPending = false
                        newItem.recognizedName = updated.recognizedName
                        newItem.foodScore = updated.foodScore ?? item.foodScore
                        newItem.cachedRecognition = updated
                        updateHistoryItem(newItem)
                    } else {
                        // 拉取失败，至少清除 pending 标记
                        setFeedbackPending(for: item.id, pending: false)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("[AppStore] checkPendingFeedbacks 失败: \(error)")
            #endif
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
