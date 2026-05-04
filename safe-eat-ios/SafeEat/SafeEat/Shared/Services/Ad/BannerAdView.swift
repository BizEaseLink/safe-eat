import SwiftUI

struct BannerAdView: UIViewRepresentable {
    private let slotId: String

    init(slotId: String = UMengConfig.SlotId.banner) {
        self.slotId = slotId
    }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        guard let vc = topViewController() else {
            print("[UMeng] Banner 广告找不到 topViewController")
            return container
        }

        let banner = UMUnionBannerAd(slotId: slotId)
        banner.delegate = context.coordinator
        context.coordinator.bannerAd = banner
        context.coordinator.container = container
        context.coordinator.rootVC = vc
        banner.loadAdAndShow(vc)

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
        var vc = window?.rootViewController
        while vc?.presentedViewController != nil {
            vc = vc?.presentedViewController
        }
        return vc
    }

    class Coordinator: NSObject, UMUnionBannerAdDelegate {
        weak var bannerAd: UMUnionBannerAd?
        weak var container: UIView?
        weak var rootVC: UIViewController?

        func uadBannerDidLoad(_ bannerAd: UMUnionBannerAd) {
            print("[UMeng] Banner 广告加载成功")
        }

        func uadBannerDidLoad(_ bannerAd: UMUnionBannerAd, failWithError error: Error?) {
            print("[UMeng] Banner 广告加载失败: \(error?.localizedDescription ?? "unknown")")
        }

        func uadBannerExposeSuccess(_ bannerAd: UMUnionBannerAd) {
            print("[UMeng] Banner 广告展示成功")
        }

        func uadBannerClicked(_ bannerAd: UMUnionBannerAd) {
            print("[UMeng] Banner 广告被点击")
        }

        func uadBannerClose(_ bannerAd: UMUnionBannerAd) {
            print("[UMeng] Banner 广告关闭")
        }
    }
}