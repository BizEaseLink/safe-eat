import UIKit

final class RewardAdManager: NSObject, UMUnionRewardVideoAdDelegate {

    static let shared = RewardAdManager()

    private var rewardAd: UMUnionRewardVideoAd?
    private var onReward: ((String) -> Void)?
    private var onClose: ((Bool) -> Void)?

    private override init() { super.init() }

    func loadAndShow(from vc: UIViewController, onReward: @escaping (String) -> Void, onClose: @escaping (Bool) -> Void) {
        print("[UMeng] 激励视频 load 开始, slotId=\(UMengConfig.SlotId.rewardVideo)")
        self.onReward = onReward
        self.onClose = onClose

        rewardAd = UMUnionRewardVideoAd(slotId: UMengConfig.SlotId.rewardVideo)
        rewardAd?.delegate = self
        rewardAd?.userId = storeUserId()
        // 先只加载，渲染成功后再手动展示
        rewardAd?.load()
    }

    // MARK: - UMUnionRewardVideoAdDelegate

    func uadRewardVideoDidLoad(_ rewardVideoAd: UMUnionRewardVideoAd) {
        print("[UMeng] 激励视频数据加载成功（等待渲染）")
    }

    func uadRewardVideoDidLoad(_ rewardVideoAd: UMUnionRewardVideoAd, failWithError error: Error?) {
        print("[UMeng] 激励视频数据加载失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoRenderSuccess(_ rewardVideoAd: UMUnionRewardVideoAd) {
        print("[UMeng] 激励视频渲染成功，开始展示")
        DispatchQueue.main.async {
            if let vc = self.topViewController() {
                print("[UMeng] 用 topVC 展示: \(vc)")
                rewardVideoAd.present(withRootViewController: vc)
            } else {
                print("[UMeng] 找不到 topViewController")
                self.onClose?(false)
                self.cleanup()
            }
        }
    }

    func uadRewardVideoRenderFail(_ rewardVideoAd: UMUnionRewardVideoAd, error: Error?) {
        print("[UMeng] 激励视频渲染失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoExposeSuccess(_ rewardVideoAd: UMUnionRewardVideoAd) {
        print("[UMeng] 激励视频展示成功")
    }

    func uadRewardVideoClicked(_ rewardVideoAd: UMUnionRewardVideoAd) {
        print("[UMeng] 激励视频被点击")
    }

    func uadRewardVideoAdRewardDidSucceed(_ rewardVideoAd: UMUnionRewardVideoAd, info: [AnyHashable: Any]?, verify: Bool) {
        print("[UMeng] 激励视频奖励成功 verify=\(verify) info=\(info ?? [:])")
        let proofToken = buildProofToken(from: info)
        DispatchQueue.main.async { self.onReward?(proofToken) }
    }

    func uadRewardVideoAdRewardDidFail(_ rewardVideoAd: UMUnionRewardVideoAd, error: Error?) {
        print("[UMeng] 激励视频奖励失败: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async { self.onClose?(false); self.cleanup() }
    }

    func uadRewardVideoClose(_ rewardVideoAd: UMUnionRewardVideoAd) {
        print("[UMeng] 激励视频关闭")
        DispatchQueue.main.async { self.onClose?(true); self.cleanup() }
    }

    func uadRewardVideo(_ rewardVideoAd: UMUnionRewardVideoAd, mediaPlayerStatus status: UMUnionMediaPlayerStatus) {
        print("[UMeng] 激励视频播放状态: \(status.rawValue)")
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

    private func storeUserId() -> String? {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "currentUserId")
    }

    private func buildProofToken(from info: [AnyHashable: Any]?) -> String {
        let transId = info?["transId"] as? String ?? UUID().uuidString
        let userId = storeUserId() ?? "anonymous"
        let ts = Int(Date().timeIntervalSince1970)
        return "umeng:transId=\(transId):ts=\(ts):sig=\(userId)"
    }

    private func cleanup() {
        rewardAd = nil
        onReward = nil
        onClose = nil
    }
}
