import Foundation
import CoreGraphics
import Combine

enum AppConfig {
    static let appCode = "safe-eat"
    static let apiBaseURL = URL(string: "http://192.168.31.123:3000/api")!
    static let imageCompressionQuality: CGFloat = 0.9
    static let historyFileName = "safe-eat-history.json"
    static let historyImageFolder = "SafeEatHistoryImages"
    static let avatarMaxDimension: CGFloat = 1024
    static let avatarTargetMaxBytes = 300 * 1024

    static func resolveRemoteURL(path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if let url = URL(string: path), url.scheme != nil {
            return url
        }

        guard var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        components.path = path.hasPrefix("/") ? path : "/\(path)"
        components.query = nil
        components.fragment = nil
        return components.url
    }
}
