import UIKit

final class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitialAd: UMUnionIntersititialAd?
    private var isAdReady = false
    private weak var adPresentingVC: UIViewController?

    private override init() { super.init() }

    func preloadAd() {
        guard AdConfigStore.shared.interstitialEnabled else { return }
        let slotId = UMengConfig.SlotId.interstitial
        guard !slotId.isEmpty else { return }
        interstitialAd = UMUnionIntersititialAd(slotId: slotId)
        interstitialAd?.delegate = self
        interstitialAd?.load()
    }

    func showAdIfReady() {
        guard isAdReady, let ad = interstitialAd else { return }
        guard let vc = AdTopVC.resolve(preferRoot: true) else {
            print("[UMeng] 插屏广告找不到 rootViewController")
            return
        }
        adPresentingVC = vc
        ad.present(withRootViewController: vc)
        isAdReady = false
    }
}

// MARK: - UMUnionInterstitialAdDelegate
extension InterstitialAdManager: UMUnionInterstitialAdDelegate {
    func uadInterstitialDidLoad(_ intersititialAd: UMUnionIntersititialAd) {}

    func uadInterstitialDidLoad(_ intersititialAd: UMUnionIntersititialAd, failWithError error: Error?) {
        print("[UMeng] 插屏广告加载失败: \(error?.localizedDescription ?? "unknown")")
        isAdReady = false
    }

    func uadInterstitialRenderSuccess(_ intersititialAd: UMUnionIntersititialAd) {
        isAdReady = true
    }

    func uadInterstitialRenderFail(_ intersititialAd: UMUnionIntersititialAd, error: Error?) {
        print("[UMeng] 插屏广告渲染失败: \(error?.localizedDescription ?? "unknown")")
        isAdReady = false
    }

    func uadInterstitialExposeSuccess(_ intersititialAd: UMUnionIntersititialAd) {}

    func uadInterstitialClicked(_ intersititialAd: UMUnionIntersititialAd) {}

    func uadInterstitialClose(_ intersititialAd: UMUnionIntersititialAd) {
        isAdReady = false
        AdTopVC.dismissAdWindow(from: adPresentingVC)
        adPresentingVC = nil
        preloadAd()
    }
}