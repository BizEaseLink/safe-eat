import Foundation
import Observation

/// 参数化配置 Store：启动时拉取 + 每小时定时刷新 + UserDefaults 持久化
@MainActor
@Observable
final class ConfigParamStore {
    static let shared = ConfigParamStore()

    /// 内存缓存：key → 解析后的值（String / Double / Bool）
    private(set) var cache: [String: Any] = [:]

    private let api: SafeEatAPI
    private static let cacheKey = "safeeat.configParam.cache"
    private static let cacheTimestampKey = "safeeat.configParam.cacheTimestamp"

    /// 刷新间隔：1 小时
    private let refreshInterval: TimeInterval = 60 * 60

    private var refreshTask: Task<Void, Never>?

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
        loadCachedConfig()
    }

    // MARK: - 公开读取方法

    /// 获取数值参数
    func getNumber(_ key: String, fallback: Double) -> Double {
        guard let value = cache[key] else { return fallback }
        if let num = value as? Double { return num }
        if let num = value as? Int { return Double(num) }
        if let str = value as? String, let num = Double(str) { return num }
        return fallback
    }

    /// 获取布尔参数
    func getBoolean(_ key: String, fallback: Bool) -> Bool {
        guard let value = cache[key] else { return fallback }
        if let bool = value as? Bool { return bool }
        if let str = value as? String {
            return str.lowercased() == "true" || str == "1"
        }
        return fallback
    }

    /// 获取字符串参数
    func getString(_ key: String, fallback: String) -> String {
        guard let value = cache[key] else { return fallback }
        if let str = value as? String { return str }
        return String(describing: value)
    }

    // MARK: - 拉取与刷新

    /// 拉取配置（需要 accessToken，在登录后调用）
    func fetchConfig(accessToken: String) async {
        do {
            // 并行拉取 ios 和 global scope
            async let iosParams = api.getConfigParams(accessToken: accessToken, scope: "ios")
            async let globalParams = api.getConfigParams(accessToken: accessToken, scope: "global")

            let ios = try await iosParams
            let global = try await globalParams

            var merged: [String: Any] = [:]
            // global 先写入，ios 后写入（ios 优先级更高，同名 key 覆盖 global）
            for item in global { merged[item.key] = parseValue(item) }
            for item in ios { merged[item.key] = parseValue(item) }

            cache = merged
            cacheToDisk(merged)
        } catch {
            #if DEBUG
            print("[ConfigParam] 拉取配置失败: \(error.localizedDescription)")
            #endif
        }
    }

    /// 强制刷新（忽略缓存），用于定时刷新
    func forceRefresh(accessToken: String) async {
        do {
            async let iosParams = api.getConfigParams(accessToken: accessToken, scope: "ios")
            async let globalParams = api.getConfigParams(accessToken: accessToken, scope: "global")

            let ios = try await iosParams
            let global = try await globalParams

            var merged: [String: Any] = [:]
            for item in global { merged[item.key] = parseValue(item) }
            for item in ios { merged[item.key] = parseValue(item) }

            cache = merged
            cacheToDisk(merged)
        } catch {
            #if DEBUG
            print("[ConfigParam] 刷新配置失败: \(error.localizedDescription)")
            #endif
        }
    }

    /// 启动定时刷新（主页面就绪后调用）
    func startPeriodicRefresh(accessTokenProvider: @escaping () -> String?) {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 3600))
                guard let self else { return }
                if let token = accessTokenProvider() {
                    await self.forceRefresh(accessToken: token)
                }
            }
        }
    }

    /// 停止定时刷新
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - 缓存持久化

    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey) else { return }
        // 从 UserDefaults 恢复为 [String: Any]
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // JSON 反序列化后 number 类型可能是 Int 或 Double，统一转为 Double
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

    /// 根据 paramType 解析 value 字符串为具体类型
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
