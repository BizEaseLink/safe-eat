import UIKit

final class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitialAd: UMUnionIntersititialAd?
    private var isAdReady = false

    private override init() { super.init() }

    func preloadAd() {
        guard AdConfigStore.shared.interstitialEnabled else { return }
        let slotId = UMengConfig.SlotId.interstitial
        guard !slotId.isEmpty else {
            print("[UMeng] 插屏广告无有效 slotId，跳过")
            return
        }
        print("[UMeng] 插屏广告预加载, slotId=\(slotId)")
        interstitialAd = UMUnionIntersititialAd(slotId: slotId)
        interstitialAd?.delegate = self
        interstitialAd?.load()
    }

    func showAdIfReady() {
        guard isAdReady, let ad = interstitialAd else { return }
        guard let vc = topViewController() else {
            print("[UMeng] 插屏广告找不到 topViewController")
            return
        }
        ad.show(withRootViewController: vc)
        isAdReady = false
    }

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
}

// MARK: - UMUnionInterstitialAdDelegate
extension InterstitialAdManager: UMUnionInterstitialAdDelegate {
    func uadInterstitialDidLoad(_ intersititialAd: UMUnionIntersititialAd) {
        print("[UMeng] 插屏广告数据加载成功（等待渲染）")
    }

    func uadInterstitialDidLoad(_ intersititialAd: UMUnionIntersititialAd, failWithError error: Error?) {
        print("[UMeng] 插屏广告加载失败: \(error?.localizedDescription ?? "unknown")")
        isAdReady = false
    }

    func uadInterstitialRenderSuccess(_ intersititialAd: UMUnionIntersititialAd) {
        print("[UMeng] 插屏广告渲染成功，可展示")
        isAdReady = true
    }

    func uadInterstitialRenderFail(_ intersititialAd: UMUnionIntersititialAd, error: Error?) {
        print("[UMeng] 插屏广告渲染失败: \(error?.localizedDescription ?? "unknown")")
        isAdReady = false
    }

    func uadInterstitialExposeSuccess(_ intersititialAd: UMUnionIntersititialAd) {
        print("[UMeng] 插屏广告展示成功")
    }

    func uadInterstitialClicked(_ intersititialAd: UMUnionIntersititialAd) {
        print("[UMeng] 插屏广告被点击")
    }

    func uadInterstitialClose(_ intersititialAd: UMUnionIntersititialAd) {
        print("[UMeng] 插屏广告关闭")
        isAdReady = false
        preloadAd()
    }
}