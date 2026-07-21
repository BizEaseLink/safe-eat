import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case server(status: Int, message: String, code: String?)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return SafeEatL10n.text(L10nKey.Errors.invalidResponse)
        case let .server(_, message, _):
            return message
        case .invalidURL:
            return SafeEatL10n.text(L10nKey.Errors.invalidURL)
        }
    }

    /// 后端返回的业务错误码（如 ACCOUNT_DELETING）
    var errorCode: String? {
        switch self {
        case let .server(_, _, code):
            return code
        default:
            return nil
        }
    }
}

/// 分页结果：items 数组 + 分页信息 + 额外字段（如 campaigns/trialAvailable）
struct PaginatedResult<T> {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
    let extra: [String: Any]

    /// 是否还有更多数据可加载
    var hasMore: Bool { items.count < total }
}

final class SafeEatAPI {
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(baseURL: URL = AppConfig.apiBaseURL) {
        self.baseURL = baseURL
        self.decoder = SafeEatAPI.makeDecoder()
    }

    func sendSMS(phone: String, scene: String? = nil, templateCode: String? = nil) async throws -> SendSmsResponse {
        var body: [String: String] = ["phone": phone]
        if let scene { body["scene"] = scene }
        if let templateCode { body["templateCode"] = templateCode }
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/sms/send",
            method: "POST",
            body: body
        )

