import UIKit

final class FloatingIconAdManager: NSObject {
    static let shared = FloatingIconAdManager()

    private var floatingAd: UMUnionFloatingIconAd?
    private(set) var isShowing = false

    // MARK: - 每日弹出次数限制
    private static let dailyCountKey = "safeeat.floatAd.dailyCount"
    private static let dailyCountDateKey = "safeeat.floatAd.dailyCountDate"

    // MARK: - 间隔时间
    private static let lastCloseTimeKey = "safeeat.floatAd.lastCloseTime"

    private override init() { super.init() }

    func loadAndShow(from viewController: UIViewController?) {
        // 已经在显示中，不重复加载
        guard !isShowing else { return }

        guard let vc = viewController else {
            print("[UMeng] 浮窗广告找不到 rootViewController")
            return
        }

        let slotId = UMengConfig.SlotId.floatWindow
        guard !slotId.isEmpty else {
            print("[UMeng] 浮窗广告无有效 slotId，跳过")
            return
        }

        // 检查每日弹出次数
        let dailyLimit = AdConfigStore.shared.floatWindowDailyLimit
        let todayCount = todayShowCount()
        if todayCount >= dailyLimit {
            print("[UMeng] 浮窗广告今日已弹出 \(todayCount) 次，达上限 \(dailyLimit)")
            return
        }

        // 检查间隔时间
        let interval = AdConfigStore.shared.floatWindowInterval
        if let lastClose = lastCloseTime(), Date().timeIntervalSince(lastClose) < interval {
            let remaining = Int(interval - Date().timeIntervalSince(lastClose))
            print("[UMeng] 浮窗广告间隔未满，还需 \(remaining) 秒")
            return
        }

        print("[UMeng] 浮窗广告加载, slotId=\(slotId)")
        floatingAd = UMUnionFloatingIconAd(slotId: slotId)
        floatingAd?.delegate = self
        floatingAd?.canMove = true
        floatingAd?.loadAndShow(vc)
    }

    func dismiss() {
        isShowing = false
        floatingAd = nil
    }

    // MARK: - 每日计数

    /// 今日已弹出次数
    private func todayShowCount() -> Int {
        let today = Self.formattedDate()
        let savedDate = UserDefaults.standard.string(forKey: Self.dailyCountDateKey)
        guard savedDate == today else { return 0 }
        return UserDefaults.standard.integer(forKey: Self.dailyCountKey)
    }

    /// 弹出次数 +1
    private func incrementDailyCount() {
        let today = Self.formattedDate()
        let savedDate = UserDefaults.standard.string(forKey: Self.dailyCountDateKey)
        var count = 0
        if savedDate == today {
            count = UserDefaults.standard.integer(forKey: Self.dailyCountKey)
        }
        count += 1
        UserDefaults.standard.set(count, forKey: Self.dailyCountKey)
        UserDefaults.standard.set(today, forKey: Self.dailyCountDateKey)
    }

    /// 上次关闭时间
    private func lastCloseTime() -> Date? {
        UserDefaults.standard.object(forKey: Self.lastCloseTimeKey) as? Date
    }

    /// 记录关闭时间
    private func recordCloseTime() {
        UserDefaults.standard.set(Date(), forKey: Self.lastCloseTimeKey)
    }

    private static func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - UMUnionFloatingIconAdDelegate
extension FloatingIconAdManager: UMUnionFloatingIconAdDelegate {
    func uadFloatingIconDidLoad(_ floatingIconAd: UMUnionFloatingIconAd) {
        print("[UMeng] 浮窗广告加载成功")
        isShowing = true
        incrementDailyCount()
    }

    func uadFloatingIconDidLoadFail(_ floatingIconAd: UMUnionFloatingIconAd, failWithError error: Error?) {
        print("[UMeng] 浮窗广告加载失败: \(error?.localizedDescription ?? "unknown")")
        isShowing = false
    }

    func uadFloatingIconExposeSuccess(_ floatingIconAd: UMUnionFloatingIconAd) {
        print("[UMeng] 浮窗广告展示成功")
    }

    func uadFloatingIconClicked(_ floatingIconAd: UMUnionFloatingIconAd) {
        print("[UMeng] 浮窗广告被点击")
    }

    func uadFloatingIconClose(_ floatingIconAd: UMUnionFloatingIconAd) {
        print("[UMeng] 浮窗广告关闭")
        isShowing = false
        recordCloseTime()
    }
}
