import Foundation
import Observation

/// 广告配置 Store：初始化时拉取 + UserDefaults 持久化
/// 使用时不检查缓存过期，只在初始化请求时判断是否需要重新拉取
@MainActor
@Observable
final class AdConfigStore {
    static let shared = AdConfigStore()

    private(set) var placements: [AdPlacementConfig] = []
    private(set) var configParams: AdsConfigParams?

    private let api: SafeEatAPI
    private static let cacheKey = "safeeat.adConfig.cache"
    private static let cacheParamsKey = "safeeat.adConfig.params.cache"
    private static let cacheTimestampKey = "safeeat.adConfig.cacheTimestamp"

    private var refreshInterval: TimeInterval { AppConfig.adConfigRefreshInterval }

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
        loadCachedConfig()
    }

    var splashEnabled: Bool {
        placement(for: .splash)?.enabled == true
    }

    var rewardVideoEnabled: Bool {
        placement(for: .rewardVideo)?.enabled == true
    }

    var nativeEnabled: Bool {
        placement(for: .native)?.enabled == true
    }

    var interstitialEnabled: Bool {
        placement(for: .interstitial)?.enabled == true
    }

    var bannerEnabled: Bool {
        placement(for: .banner)?.enabled == true
    }

    var floatWindowEnabled: Bool {
        placement(for: .floatWindow)?.enabled == true
    }

    /// 浮窗广告每日弹出次数上限（默认 10）
    var floatWindowDailyLimit: Int {
        configParams?.floatWindowDailyLimit ?? 10
    }

    /// 浮窗广告关闭后再次弹出的间隔时间（秒，默认 300 = 5分钟）
    var floatWindowInterval: TimeInterval {
        TimeInterval(configParams?.floatWindowInterval ?? 300)
    }

    func slotId(for code: AdPlacementCode) -> String? {
        placement(for: code)?.slotId
    }

    func placement(for code: AdPlacementCode) -> AdPlacementConfig? {
        placements.first { $0.code == code.rawValue }
    }

    // MARK: - 初始化拉取

    /// 缓存是否在 TTL 有效期内（仅初始化时判断）
    private var isCacheValid: Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < refreshInterval
    }

    /// 初始化拉取广告配置（缓存未过期则跳过网络请求）
    func fetchConfig() async {
        if isCacheValid && !placements.isEmpty {
            return
        }
        await forceRefresh()
    }

    /// 强制刷新广告配置（忽略缓存），用于回前台等场景
    func forceRefresh() async {
        do {
            let response: AdConfigResponse = try await api.sendPublicRequest(
                path: "/v1/apps/\(AppConfig.appCode)/ads/config",
                method: "GET"
            )
            placements = response.placements
            if let params = response.configParams {
                configParams = params
            }
            cacheConfig(response.placements, params: response.configParams)
        } catch {
            print("[AdConfig] 拉取广告配置失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 缓存持久化

    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        if let cached = try? JSONDecoder().decode([AdPlacementConfig].self, from: data) {
            placements = cached
        }
        if let paramsData = UserDefaults.standard.data(forKey: Self.cacheParamsKey),
           let params = try? JSONDecoder().decode(AdsConfigParams.self, from: paramsData) {
            configParams = params
        }
    }

    private func cacheConfig(_ configs: [AdPlacementConfig], params: AdsConfigParams?) {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
        if let params, let paramsData = try? JSONEncoder().encode(params) {
            UserDefaults.standard.set(paramsData, forKey: Self.cacheParamsKey)
        }
        UserDefaults.standard.set(Date(), forKey: Self.cacheTimestampKey)
    }
}
