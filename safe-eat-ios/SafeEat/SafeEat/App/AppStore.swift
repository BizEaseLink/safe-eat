import Foundation
import Combine
import UserNotifications
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
    @Published var showLocalNetworkDenied = false
    @Published var selectedRootTab: AppRootTab = .home
    @Published var pushProfileRoute: ProfileRoute?
    @Published var hasCompletedOnboarding: Bool
    @Published var allowsGuestHome: Bool
    @Published var showLoginPrompt = false
    @Published var loginPromptFeature: String?
    @Published var isNewUser: Bool = false
    /// 登录后需要设置密码（新注册用户或未设密码用户）
    @Published var requiresPasswordSetup: Bool = false
    /// 验证码登录未注册用户，需要注册（设密码后才算注册完成）
    @Published var requiresRegistration: Bool = false
    /// 登录/注册时检测到账号注销中状态
    @Published var accountDeletingDetected: Bool = false
    @Published var accountLockedDetected: Bool = false
    @Published private(set) var localCacheUsageBytes: Int64 = 0
    @Published var pendingNotificationDate: Date?
    @Published var dailyQuota: DailyQuotaSnapshot?
    @Published var notificationUnreadCount: Int = 0

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

    let notificationStore: NotificationStore
    private var cancellables = Set<AnyCancellable>()

    private var transactionListener: Task<Void, Never>?

    /// R2-2: 轮询任务句柄。新轮询前 cancel 旧轮询，避免快速重入并发多个轮询
    private var pollTask: Task<VerifyPollResult, Never>?

    private static let onboardingKey = "safe-eat.onboarding.completed"
    private static let guestHomeKey = "safe-eat.onboarding.guest-home"

    init(
        api: SafeEatAPI,
        sessionStore: AuthSessionStore,
        historyStore: LocalHistoryStore,
        storeKitService: StoreKitServiceProtocol = StoreKitService.shared,
        notificationStore: NotificationStore? = nil
    ) {
        self.api = api
        self.sessionStore = sessionStore
        self.historyStore = historyStore
        self.storeKitService = storeKitService
        self.notificationStore = notificationStore ?? NotificationStore(api: api)
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        self.allowsGuestHome = UserDefaults.standard.bool(forKey: Self.guestHomeKey)

        // 同步 NotificationStore 的未读数到 @Published 属性
        self.notificationStore.$unreadCount
            .receive(on: RunLoop.main)
            .sink { [weak self] count in
                self?.notificationUnreadCount = count
            }
            .store(in: &cancellables)

        // 监听本地网络权限被拒绝的通知（来自 NotificationStore 等子 Store）
        NotificationCenter.default.publisher(for: .localNetworkDenied)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.showLocalNetworkDenied = true
            }
            .store(in: &cancellables)
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

        // 首次启动：统一请求推送通知权限（仅 .notDetermined 时弹系统弹窗）
        await requestNotificationPermissionIfNeeded()

        if session != nil, !requiresPhoneBinding {
            await refreshProfile()
            // profile 加载后切换到该用户的历史文件
            historyStore.switchUser(userId: profile?.id)
            reloadLocalHistory()
            // 启动时检查待审核反馈是否已审批
            await checkPendingFeedbacks()
            // 启动时拉取未读消息数
            if let token = session?.accessToken {
                await notificationStore.fetchUnreadCount(accessToken: token)
            }
        }

        // 启动 Transaction 监听，订阅状态变更时自动刷新 profile
        startTransactionListener()
    }

    func sendSMS(phone: String, scene: String? = nil, templateCode: String? = nil) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone, scene: scene, templateCode: templateCode)
    }

    func sendSMS(phone: String, captchaId: String, captchaCode: String, scene: String? = nil, templateCode: String? = nil) async throws -> SendSmsResponse {
        try await api.sendSMS(phone: phone, captchaId: captchaId, captchaCode: captchaCode, scene: scene, templateCode: templateCode)
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

    /// 注销恢复：通过手机号+验证码恢复账号（公开接口，无需登录态）
    func cancelDeletionPublic(phone: String, code: String) async {
        await handleLoginTask {
            try await api.cancelDeletionPublic(phone: phone, code: code)
        }
    }

    /// 设置密码完成后：刷新 profile 并取消 requiresPasswordSetup 标记
    func completePasswordSetup() async {
        requiresPasswordSetup = false
        await refreshProfile()
        historyStore.switchUser(userId: profile?.id)
        reloadLocalHistory()
        if let token = session?.accessToken {
            await notificationStore.fetchUnreadCount(accessToken: token)
        }
    }

    /// 已登录用户设置密码（老用户首次设密码，无需验证码）
    func setPasswordAfterLogin(password: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let updatedSession = try await authorizedRequest { token in
                try await api.setPasswordAfterLogin(accessToken: token, password: password)
            }
            finishLogin(with: updatedSession)
            requiresPasswordSetup = false
        } catch {
            errorMessage = error.localizedDescription
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
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.avatarCompressionFailed), code: nil)
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
            // 带 token 拉 plans：后端据此算「当前用户」的 trialAvailable（未带 token 会被判成匿名，恒 true）
            let result: PaginatedResult<MembershipPlan>
            if let token = try? currentAccessToken() {
                result = try await api.getPlans(accessToken: token)
            } else {
                result = try await api.getPlans()
            }
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
        // 同步刷新 plans（含 trialAvailable）：保证「是否有试用资格」跟随最新后端状态，
        // 已用过试用的用户进任何页面都不会再看到体验入口
        await loadPlansWithCampaigns()
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
        rawImage: UIImage? = nil,
        alternateNames: [String]? = nil
    ) throws -> LocalHistoryItem {
        // 原图缩小到 720 再编码，减少磁盘写入量
        let uploadSource = originalImage.scaledDown(maxDimension: 720)
        guard let originalImageData = uploadSource.jpegData(compressionQuality: 0.78) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveOriginalFailed), code: nil)
        }
        // raw 图进一步缩小和质量降低，仅用于旋转等降级场景
        let rawSource = (rawImage ?? originalImage).scaledDown(maxDimension: 540)
        guard let rawImageData = rawSource.jpegData(compressionQuality: 0.72) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveHiddenOriginalFailed), code: nil)
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
            userId: profile?.id,
            alternateNames: alternateNames
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
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.localRecordMissing), code: nil)
        }
        guard let originalImage = LocalImageLoader.loadOriginalImage(for: item)?.rotated(clockwise: true) else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.localOriginalMissing), code: nil)
        }

        let rotatedPreview = LocalImageLoader.loadImage(from: item.previewImageUri)?.rotated(clockwise: true)
        guard let originalImageData = originalImage.jpegDataForUpload() else {
            throw APIError.server(status: 0, message: SafeEatL10n.text(L10nKey.Errors.saveRotatedOriginalFailed), code: nil)
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
        // 本地网络权限被拒绝（-1009），显示专用引导弹窗
        if isLocalNetworkDeniedError(error) {
            showLocalNetworkDenied = true
            return
        }
        errorMessage = error.localizedDescription
    }

    /// 检测本地网络权限被拒绝的错误
    /// URLError.Code = -1009 (.notConnectedToInternet) + iOS 16+ 本地网络禁止时也会触发
    private func isLocalNetworkDeniedError(_ error: Error) -> Bool {
        let nsError = error as NSError
        // -1009 = NSURLErrorNotConnectedToInternet
        if nsError.domain == NSURLErrorDomain && nsError.code == -1009 {
            return true
        }
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
            return true
        }
        return false
    }

    // MARK: - 会员购买（StoreKit 2）

    /// 购买流程结果（T8：替代"只看 purchaseError==nil"的间接判断）
    /// 调用方按 case 处理 UI 反馈，不再依赖 purchaseError 副作用
    enum PurchaseFlowResult {
        /// 购买成功并拿到 transactionId（可进入轮询确认）
        case purchased(transactionId: String)
        /// 用户取消付款（不弹任何成功提示）
        case userCancelled
        /// 购买待确认（Apple pending 状态，等 Transaction.updates 异步补激活）
        case pending
        /// 购买失败（purchaseError 已设）
        case failed
    }

    /// 轮询 verify-status 的结果（T9）
    enum VerifyPollResult {
        /// 会员已激活
        case activated
        /// 会员已生效但已过期（active=false）
        case expired
        /// 超时未确认
        case timeout
        /// 请求失败
        case failed(Error)
    }

    func loadMembershipProducts() async {
        do {
            membershipProducts = try await storeKitService.loadProducts()
        } catch {
            purchaseError = SafeEatL10n.text(L10nKey.Errors.invalidResponse)
        }
    }

    /// 检查 StoreKit Introductory Offer 试用资格
    /// 内部试用只信后端 trialAvailable，StoreKit 资格仅作展示参考，不覆盖后端结果
    func checkTrialEligibility() async {
        // 检查第一个付费套餐的 StoreKit 试用资格
        let firstPaidPlan = membershipPlans.first(where: { $0.tier != "free" && $0.appleProductId != nil })
        if let plan = firstPaidPlan, let productID = plan.appleProductId {
            trialEligibleFromStoreKit = await storeKitService.checkIntroOfferEligibility(for: productID)
        }
        // 内部试用不走 Apple，trialAvailable 只信后端，不再被 StoreKit 覆盖
    }

    @discardableResult
    func purchaseMembership(product: Product, planId: String) async -> PurchaseFlowResult {
        isPurchasingMembership = true
        // R2-1/R1-2 修复：defer 保证所有 return 分支（含 throw / 取消 / 失败 / pending）都复位 loading，
        // 不再依赖调用方在 View 层手动写 store.isPurchasingMembership
        defer { isPurchasingMembership = false }
        purchaseError = nil

        // Apple IAP 路径不再创建预订单：
        // - Apple transactionId 由 Apple 生成，后端无法预知
        // - 旧流程创建预订单后 verify-transaction 又建了第二条订单，导致用户看到两条订单（pending 预订单 + paid 正式订单）
        // - 现改为直接购买，verify-transaction 不传 orderId，后端 createAndPayIapOrder 自动建单
        // - POST /orders 接口保留给未来微信/支付宝路径使用

        do {
            // 1. 发起 StoreKit 购买
            // T6：appAccountToken = UUID(userId)，后端 webhook 反查 userId 用（F3 修复）
            // userId 是后端用户 UUID 字符串，直接转 UUID；非法或未登录时传 nil 退回默认行为
            let userId = profile?.id
            let appAccountToken = userId.flatMap { UUID(uuidString: $0) }
            let result = try await storeKitService.purchase(product, appAccountToken: appAccountToken)

            switch result {
            case .success(let transaction):
                // 2. 购买成功，发送收据到后端验证（不传 orderId，后端自动建单）
                await handleSuccessfulPurchase(transaction: transaction)
                // T8：返回 purchased，让调用方决定 UI 反馈（不再依赖 purchaseError==nil）
                // handleSuccessfulPurchase 验证失败会设 purchaseError，但只要 StoreKit 成功就算 purchased
                return .purchased(transactionId: String(transaction.id))

            case .userCancelled:
                // 用户取消，无需通知后端（没有预订单需要标记失败）
                // T8：不设 purchaseError，调用方按 .userCancelled 不弹成功
                return .userCancelled

            case .pending:
                purchaseError = SafeEatL10n.text(L10nKey.Membership.purchasePending)
                return .pending

            case .failed(let error):
                // 购买失败，无需通知后端（没有预订单需要标记失败）
                purchaseError = error.localizedDescription
                return .failed
            }
        } catch {
            purchaseError = error.localizedDescription
            return .failed
        }
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

    /// 激活体验会员（调用后端 POST /membership/trial）
    func activateTrialMembership() async throws -> TrialActivationResult {
        try await authorizedRequest { token in
            try await api.activateTrial(accessToken: token)
        }
    }

    /// 统一的试用激活流程：调用后端激活 → 刷新会员状态 + plans（含 trialAvailable） → 返回是否成功
    /// 成功返回 true，失败返回 false 并把错误写入 errorMessage（调用方据此决定是否关闭 sheet）
    /// 两处试用入口（NewUserWelcomeSheet / MembershipPurchaseView 的 trialPromptSheet）共用此方法
    @discardableResult
    func activateTrialAndRefresh() async -> Bool {
        do {
            _ = try await activateTrialMembership()
            await loadMembershipStatus()
            await loadPlansWithCampaigns()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func handleSuccessfulPurchase(transaction: Transaction) async {
        let transactionID = String(transaction.id)

        // C5: 使用新的 verify-transaction 接口发放权益
        // Apple IAP 路径不传 orderId，让后端 createAndPayIapOrder 自动建单
        do {
            let result = try await authorizedRequest { token in
                try await api.verifyTransaction(
                    accessToken: token,
                    payload: IAPVerifyTransactionPayload(
                        transactionId: transactionID,
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

    /// 首次启动时请求推送通知权限
    /// 仅在 .notDetermined（从未请求过）时弹系统授权弹窗
    /// .denied 时不做任何事（用户在提醒设置中开启时会触发引导）
    private func requestNotificationPermissionIfNeeded() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        )
    }

    // MARK: - IAP 购买状态轮询（T9）

    /// 轮询后端 verify-status 接口确认购买是否真正生效
    /// - Parameters:
    ///   - transactionId: Apple 交易 ID
    ///   - interval: 轮询间隔（秒），默认 5
    ///   - timeout: 总超时（秒），默认 60
    /// - Returns: VerifyPollResult（activated/expired/timeout/failed）
    /// - Note: 不起 iOS 后台 Task（不可靠，§11.3），超时后靠下拉刷新 + Transaction.updates 异步补激活
    /// - R2-2: 调用前 cancel 旧 pollTask，防快速重入并发多个轮询
    /// - R2-3: 循环内检查 Task.isCancelled，配合 R2-2 立即退出
    /// - S-1: 401/认证失败立即 .failed（不继续刷 token / 不登出用户）；连续网络错误 3 次也 .failed
    func pollVerifyStatus(
        transactionId: String,
        interval: TimeInterval = 5,
        timeout: TimeInterval = 60
    ) async -> VerifyPollResult {
        // R2-2: 取消旧轮询，避免并发
        pollTask?.cancel()
        let task = Task<VerifyPollResult, Never> { [weak self] in
            guard let self else { return .failed(APIError.server(status: 0, message: "store released", code: nil)) }
            return await self.runPollLoop(transactionId: transactionId, interval: interval, timeout: timeout)
        }
        pollTask = task
        defer { pollTask = nil }
        return await task.value
    }

    private func runPollLoop(
        transactionId: String,
        interval: TimeInterval,
        timeout: TimeInterval
    ) async -> VerifyPollResult {
        let deadline = Date().addingTimeInterval(timeout)
        var consecutiveNetworkErrors = 0
        let maxConsecutiveNetworkErrors = 3  // S-2: 连续 3 次网络错误提前 .failed，不一路吞到 60s

        while Date() < deadline {
            // R2-3: cancel 检查（配合 R2-2 的 pollTask.cancel）
            if Task.isCancelled { break }

            // S-1: 轮询不走 authorizedRequest（避免 401 时 refresh 失败 logout 把用户登出）。
            // 直接用当前 token，401/认证失败立即 .failed 由调用方提示，用户仍登录。
            let tokenResult: Result<String, Error>
            do {
                tokenResult = .success(try currentAccessToken())
            } catch {
                // 无 session：立即 .failed（不登出，currentAccessToken 已设 showLoginPrompt）
                return .failed(error)
            }

            do {
                let token = try tokenResult.get()
                let result = try await api.verifyIapStatus(accessToken: token, transactionId: transactionId)

                // 单次成功请求，重置网络错误计数
                consecutiveNetworkErrors = 0

                switch result.status {
                case "success":
                    // 后端确认成功，刷新本地状态
                    await refreshProfile()
                    await loadMembershipStatus()
                    // T10：post 通知让 ProfileView 刷新
                    NotificationCenter.default.post(name: .membershipPurchaseDidComplete, object: nil)
                    if result.membership?.active == false {
                        return .expired
                    }
                    return .activated
                case "failed":
                    return .failed(APIError.server(
                        status: 0,
                        message: SafeEatL10n.text(L10nKey.Membership.verifyFailed),
                        code: nil
                    ))
                case "pending":
                    break // 继续轮询
                default:
                    break
                }
            } catch {
                // S-1: 401/认证失败立即 .failed（不继续刷 token、不登出用户）
                if isUnauthorizedError(error) {
                    return .failed(error)
                }

                // 网络错误（URLError）累计，连续 N 次提前 .failed
                if error is URLError || (error as NSError).domain == NSURLErrorDomain {
                    consecutiveNetworkErrors += 1
                    if consecutiveNetworkErrors >= maxConsecutiveNetworkErrors {
                        return .failed(error)
                    }
                    // 否则继续重试
                } else {
                    // 其他错误（如 APIError 5xx），也算一次网络类失败，累计
                    consecutiveNetworkErrors += 1
                    if consecutiveNetworkErrors >= maxConsecutiveNetworkErrors {
                        return .failed(error)
                    }
                }
            }

            // R2-3: sleep 前再检查一次 cancel，cancel 后立即退出不等下一轮
            if Task.isCancelled { break }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            // sleep 后立即检查 cancel
            if Task.isCancelled { break }
        }

        return .timeout
    }

    private func isUnauthorizedError(_ error: Error) -> Bool {
        guard case let APIError.server(status, _, _) = error else {
            return false
        }
        return status == 401
    }

    private func currentAccessToken() throws -> String {
        guard let token = session?.accessToken else {
            showLoginPrompt = true
            throw APIError.server(status: 401, message: SafeEatL10n.text(L10nKey.Errors.sessionExpired), code: nil)
        }
        return token
    }

    private func refreshSessionIfNeeded() async throws -> AuthSession {
        if let refreshTask {
            return try await refreshTask.value
        }

        guard let currentSession = session else {
            let expiredError = APIError.server(status: 401, message: SafeEatL10n.text(L10nKey.Errors.sessionExpired), code: nil)
            logout(message: expiredError.localizedDescription)
            throw expiredError
        }

        let task = Task<AuthSession, Error> { [api] in
            let refreshed = try await api.refreshToken(currentSession.refreshToken)
            return AuthSession(
                accessToken: refreshed.accessToken,
                refreshToken: refreshed.refreshToken,
                requiresPhoneBinding: currentSession.requiresPhoneBinding,
                isNewUser: nil,
                requiresPasswordSetup: nil,
                requiresRegistration: nil
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
        } catch let error as APIError {
            if error.errorCode == "ACCOUNT_DELETING" {
                accountDeletingDetected = true
            } else if error.errorCode == "ACCOUNT_LOCKED" {
                accountLockedDetected = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func finishLogin(with session: AuthSession) {
        // 未注册手机号：验证码通过但不发 token，需要跳转设置密码页完成注册
        if session.needsRegistration {
            requiresRegistration = true
            isLoading = false
            return
        }

        applySession(session)
        isNewUser = session.isNew
        requiresPasswordSetup = session.needsPasswordSetup
        allowsGuestHome = true
        UserDefaults.standard.set(true, forKey: Self.guestHomeKey)
        #if DEBUG
        print("[AppStore] login success, session updated, requiresPasswordSetup=\(session.needsPasswordSetup)")
        #endif
        if session.requiresPhoneBinding == true {
            profile = nil
            historyStore.switchUser(userId: nil)
            reloadLocalHistory()
        } else if !session.needsPasswordSetup {
            // 不需要设置密码时才自动加载 profile
            Task {
                await refreshProfile()
                // profile 加载后切换到该用户的历史文件
                historyStore.switchUser(userId: profile?.id)
                reloadLocalHistory()
                // 登录成功后拉取未读消息数
                if let token = self.session?.accessToken {
                    await notificationStore.fetchUnreadCount(accessToken: token)
                }
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

                // 续费/家庭共享等场景，必须同步到服务端
                do {
                    _ = try await self.verifyTransaction(transaction: transaction)
                } catch {
                    print("[AppStore] Transaction listener verifyTransaction failed: \(error)")
                }

                // 刷新 profile 确保本地状态同步
                await self.refreshProfile()
                await self.loadMembershipStatus()

                // T9 §11.4 / T10：Transaction.updates 异步补激活（pending→success），
                // post 通知让前端刷新（ProfileView 监听）
                NotificationCenter.default.post(name: .membershipPurchaseDidComplete, object: nil)
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
        if requiresPasswordSetup {
            return true
        }
        return session == nil && !allowsGuestHome
    }
}
