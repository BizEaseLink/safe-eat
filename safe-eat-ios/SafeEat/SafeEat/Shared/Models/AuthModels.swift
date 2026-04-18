import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
}

struct SendSmsResponse: Codable {
    let expiresAt: Date?
    let devCode: String?
}

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
}
