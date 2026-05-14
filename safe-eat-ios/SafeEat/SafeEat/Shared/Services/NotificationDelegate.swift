import UserNotifications
import UIKit

@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    private weak var store: AppStore?

    func configure(store: AppStore) {
        self.store = store
        UNUserNotificationCenter.current().delegate = self
    }

    // App 在前台时也显示通知
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // 点击通知时跳转
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let dateStr = userInfo["targetDate"] as? String else {
            completionHandler()
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let targetDate = formatter.date(from: dateStr) else {
            completionHandler()
            return
        }

        Task { @MainActor [weak self] in
            self?.store?.selectedRootTab = .history
            self?.store?.pendingNotificationDate = targetDate
            completionHandler()
        }
    }
}