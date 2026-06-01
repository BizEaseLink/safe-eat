import Foundation
import Observation

@MainActor
@Observable
final class AppVersionStore {
    static let shared = AppVersionStore()

    private let api: SafeEatAPI

    // 状态
    private(set) var updateInfo: AppVersionCheckResponse?
    private(set) var isChecking = false

    // UserDefaults 缓存
    private static let skippedVersionKey = "safeeat.skippedVersion"

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
    }

    /// 检查版本更新（冷启动时调用）
    func checkVersion() async {
        isChecking = true
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        do {
            let response: AppVersionCheckResponse = try await api.sendPublicRequest(
                path: "/v1/apps/\(AppConfig.appCode)/app-version/check?platform=ios&currentVersion=\(currentVersion)",
                method: "GET"
            )
            updateInfo = response

            // 如果是普通更新且用户已跳过此版本，则不弹窗
            if response.needsUpdate && !response.forceUpdate {
                if let skipped = UserDefaults.standard.string(forKey: Self.skippedVersionKey),
                   skipped == response.latestVersion {
                    updateInfo = nil  // 不弹窗
                }
            }
        } catch {
            print("[AppVersion] 版本检查失败: \(error.localizedDescription)")
        }
        isChecking = false
    }

    /// 跳过当前版本更新（普通更新时调用）
    func skipCurrentVersion() {
        if let version = updateInfo?.latestVersion {
            UserDefaults.standard.set(version, forKey: Self.skippedVersionKey)
        }
        updateInfo = nil
    }

    /// 清除更新提示（Sheet dismiss 时调用）
    func dismissUpdate() {
        updateInfo = nil
    }

    /// 打开 App Store
    func openAppStore() {
        if let urlStr = updateInfo?.storeUrl, let url = URL(string: urlStr) {
            UIApplication.shared.open(url)
        } else {
            // 默认使用 AppConfig 中的 appStoreID
            let url = URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)")!
            UIApplication.shared.open(url)
        }
    }
}
