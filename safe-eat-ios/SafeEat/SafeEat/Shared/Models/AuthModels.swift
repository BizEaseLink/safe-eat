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
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
