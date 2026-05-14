import UIKit

final class FloatingIconAdManager: NSObject {
    static let shared = FloatingIconAdManager()

    private var floatingAd: UMUnionFloatingIconAd?
    private(set) var isShowing = false

    private override init() { super.init() }

    func loadAndShow(from viewController: UIViewController?) {
        guard let vc = viewController else {
            print("[UMeng] 浮窗广告找不到 rootViewController")
            return
        }

        let slotId = UMengConfig.SlotId.floatWindow
        guard !slotId.isEmpty else {
            print("[UMeng] 浮窗广告无有效 slotId，跳过")
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
}

// MARK: - UMUnionFloatingIconAdDelegate
extension FloatingIconAdManager: UMUnionFloatingIconAdDelegate {
    func uadFloatingIconDidLoad(_ floatingIconAd: UMUnionFloatingIconAd) {
        print("[UMeng] 浮窗广告加载成功")
        isShowing = true
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
    }
}