        return try await send(request, as: SendSmsResponse.self)
    }

    func sendSMS(phone: String, captchaId: String, captchaCode: String, scene: String? = nil, templateCode: String? = nil) async throws -> SendSmsResponse {
        var body: [String: String] = [
            "phone": phone,
            "captchaId": captchaId,
            "captchaCode": captchaCode,
        ]
        if let scene { body["scene"] = scene }
        if let templateCode { body["templateCode"] = templateCode }
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/sms/send",
            method: "POST",
            body: body
        )

        return try await send(request, as: SendSmsResponse.self)
    }

    func getCaptcha() async throws -> CaptchaResponse {
        let request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/captcha",
            method: "GET"
        )
        return try await send(request, as: CaptchaResponse.self)
    }

    func login(phone: String, code: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/login",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )

        return try await send(request, as: AuthSession.self)
    }

    func loginWithPassword(phone: String, password: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/password/login",
            method: "POST",
            body: PhonePasswordBody(phone: phone, password: password)
        )

        return try await send(request, as: AuthSession.self)
    }

    func setPassword(phone: String, code: String, password: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/password/set",
            method: "POST",
            body: PhoneCodePasswordBody(phone: phone, code: code, password: password)
        )

        return try await send(request, as: AuthSession.self)
    }

    /// 已登录用户设置密码（老用户首次设密码，无需验证码）
    func setPasswordAfterLogin(accessToken: String, password: String) async throws -> AuthSession {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/password/set-after-login",
            method: "POST",
            body: PasswordOnlyBody(password: password)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        return try await send(request, as: AuthSession.self)
    }

    func appleLogin(appleSub: String, displayName: String?) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/apple/login",
            method: "POST",
            body: AppleLoginBody(appleSub: appleSub, displayName: displayName)
        )

        return try await send(request, as: AuthSession.self)
    }

    func bindApplePhone(accessToken: String, phone: String, code: String) async throws -> AuthSession {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/apple/bind-phone",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: AuthSession.self)
    }

    func refreshToken(_ refreshToken: String) async throws -> RefreshTokenResponse {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/refresh-token",
            method: "POST",
            body: ["refreshToken": refreshToken]
        )

        return try await send(request, as: RefreshTokenResponse.self)
    }

    func logout(_ refreshToken: String) async throws {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/logout",
            method: "POST",
            body: ["refreshToken": refreshToken]
        )
        try await sendVoid(request)
    }

    func getProfile(accessToken: String) async throws -> UserProfile {
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/me", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func getDailyQuota(accessToken: String) async throws -> DailyQuotaSnapshot {
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/quota/daily-snapshot", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: DailyQuotaSnapshot.self)
    }

    func getPublicDailyQuota() async throws -> DailyQuotaSnapshot {
        try await sendPublicRequest(path: "/v1/apps/\(AppConfig.appCode)/quota/daily-snapshot", method: "GET")
    }

    func updateProfile(accessToken: String, payload: UserProfileUpdatePayload) async throws -> UserProfile {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me/profile",
            method: "PATCH",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func updateHealthProfile(accessToken: String, payload: UserHealthProfileUpdatePayload) async throws -> UserProfile {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me/health-profile",
            method: "PATCH",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func updateAvatar(accessToken: String, imageData: Data, fileName: String = "avatar.jpg") async throws -> UserProfile {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/me/avatar", method: "PATCH")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [:],
            fileFieldName: "avatar",
            fileName: fileName,
            mimeType: "image/jpeg",
            fileData: imageData
        )

        return try await send(request, as: UserProfile.self)
    }

    func changePhone(accessToken: String, newPhone: String, code: String) async throws -> UserProfile {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me/phone",
            method: "PATCH",
            body: ChangePhoneBody(newPhone: newPhone, verificationCode: code)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UserProfile.self)
    }

    func resetPassword(phone: String, code: String, newPassword: String) async throws -> ResetPasswordResult {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/reset-password",
            method: "POST",
            body: ResetPasswordBody(phone: phone, verificationCode: code, newPassword: newPassword)
        )
        return try await send(request, as: ResetPasswordResult.self)
    }

    func sendChangePhoneOldSms(accessToken: String, phone: String, captchaId: String? = nil, captchaCode: String? = nil) async throws -> SendSmsResponse {
        var body: [String: String] = ["phone": phone]
        if let captchaId { body["captchaId"] = captchaId }
        if let captchaCode { body["captchaCode"] = captchaCode }
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/send-change-phone-old-sms",
            method: "POST",
            body: body
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: SendSmsResponse.self)
    }

    func verifyChangePhoneOld(accessToken: String, phone: String, code: String) async throws -> VerifyChangePhoneOldResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/verify-change-phone-old",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: VerifyChangePhoneOldResult.self)
    }

    func deleteAccount(accessToken: String, phone: String, code: String) async throws -> DeletionRequestResponse {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me",
            method: "DELETE",
            body: ["phone": phone, "code": code]
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: DeletionRequestResponse.self)
    }

    func getDeletionStatus(accessToken: String) async throws -> DeletionStatusResponse {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me/deletion-status",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: DeletionStatusResponse.self)
    }

    func cancelDeletion(accessToken: String) async throws -> CancelDeletionResponse {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/me/cancel-deletion",
            method: "POST"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: CancelDeletionResponse.self)
    }

    /// 注销恢复公开接口（无需登录态），通过短信验证码恢复账号
    func cancelDeletionPublic(phone: String, code: String) async throws -> AuthSession {
        let request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/auth/cancel-deletion",
            method: "POST",
            body: PhoneCodeBody(phone: phone, code: code)
        )
        return try await send(request, as: AuthSession.self)
    }

    func fetchDisclosure(category: String, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResult<DisclosureItem> {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/disclosures",
            method: "GET"
        )
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "category", value: category),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        request.url = components?.url
        return try await sendPaginated(request, as: DisclosureItem.self)
    }

    func getPlans() async throws -> PaginatedResult<MembershipPlan> {
        let request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/membership/plans", method: "GET")
        return try await sendPaginated(request, as: MembershipPlan.self)
    }

    func getMembershipMe(accessToken: String) async throws -> MembershipMeResult {
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/membership/me", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: MembershipMeResult.self)
    }

    func verifyTransaction(accessToken: String, payload: IAPVerifyTransactionPayload) async throws -> IAPVerifyTransactionResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/membership/apple/verify-transaction",
            method: "POST",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: IAPVerifyTransactionResult.self)
    }

    /// IAP 购买状态轮询（GET /iap/verify-status?transactionId=X）
    /// 后端先查本地 iap_receipt_log，未命中再调 Apple Server API，返回 status + membership
    func verifyIapStatus(accessToken: String, transactionId: String) async throws -> IAPVerifyStatusResult {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/iap/verify-status",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "transactionId", value: transactionId)
        ]
        request.url = components?.url
        return try await send(request, as: IAPVerifyStatusResult.self)
    }

    func redeemCode(accessToken: String, code: String) async throws -> RedeemCodeResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/membership/redeem",
            method: "POST",
            body: RedeemCodePayload(code: code)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: RedeemCodeResult.self)
    }

    func activateTrial(accessToken: String) async throws -> TrialActivationResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/membership/trial",
            method: "POST",
            body: EmptyPayload()
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: TrialActivationResult.self)
    }

    func getAvailableCampaigns(accessToken: String, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResult<AvailableCampaign> {
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/membership/campaigns", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        request.url = components?.url
        return try await sendPaginated(request, as: AvailableCampaign.self)
    }

    func createMembershipOrder(accessToken: String, payload: MembershipOrderPayload) async throws -> MembershipOrderResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/orders",
            method: "POST",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: MembershipOrderResult.self)
    }

    func markOrderFailed(accessToken: String, orderId: String) async throws {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/orders/\(orderId)/mark-failed",
            method: "POST"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        try await sendVoid(request)
    }

    func getUserOrders(accessToken: String, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResult<OrderContainer> {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/orders",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        request.url = components?.url
        return try await sendPaginated(request, as: OrderContainer.self)
    }

    func claimAdReward(accessToken: String, payload: ClaimAdRewardPayload) async throws -> ClaimAdRewardResult {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/ads/rewards/claim",
            method: "POST",
            body: payload
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: ClaimAdRewardResult.self)
    }

    func createRecognition(accessToken: String, imageData: Data, fileName: String) async throws -> RecognitionRecord {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/recognitions", method: "POST")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [:],
            fileFieldName: "image",
            fileName: fileName,
            mimeType: "image/jpeg",
            fileData: imageData
        )

        let result = try await sendPaginated(request, as: RecognitionRecord.self)
        guard let first = result.items.first else {
            throw APIError.server(status: 200, message: SafeEatL10n.text(L10nKey.Errors.invalidResponse), code: nil)
        }
        return first
    }

    // MARK: - 5候选识别流程

    func identify(accessToken: String, imageData: Data, fileName: String) async throws -> IdentifyResponse {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/recognitions/identify", method: "POST")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = MultipartFormDataBuilder.build(
            boundary: boundary,
            textFields: [:],
            fileFieldName: "image",
            fileName: fileName,
            mimeType: "image/jpeg",
            fileData: imageData
        )
        return try await send(request, as: IdentifyResponse.self)
    }

    func confirm(accessToken: String, selectedFoodId: String? = nil, selectedName: String? = nil, sessionId: String) async throws -> RecognitionRecord {
        var request = try buildJSONRequest(
            path: "/v1/apps/\(AppConfig.appCode)/recognitions/confirm",
            method: "POST",
            body: ConfirmRequestBody(selectedFoodId: selectedFoodId, selectedName: selectedName, sessionId: sessionId)
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: RecognitionRecord.self)
    }

    func searchFoods(accessToken: String, query: String) async throws -> FoodSearchResponse {
        var request = try buildRequest(path: "/v1/apps/\(AppConfig.appCode)/foods/search", method: "GET")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        request.url = components?.url
        return try await send(request, as: FoodSearchResponse.self)
    }

    func getRecognition(accessToken: String, recognitionId: String) async throws -> RecognitionRecord {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/recognitions/\(recognitionId)",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        // getRecognition 返回 data 为单个对象（不是数组），用 send 直接解码
        return try await send(request, as: RecognitionRecord.self)
    }

    func getPendingFeedbacks(accessToken: String) async throws -> [PendingFeedbackItem] {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/recognitions/feedbacks/pending",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: [PendingFeedbackItem].self)
    }

    func listMyHistory(accessToken: String, page: Int = 1, pageSize: Int = 20) async throws -> PaginatedResult<RecognitionRecord> {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/recognitions",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        request.url = components?.url
        return try await sendPaginated(request, as: RecognitionRecord.self)
    }

    func sendPublicRequest<T: Decodable>(path: String, method: String) async throws -> T {
        let request = try buildRequest(path: path, method: method)
        return try await send(request, as: T.self)
    }

    // MARK: - 消息通知

    func getNotifications(accessToken: String, page: Int, pageSize: Int, type: String?) async throws -> PaginatedResult<NotificationMessage> {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/notifications",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
        ]
        if let type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        components?.queryItems = queryItems
        request.url = components?.url
        return try await sendPaginated(request, as: NotificationMessage.self)
    }

    func getUnreadCount(accessToken: String) async throws -> UnreadCountResponse {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/notifications/unread",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return try await send(request, as: UnreadCountResponse.self)
    }

    func markNotificationRead(accessToken: String, notificationId: String) async throws {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/notifications/\(notificationId)/read",
            method: "PUT"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        try await sendVoid(request)
    }

    func markAllNotificationsRead(accessToken: String) async throws {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/notifications/read-all",
            method: "PUT"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        try await sendVoid(request)
    }

    // MARK: - 参数化配置

    /// 拉取参数化配置（支持 scope 筛选，如 "ios"/"global"）
    func getConfigParams(accessToken: String, scope: String? = nil) async throws -> [ConfigParamItem] {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/config/params",
            method: "GET"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        if let scope {
            var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "scope", value: scope)]
            request.url = components?.url
        }
        let response = try await send(request, as: ConfigParamListResponse.self)
        return response.items
    }

    func checkAppVersion(platform: String, currentVersion: String) async throws -> AppVersionCheckResponse {
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/app-version/check",
            method: "GET"
        )
        var components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "platform", value: platform),
            URLQueryItem(name: "currentVersion", value: currentVersion),
        ]
        request.url = components?.url
        return try await send(request, as: AppVersionCheckResponse.self)
    }

    @discardableResult
    func submitFeedback(
        accessToken: String,
        recognitionId: String,
        proposedName: String,
        comment: String,
        feedbackType: FeedbackType? = nil,
        evidenceImage: (data: Data, fileName: String)? = nil
    ) async throws -> [RecognitionRecord] {
        // 后端路由: POST /v1/apps/:appCode/recognitions/:recognitionId/feedback
        // matched 时返回 [RecognitionRecord]，pending 时返回 []
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = try buildRequest(
            path: "/v1/apps/\(AppConfig.appCode)/recognitions/\(recognitionId)/feedback",
            method: "POST"
        )
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var textFields: [String: String] = [
            "proposedName": proposedName,
            "comment": comment,
        ]

        if let ft = feedbackType {
            textFields["feedbackType"] = ft.rawValue
        }

        if let image = evidenceImage {
            request.httpBody = MultipartFormDataBuilder.build(
                boundary: boundary,
                textFields: textFields,
                fileFieldName: "evidenceImage",
                fileName: image.fileName,
                mimeType: "image/jpeg",
                fileData: image.data
            )
        } else {
            request.httpBody = MultipartFormDataBuilder.buildTextOnly(
                boundary: boundary,
                textFields: textFields
            )
        }

        #if DEBUG
        print("[SafeEatAPI] submitFeedback fields: \(textFields), hasImage: \(evidenceImage != nil)")
        #endif

        return try await send(request, as: [RecognitionRecord].self)
    }

    /// 无返回值请求：只检查 status==1，不解析 data
    private func sendVoid(_ request: URLRequest) async throws {
        #if DEBUG
        if let url = request.url?.absoluteString {
            print("[SafeEatAPI] \(request.httpMethod ?? "REQUEST") \(url)")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? Int
        {
            if status == 1 { return }
            let errorMessage = json["message"] as? String
                ?? SafeEatL10n.format(L10nKey.Errors.requestFailed, httpResponse.statusCode)
            let errorCode = json["code"] as? String
            throw APIError.server(
                status: httpResponse.statusCode,
                message: localizedMessage(for: errorMessage, statusCode: httpResponse.statusCode),
                code: errorCode
            )
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let serverMessage = jsonObj?["message"] as? String
            let serverCode = jsonObj?["code"] as? String
            throw APIError.server(
                status: httpResponse.statusCode,
                message: localizedMessage(for: serverMessage, statusCode: httpResponse.statusCode),
                code: serverCode
            )
        }
    }

    /// 通用请求：解析拦截器格式，解码 data 字段为指定类型 T
    /// T 是数组类型（如 [SomeType]）时返回整个数组
    /// T 是单对象类型时直接解码（适用于 data 不是数组的接口）
    private func send<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        #if DEBUG
        if let url = request.url?.absoluteString {
            print("[SafeEatAPI] \(request.httpMethod ?? "REQUEST") \(url)")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[SafeEatAPI] status=\(httpResponse.statusCode)")
        if !(200..<300).contains(httpResponse.statusCode), let responseStr = String(data: data, encoding: .utf8) {
            print("[SafeEatAPI] error response body: \(responseStr)")
        }
        #endif

        // 解析后端全局响应拦截器格式 { status, data, message, code, requestId }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? Int
        {
            if status == 1 {
                guard let responseData = json["data"] else {
                    throw APIError.server(
                        status: httpResponse.statusCode,
                        message: SafeEatL10n.text(L10nKey.Errors.invalidResponse),
                        code: nil)
                }
                let dataJSON = try JSONSerialization.data(withJSONObject: responseData)
                do {
                    return try decoder.decode(type, from: dataJSON)
                } catch {
                    #if DEBUG
                    print("[SafeEatAPI] Decode failed for type \(type): \(error)")
                    if let dataStr = String(data: dataJSON, encoding: .utf8) {
                        print("[SafeEatAPI] Data JSON (first 500 chars): \(String(dataStr.prefix(500)))")
                    }
                    #endif
                    throw APIError.server(
                        status: httpResponse.statusCode,
                        message: SafeEatL10n.format(L10nKey.Errors.decodeFailed, error.localizedDescription),
                        code: nil)
                }
            } else {
                let errorMessage = json["message"] as? String
                    ?? SafeEatL10n.format(L10nKey.Errors.requestFailed, httpResponse.statusCode)
                let errorCode = json["code"] as? String
                throw APIError.server(
                    status: httpResponse.statusCode,
                    message: localizedMessage(for: errorMessage, statusCode: httpResponse.statusCode),
                    code: errorCode
                )
            }
        }

        // 旧格式兼容：后端拦截器未启用时，直接解码整个 body
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let serverMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            let serverCode = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["code"] as? String
            throw APIError.server(
                status: httpResponse.statusCode,
                message: localizedMessage(for: serverMessage, statusCode: httpResponse.statusCode),
                code: serverCode
            )
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.server(
                status: httpResponse.statusCode,
                message: SafeEatL10n.format(L10nKey.Errors.decodeFailed, error.localizedDescription),
                        code: nil)
        }
    }

    /// 数组请求：data 是数组，取第一项返回 T
    /// 适用于识别等返回 data: [T] 但页面只需要单个结果的接口
    private func sendFirst<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let array = try await send(request, as: Array<T>.self)
        guard let first = array.first else {
            throw APIError.server(
                status: 200,
                message: SafeEatL10n.text(L10nKey.Errors.invalidResponse),
                        code: nil)
        }
        return first
    }

    /// 分页请求：返回 data 数组 + total/page/pageSize + 额外字段
    private func sendPaginated<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> PaginatedResult<T> {
        #if DEBUG
        if let url = request.url?.absoluteString {
            print("[SafeEatAPI] \(request.httpMethod ?? "REQUEST") \(url)")
        }
        #endif

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let responseData = json["data"]
        else {
            let errorMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
                ?? SafeEatL10n.format(L10nKey.Errors.requestFailed, httpResponse.statusCode)
            throw APIError.server(status: httpResponse.statusCode, message: errorMessage, code: nil)
        }

        do {
            let dataJSON = try JSONSerialization.data(withJSONObject: responseData)
            let items = try decoder.decode([T].self, from: dataJSON)
            let total = json["total"] as? Int ?? items.count
            let page = json["page"] as? Int ?? 1
            let pageSize = json["pageSize"] as? Int ?? items.count

            // 提取额外字段（排除 status/data/total/page/pageSize）
            let knownKeys: Set<String> = ["status", "data", "total", "page", "pageSize"]
            var extra: [String: Any] = [:]
            for (key, value) in json where !knownKeys.contains(key) {
                extra[key] = value
            }

            return PaginatedResult(items: items, total: total, page: page, pageSize: pageSize, extra: extra)
        } catch {
            #if DEBUG
            print("[SafeEatAPI] sendPaginated decode failed for type \(T.self): \(error)")
            if let dataStr = String(data: try JSONSerialization.data(withJSONObject: responseData), encoding: .utf8) {
                print("[SafeEatAPI] Data JSON (first 1000 chars): \(String(dataStr.prefix(1000)))")
            }
            #endif
            throw APIError.server(
                status: httpResponse.statusCode,
                message: SafeEatL10n.format(L10nKey.Errors.decodeFailed, error.localizedDescription),
                        code: nil)
        }
    }

    private func buildRequest(path: String, method: String) throws -> URLRequest {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let basePath = components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let requestPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let mergedPath = [basePath, requestPath]
            .filter { !$0.isEmpty }
            .joined(separator: "/")

        components?.path = "/" + mergedPath

        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(SafeEatL10n.isZh ? "zh" : "en", forHTTPHeaderField: "Accept-Language")
        return request
    }

    private func buildJSONRequest<T: Encodable>(path: String, method: String, body: T) throws -> URLRequest {
        var request = try buildRequest(path: path, method: method)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    /// 解码 JSON 数据为指定类型（供外部解码 extra 字段使用）
    func decodeJSON<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        try decoder.decode(type, from: data)
    }

    private func localizedMessage(for serverMessage: String?, statusCode: Int) -> String {
        switch serverMessage {
        case "Daily recognition quota has been used up.":
            return SafeEatL10n.text(L10nKey.Errors.requestQuotaExceeded)
        case "Bad Request":
            return SafeEatL10n.text(L10nKey.Errors.invalidResponse)
        default:
            return serverMessage ?? SafeEatL10n.format(L10nKey.Errors.requestFailed, statusCode)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if let date = ISO8601DateFormatter.withFractional.date(from: raw) {
                return date
            }

            if let date = ISO8601DateFormatter.basic.date(from: raw) {
                return date
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(raw)")
        }
        return decoder
    }
}

