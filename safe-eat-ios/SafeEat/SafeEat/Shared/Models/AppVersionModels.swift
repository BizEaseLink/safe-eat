import Foundation

struct AppVersionCheckResponse: Decodable, Identifiable {
    var id: String { latestVersion ?? UUID().uuidString }

    let needsUpdate: Bool
    let forceUpdate: Bool
    let latestVersion: String?
    let minimumVersion: String?
    let releaseNotes: String?
    let storeUrl: String?
}
