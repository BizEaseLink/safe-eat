import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let requiresPhoneBinding: Bool?
    let isNewUser: Bool?

    var isNew: Bool { isNewUser == true }
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

struct CaptchaResponse: Codable {
    let captchaId: String
    let svgBase64: String
}
