import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let requiresPhoneBinding: Bool?
    let isNewUser: Bool?
    let requiresPasswordSetup: Bool?
    let requiresRegistration: Bool?

    var isNew: Bool { isNewUser == true }
    var needsPasswordSetup: Bool { requiresPasswordSetup == true }
    var needsRegistration: Bool { requiresRegistration == true }
}

struct SendSmsResponse: Codable {
    let expiresAt: Date?
    let devCode: String?
    let needCaptcha: Bool?
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}

struct DeletionRequestResponse: Codable {
    let status: String
    let cooldownEndsAt: Date?
    let message: String?
}

struct DeletionStatusResponse: Codable {
    let status: String
    let cooldownEndsAt: Date?
    let canCancel: Bool?
}

struct CancelDeletionResponse: Codable {
    let status: String
    let message: String?
}

/// 注销恢复公开接口的响应，包含登录态
struct CancelDeletionPublicResponse: Codable {
    let accessToken: String?
    let refreshToken: String?
    let isNewUser: Bool?
    let requiresPasswordSetup: Bool?
}

struct CaptchaResponse: Codable {
    let captchaId: String
    let svgBase64: String
}

struct ResetPasswordResult: Codable {
    let success: Bool?
}

struct VerifyChangePhoneOldResult: Codable {
    let verified: Bool?
}
