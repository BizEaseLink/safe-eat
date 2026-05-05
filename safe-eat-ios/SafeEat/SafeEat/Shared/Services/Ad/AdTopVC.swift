import UIKit

/// 广告场景下获取合适的 rootViewController
/// 核心问题：SwiftUI sheet/modal 场景下，遍历 presentedViewController 链会找到 sheet VC，
/// 导致全屏广告（插屏/激励视频）present 在 sheet 内部而非全屏。
enum AdTopVC {
    /// 获取适合展示广告的 ViewController
    /// - preferRoot: 为 true 时创建独立 window 展示全屏广告，不受任何 sheet/modal 影响
    /// - 默认遍历完整的 presentedViewController 链（适合 Banner/Native 等嵌入型广告）
    static func resolve(preferRoot: Bool = false) -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
        guard let root = window?.rootViewController else { return nil }

        // 全屏广告模式：创建独立 window，层级最高，不受 sheet 影响
        if preferRoot {
            return adWindowVC(windowScene: windowScene)
        }

        var vc = root
        while let presented = vc.presentedViewController {
            if presented.isBeingDismissed { break }
            vc = presented
        }

        if vc.isBeingDismissed { return root }
        return vc
    }

    /// 创建一个独立的 window + VC 专门用于全屏广告展示
    /// 广告关闭后自动清理 window
    private static func adWindowVC(windowScene: UIWindowScene?) -> UIViewController? {
        guard let windowScene else { return nil }

        let adWindow = UIWindow(windowScene: windowScene)
        adWindow.windowLevel = .normal + 1
        adWindow.makeKeyAndVisible()

        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        adWindow.rootViewController = vc

        // 保存引用，广告关闭后清理
        objc_setAssociatedObject(vc, &AssociatedKeys.adWindow, adWindow, .OBJC_ASSOCIATION_RETAIN)

        return vc
    }

    /// 全屏广告关闭后调用，清理独立 window
    static func dismissAdWindow(from vc: UIViewController?) {
        guard let vc else { return }
        let adWindow = objc_getAssociatedObject(vc, &AssociatedKeys.adWindow) as? UIWindow
        adWindow?.isHidden = true
    }

    private enum AssociatedKeys {
        nonisolated(unsafe) static var adWindow = "adWindow"
    }
}