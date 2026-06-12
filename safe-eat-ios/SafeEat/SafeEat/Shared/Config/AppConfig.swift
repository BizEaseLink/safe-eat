import Foundation
import CoreGraphics
import Combine

enum AppConfig {
    static let appCode = "safe-eat"
    static let appStoreID = "6741974970"
    static let apiBaseURL = URL(string: "http://192.168.31.160:3000/api")!
    static let imageCompressionQuality: CGFloat = 0.9
    static let historyFileName = "safe-eat-history.json"
    static let historyImageFolder = "SafeEatHistoryImages"
    static let avatarMaxDimension: CGFloat = 1024
    static let avatarTargetMaxBytes = 300 * 1024

    /// 广告配置刷新间隔（秒），缓存过期后重新请求网络，同时作为定时刷新周期
    /// 测试阶段设 1 小时，上线后可改为 24 小时或更长
    static let adConfigRefreshInterval: TimeInterval = 1 * 60 * 60

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