private struct PhoneBody: Encodable {
    let phone: String
}

private struct PhoneCodeBody: Encodable {
    let phone: String
    let code: String
}

private struct PhonePasswordBody: Encodable {
    let phone: String
    let password: String
}

private struct PhoneCodePasswordBody: Encodable {
    let phone: String
    let code: String
    let password: String
}

private struct PasswordOnlyBody: Encodable {
    let password: String
}

private struct AppleLoginBody: Encodable {
    let appleSub: String
    let displayName: String?
}

private struct ChangePhoneBody: Encodable {
    let newPhone: String
    let verificationCode: String
}

private struct ResetPasswordBody: Encodable {
    let phone: String
    let verificationCode: String
    let newPassword: String
}

private struct FeedbackRequestBody: Encodable {
    let recognitionId: String
    let proposedName: String
    let comment: String
}

private struct ConfirmRequestBody: Encodable {
    let selectedFoodId: String?
    let selectedName: String?
    let sessionId: String

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 只编码非 nil 字段,避免把 nil 当 null 传(后端 IsOptional 能接,但保持请求干净)
        try container.encodeIfPresent(selectedFoodId, forKey: .selectedFoodId)
        try container.encodeIfPresent(selectedName, forKey: .selectedName)
        try container.encode(sessionId, forKey: .sessionId)
    }

    private enum CodingKeys: String, CodingKey {
        case selectedFoodId, selectedName, sessionId
    }
}

