import UIKit

final class RewardAdManager: NSObject, UMUnionRewardVideoAdDelegate {
    static let shared = RewardAdManager()

    private var rewardAd: UMUnionRewardVideoAd?
    private var onReward: ((String) -> Void)?
    private var onClose: ((Bool) -> Void)?
    private weak var adPresentingVC: UIViewController?

    private override init() { super.init() }

    func loadAndShow(from vc: UIViewController, onReward: @escaping (String) -> Void, onClose: @escaping (Bool) -> Void) {
        self.onReward = onReward
        self.onClose = onClose

        rewardAd = UMUnionRewardVideoAd(slotId: UMengConfig.SlotId.rewardVideo)
        rewardAd?.delegate = self
        rewardAd?.userId = storeUserId()
        rewardAd?.load()
    }

    // MARK: - UMUnionRewardVideoAdDelegate

    func uadRewardVideoDidLoad(_ rewardVideoAd: UMUnionRewardVideoAd) {}

    func uadRewardVideoDidLoad(_ rewardVideoAd: UMUnionRewardVideoAd, failWithError error: Error?) {
        print("[UMeng] 激励视频加载失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoRenderSuccess(_ rewardVideoAd: UMUnionRewardVideoAd) {
        DispatchQueue.main.async {
            if let vc = AdTopVC.resolve(preferRoot: true) {
                self.adPresentingVC = vc
                rewardVideoAd.present(withRootViewController: vc)
            } else {
                self.onClose?(false)
                self.cleanup()
            }
        }
    }

    func uadRewardVideoRenderFail(_ rewardVideoAd: UMUnionRewardVideoAd, error: Error?) {
        print("[UMeng] 激励视频渲染失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoExposeSuccess(_ rewardVideoAd: UMUnionRewardVideoAd) {}

    func uadRewardVideoClicked(_ rewardVideoAd: UMUnionRewardVideoAd) {}

    func uadRewardVideoAdRewardDidSucceed(_ rewardVideoAd: UMUnionRewardVideoAd, info: [AnyHashable: Any]?, verify: Bool) {
        let proofToken = buildProofToken(from: info)
        DispatchQueue.main.async { self.onReward?(proofToken) }
    }

    func uadRewardVideoAdRewardDidFail(_ rewardVideoAd: UMUnionRewardVideoAd, error: Error?) {
        print("[UMeng] 激励视频奖励失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoClose(_ rewardVideoAd: UMUnionRewardVideoAd) {
        DispatchQueue.main.async { self.onClose?(true); self.cleanup() }
    }

    func uadRewardVideo(_ rewardVideoAd: UMUnionRewardVideoAd, mediaPlayerStatus status: UMUnionMediaPlayerStatus) {}

    private func storeUserId() -> String? {
        UserDefaults.standard.string(forKey: "currentUserId")
    }

    private func buildProofToken(from info: [AnyHashable: Any]?) -> String {
        let transId = info?["transId"] as? String ?? UUID().uuidString
        let userId = storeUserId() ?? "anonymous"
        let ts = Int(Date().timeIntervalSince1970)
        return "umeng:transId=\(transId):ts=\(ts):sig=\(userId)"
    }

    private func cleanup() {
        AdTopVC.dismissAdWindow(from: adPresentingVC)
        adPresentingVC = nil
        rewardAd?.delegate = nil
        rewardAd = nil
        onReward = nil
        onClose = nil
    }
}