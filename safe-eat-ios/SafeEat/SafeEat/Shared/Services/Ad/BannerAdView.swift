import SwiftUI
import UMUnionSDK

struct BannerAdView: UIViewRepresentable {
    private var adConfig: AdConfigStore { AdConfigStore.shared }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        guard adConfig.bannerEnabled else { return container }

        let slotId = UMengConfig.SlotId.banner
        guard !slotId.isEmpty else { return container }

        let nativeAd = UMUnionNativeAd(slotId: slotId, type: .default)
        nativeAd.delegate = context.coordinator
        context.coordinator.nativeAd = nativeAd
        context.coordinator.container = container
        nativeAd.load()

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UMUnionNativeAdDelegate, UMUnionNativeAdViewDelegate {
        var nativeAd: UMUnionNativeAd?
        var container: UIView?
        private var model: UMUnionNativeAdDataModel?

        func nativeAdLoaded(_ nativeAdDataModel: UMUnionNativeAdDataModel?, error: Error?) {
            if let error {
                print("[UMeng] Banner 自渲染加载失败: \(error.localizedDescription)")
                return
            }
            guard let model = nativeAdDataModel else { return }
            self.model = model
            DispatchQueue.main.async { [weak self] in
                self?.renderAd()
            }
        }

        func nativeAdRenderSuccess(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?) {}
        func nativeAdRenderFail(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?, error: Error?) {}

        private func renderAd() {
            guard let model, let container else { return }
            guard let vc = AdTopVC.resolve() else { return }

            let adView = UMUnionNativeBannerAdView()
            adView.delegate = self
            adView.viewController = vc
            adView.frame = CGRect(x: 0, y: 0, width: container.bounds.width, height: 50)

            let titleLabel = UILabel()
            titleLabel.text = model.title
            titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
            titleLabel.numberOfLines = 1
            titleLabel.frame = CGRect(x: 8, y: 4, width: adView.bounds.width - 60, height: 20)
            adView.addSubview(titleLabel)

            if !model.content.isEmpty {
                let descLabel = UILabel()
                descLabel.text = model.content
                descLabel.font = .systemFont(ofSize: 12)
                descLabel.textColor = .secondaryLabel
                descLabel.numberOfLines = 1
                descLabel.frame = CGRect(x: 8, y: 26, width: adView.bounds.width - 60, height: 18)
                adView.addSubview(descLabel)
            }

            let adBadge = UILabel()
            adBadge.text = "广告"
            adBadge.font = .systemFont(ofSize: 10, weight: .medium)
            adBadge.textColor = .tertiaryLabel
            adBadge.textAlignment = .right
            adBadge.frame = CGRect(x: adView.bounds.width - 50, y: 15, width: 42, height: 20)
            adView.addSubview(adBadge)

            adView.bindDataModel(model, clickableViews: [titleLabel])

            container.addSubview(adView)
            adView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                adView.topAnchor.constraint(equalTo: container.topAnchor),
                adView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                adView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                adView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        func nativeAdViewExpose(_ nativeAdView: UMUnionNativeBannerAdView) {}
        func nativeAdViewDidClick(_ nativeAdView: UMUnionNativeBannerAdView) {}
        func nativeAdViewWithError(_ error: Error) {
            print("[UMeng] Banner 自渲染视图错误: \(error.localizedDescription)")
        }
        func nativeAdView(_ nativeAdView: UMUnionNativeBannerAdView, mediaPlayerStatus status: UMUnionMediaPlayerStatus) {}
        func nativeAdViewDetailViewWillPresent(_ nativeAdView: UMUnionNativeBannerAdView) {}
        func nativeAdViewDetailViewClosed(_ nativeAdView: UMUnionNativeBannerAdView) {}
    }
}