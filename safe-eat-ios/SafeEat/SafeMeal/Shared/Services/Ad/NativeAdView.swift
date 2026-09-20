import SwiftUI
import UMUnionSDK

struct NativeAdView: UIViewRepresentable {
    private var adConfig: AdConfigStore { AdConfigStore.shared }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        guard adConfig.nativeEnabled else { return container }

        let slotId = UMengConfig.SlotId.native
        guard !slotId.isEmpty else { return container }

        let nativeAd = UMUnionNativeAd(slotId: slotId, type: .feed)
        nativeAd.delegate = context.coordinator
        context.coordinator.nativeAd = nativeAd
        context.coordinator.container = container
        nativeAd.load()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UMUnionNativeAdDelegate {
        var nativeAd: UMUnionNativeAd?
        var container: UIView?

        func nativeAdLoaded(_ nativeAdDataModel: UMUnionNativeAdDataModel?, error: Error?) {
            if let error {
                print("[UMeng] 信息流广告加载失败: \(error.localizedDescription)")
            }
        }

        func nativeAdRenderSuccess(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?) {
            guard let model else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, let container = self.container else { return }
                self.renderAd(model: model, into: container)
            }
        }

        private func renderAd(model: UMUnionNativeAdDataModel, into container: UIView) {
            let bannerAdView = UMUnionNativeBannerAdView()
            bannerAdView.viewController = AdTopVC.resolve()

            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            stack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            stack.isLayoutMarginsRelativeArrangement = true

            let titleLabel = UILabel()
            titleLabel.text = model.title
            titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            titleLabel.numberOfLines = 2
            stack.addArrangedSubview(titleLabel)

            if !model.content.isEmpty {
                let descLabel = UILabel()
                descLabel.text = model.content
                descLabel.font = .systemFont(ofSize: 13)
                descLabel.textColor = .secondaryLabel
                descLabel.numberOfLines = 2
                stack.addArrangedSubview(descLabel)
            }

            let adBadge = UILabel()
            adBadge.text = "广告"
            adBadge.font = .systemFont(ofSize: 10, weight: .medium)
            adBadge.textColor = .tertiaryLabel
            adBadge.textAlignment = .right
            stack.addArrangedSubview(adBadge)

            bannerAdView.addSubview(stack)
            stack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: bannerAdView.topAnchor),
                stack.bottomAnchor.constraint(equalTo: bannerAdView.bottomAnchor),
                stack.leadingAnchor.constraint(equalTo: bannerAdView.leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: bannerAdView.trailingAnchor),
            ])

            bannerAdView.bindDataModel(model, clickableViews: [titleLabel])

            container.addSubview(bannerAdView)
            bannerAdView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerAdView.topAnchor.constraint(equalTo: container.topAnchor),
                bannerAdView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                bannerAdView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bannerAdView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        func nativeAdRenderFail(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?, error: Error?) {
            print("[UMeng] 信息流广告渲染失败: \(error?.localizedDescription ?? "unknown")")
        }
    }
}