private enum ISO8601DateFormatter {
    static let withFractional: Foundation.ISO8601DateFormatter = {
        let formatter = Foundation.ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let basic: Foundation.ISO8601DateFormatter = {
        let formatter = Foundation.ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private enum MultipartFormDataBuilder {
    static func buildTextOnly(
        boundary: String,
        textFields: [String: String]
    ) -> Data {
        var data = Data()
        let lineBreak = "\r\n"

        for (key, value) in textFields {
            data.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            data.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        data.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)
        return data
    }

    static func build(
        boundary: String,
        textFields: [String: String],
        fileFieldName: String,
        fileName: String,
        mimeType: String,
        fileData: Data
    ) -> Data {
        var data = Data()
        let lineBreak = "\r\n"

        for (key, value) in textFields {
            data.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)".data(using: .utf8)!)
            data.append("\(value)\(lineBreak)".data(using: .utf8)!)
        }

        data.append("--\(boundary)\(lineBreak)".data(using: .utf8)!)
        data.append(
            "Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\(lineBreak)".data(using: .utf8)!
        )
        data.append("Content-Type: \(mimeType)\(lineBreak)\(lineBreak)".data(using: .utf8)!)
        data.append(fileData)
        data.append(lineBreak.data(using: .utf8)!)
        data.append("--\(boundary)--\(lineBreak)".data(using: .utf8)!)

        return data
    }
}
