import Foundation

struct AppVersionCheckResponse: Decodable {
    let needsUpdate: Bool
    let forceUpdate: Bool
    let latestVersion: String?
    let minimumVersion: String?
    let releaseNotes: String?
    let storeUrl: String?
}
