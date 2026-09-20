import Foundation
import CoreGraphics
import Combine

enum AppConfig {
    static let appCode = "safe-meal"
    static let appStoreID = "6807346000"

    // API 地址:测试连 SIT(https://sit.bizeaselink.cn),线上连生产(https://bizeaselink.cn)
    static let apiBaseURL: URL = {
        #if DEBUG
        return URL(string: "https://bizeaselink.cn/api")!   // 测试: SIT
        #else
        return URL(string: "https://bizeaselink.cn/api")!        // 线上: 生产域名
        #endif
    }()
    static let imageCompressionQuality: CGFloat = 0.9
    static let historyFileName = "safe-eat-history.json"
    static let historyImageFolder = "SafeMealHistoryImages"
    static let avatarMaxDimension: CGFloat = 1024
    static let avatarTargetMaxBytes = 300 * 1024

    /// 识别上传图压缩配置：拍照/相册上传前统一压缩，避免 413。
    /// - maxDimension：长边上限（pt 像素），食物识别不需要原图分辨率
    /// - targetMaxBytes：目标体积上限，给 nginx 留余量
    /// - minQuality：质量下限，防止压到看不清影响识别
    static let uploadImageMaxDimension: CGFloat = 1600
    static let uploadImageTargetMaxBytes = 1024 * 1024
    static let uploadImageMinQuality: CGFloat = 0.5

    /// 相册上传入口 feature flag。默认关，用户明确说开才开。
    /// 当前：测试中，临时开启
    static let galleryPickerEnabled = true

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
