import Foundation
import Observation

@MainActor
@Observable
final class AdConfigStore {
    static let shared = AdConfigStore()

    private(set) var placements: [AdPlacementConfig] = []

    private let api: SafeEatAPI
    private static let cacheKey = "safeeat.adConfig.cache"
    private static let cacheTimestampKey = "safeeat.adConfig.cacheTimestamp"
    private static let cacheTTL: TimeInterval = 24 * 60 * 60 // 24 小时

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

    func slotId(for code: AdPlacementCode) -> String? {
        placement(for: code)?.slotId
    }

    func placement(for code: AdPlacementCode) -> AdPlacementConfig? {
        placements.first { $0.code == code.rawValue }
    }

    /// 缓存是否在 TTL 有效期内
    private var isCacheValid: Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < Self.cacheTTL
    }

    /// 拉取广告配置，24h 内不重复请求
    func fetchConfig() async {
        if isCacheValid && !placements.isEmpty {
            return
        }
        do {
            let response: AdConfigResponse = try await api.sendPublicRequest(
                path: "/v1/\(AppConfig.appCode)/ads/config",
                method: "GET"
            )
            placements = response.placements
            cacheConfig(response.placements)
        } catch {
            print("[AdConfig] 拉取广告配置失败: \(error.localizedDescription)")
        }
    }

    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        if let cached = try? JSONDecoder().decode([AdPlacementConfig].self, from: data) {
            placements = cached
        }
    }

    private func cacheConfig(_ configs: [AdPlacementConfig]) {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
            UserDefaults.standard.set(Date(), forKey: Self.cacheTimestampKey)
        }
    }
}
