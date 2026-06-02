import Foundation

struct AppVersionCheckResponse: Decodable, Identifiable {
    var id: String { latestVersion ?? UUID().uuidString }

    let needsUpdate: Bool
    let forceUpdate: Bool
    let latestVersion: String?
    let minimumVersion: String?
    let releaseNotes: String?
    let storeUrl: String?

    init(needsUpdate: Bool, forceUpdate: Bool, latestVersion: String?,
         minimumVersion: String? = nil, releaseNotes: String? = nil, storeUrl: String? = nil) {
        self.needsUpdate = needsUpdate
        self.forceUpdate = forceUpdate
        self.latestVersion = latestVersion
        self.minimumVersion = minimumVersion
        self.releaseNotes = releaseNotes
        self.storeUrl = storeUrl
    }
}
