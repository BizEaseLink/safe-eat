import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class AppVersionStore {
    static let shared = AppVersionStore()

    private let api: SafeEatAPI

    // 状态
    internal(set) var updateInfo: AppVersionCheckResponse?
    private(set) var isChecking = false

    // UserDefaults 缓存
    private static let skippedVersionKey = "safeeat.skippedVersion"
    private static let skippedDateKey = "safeeat.skippedDate"
    private static let lastCheckedVersionKey = "safeeat.lastCheckedVersion"

    // 通知名：版本更新检测到时发送，object 为 AppVersionCheckResponse
    static let updateDetectedNotification = Notification.Name("AppVersionUpdateDetected")

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
    }

    /// 检查版本更新（冷启动/前台恢复时调用）
    func checkVersion() async {
        guard !isChecking else { return }
        // 弹窗正在显示时不重复检查
        guard updateInfo == nil else { return }
        isChecking = true
        defer { isChecking = false }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        // 如果用户已升级 App，清除旧的跳过记录
        let lastChecked = UserDefaults.standard.string(forKey: Self.lastCheckedVersionKey)
        if lastChecked != nil && lastChecked != currentVersion {
            UserDefaults.standard.removeObject(forKey: Self.skippedVersionKey)
        }
        UserDefaults.standard.set(currentVersion, forKey: Self.lastCheckedVersionKey)

        do {
            #if DEBUG
            print("[AppVersion] checking platform=ios currentVersion=\(currentVersion)")
            #endif

            let response = try await api.checkAppVersion(platform: "ios", currentVersion: currentVersion)

            #if DEBUG
            print("[AppVersion] response needsUpdate=\(response.needsUpdate) forceUpdate=\(response.forceUpdate) latest=\(response.latestVersion ?? "-") minimum=\(response.minimumVersion ?? "-")")
            #endif

            // TODO: 测试完成后恢复跳过逻辑（当日不再弹窗）
            // 临时：每次都弹窗，方便测试
            // if response.needsUpdate && !response.forceUpdate {
            //     if let skipped = UserDefaults.standard.string(forKey: Self.skippedVersionKey),
            //        skipped == response.latestVersion,
            //        let skippedDateStr = UserDefaults.standard.string(forKey: Self.skippedDateKey),
            //        isSameDay(skippedDateStr) {
            //         return  // 跳过当日不再弹窗
            //     }
            // }

            updateInfo = response

            // 通过 NotificationCenter 通知 ContentView 弹窗
            // @Observable 变化可能不会自动触发视图刷新，用通知确保可靠
            if response.needsUpdate {
                NotificationCenter.default.post(
                    name: Self.updateDetectedNotification,
                    object: response
                )
            }
        } catch {
            print("[AppVersion] 版本检查失败: \(error.localizedDescription)")
        }
    }

    /// 跳过当前版本更新（普通更新时调用，仅当日有效）
    func skipCurrentVersion() {
        if let version = updateInfo?.latestVersion {
            UserDefaults.standard.set(version, forKey: Self.skippedVersionKey)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.standard.set(formatter.string(from: Date()), forKey: Self.skippedDateKey)
        }
        updateInfo = nil
    }

    /// 清除更新提示（Sheet dismiss 时调用）
    func dismissUpdate() {
        updateInfo = nil
    }

    /// 打开 App Store
    func openAppStore() {
        if let url = validStoreURL(from: updateInfo?.storeUrl) {
            UIApplication.shared.open(url)
        } else {
            let url = URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)")!
            UIApplication.shared.open(url)
        }
    }

    private func validStoreURL(from value: String?) -> URL? {
        guard let value,
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https", "itms-apps"].contains(scheme)
        else {
            return nil
        }
        return url
    }

    private func isSameDay(_ dateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: Date())
    }
}
