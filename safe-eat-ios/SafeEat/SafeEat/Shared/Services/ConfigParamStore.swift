import Foundation
import Observation

/// 参数化配置 Store：初始化时拉取 + UserDefaults 持久化
/// 使用时不检查缓存过期，只在初始化请求时判断是否需要重新拉取
@MainActor
@Observable
final class ConfigParamStore {
    static let shared = ConfigParamStore()

    /// 内存缓存：key → 解析后的值（String / Double / Bool）
    private(set) var cache: [String: Any] = [:]

    private let api: SafeEatAPI
    private static let cacheKey = "safeeat.configParam.cache"
    private static let cacheTimestampKey = "safeeat.configParam.cacheTimestamp"

    /// 缓存有效时长：1 小时（仅初始化请求时判断）
    private let cacheTTL: TimeInterval = 60 * 60

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
        loadCachedConfig()
    }

    // MARK: - 公开读取方法

    /// 获取数值参数（不检查缓存过期，直接读内存）
    func getNumber(_ key: String, fallback: Double) -> Double {
        guard let value = cache[key] else { return fallback }
        if let num = value as? Double { return num }
        if let num = value as? Int { return Double(num) }
        if let str = value as? String, let num = Double(str) { return num }
        return fallback
    }

    /// 获取布尔参数（不检查缓存过期，直接读内存）
    func getBoolean(_ key: String, fallback: Bool) -> Bool {
        guard let value = cache[key] else { return fallback }
        if let bool = value as? Bool { return bool }
        if let str = value as? String {
            return str.lowercased() == "true" || str == "1"
        }
        return fallback
    }

    /// 获取字符串参数（不检查缓存过期，直接读内存）
    func getString(_ key: String, fallback: String) -> String {
        guard let value = cache[key] else { return fallback }
        if let str = value as? String { return str }
        return String(describing: value)
    }

    // MARK: - 初始化拉取

    /// 初始化拉取配置（缓存未过期则跳过网络请求）
    func fetchConfig(accessToken: String) async {
        if isCacheValid && !cache.isEmpty {
            return
        }
        await forceRefresh(accessToken: accessToken)
    }

    /// 强制刷新（忽略缓存），用于回前台等场景
    func forceRefresh(accessToken: String) async {
        do {
            async let mobileParams = api.getConfigParams(accessToken: accessToken, scope: "mobile")
            async let globalParams = api.getConfigParams(accessToken: accessToken, scope: "global")

            let mobile = try await mobileParams
            let global = try await globalParams

            var merged: [String: Any] = [:]
            // global 先写入，mobile 后写入（mobile 优先级更高，同名 key 覆盖 global）
            for item in global { merged[item.key] = parseValue(item) }
            for item in mobile { merged[item.key] = parseValue(item) }

            cache = merged
            cacheToDisk(merged)
        } catch {
            #if DEBUG
            print("[ConfigParam] 拉取配置失败: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - 缓存过期判断（仅初始化时使用）

    private var isCacheValid: Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: Self.cacheTimestampKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < cacheTTL
    }

    // MARK: - 缓存持久化

    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            var normalized: [String: Any] = [:]
            for (key, value) in dict {
                if let num = value as? Double {
                    normalized[key] = num
                } else if let num = value as? Int {
                    normalized[key] = Double(num)
                } else {
                    normalized[key] = value
                }
            }
            cache = normalized
        }
    }

    private func cacheToDisk(_ dict: [String: Any]) {
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
            UserDefaults.standard.set(Date(), forKey: Self.cacheTimestampKey)
        }
    }

    // MARK: - 解析

    private func parseValue(_ item: ConfigParamItem) -> Any {
        switch item.paramType {
        case "number":
            return Double(item.value) ?? 0
        case "boolean":
            return item.value.lowercased() == "true" || item.value == "1"
        default:
            return item.value
        }
    }
}
