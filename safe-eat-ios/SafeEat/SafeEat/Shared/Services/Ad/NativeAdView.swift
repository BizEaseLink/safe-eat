import SwiftUI
import UMUnionSDK

struct NativeAdView: UIViewRepresentable {
    private var adConfig: AdConfigStore { AdConfigStore.shared }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()

        guard adConfig.nativeEnabled else { return container }

        let slotId = UMengConfig.SlotId.native
        let nativeAd = UMUnionNativeAd(slotId: slotId, type: .feed)
        nativeAd.delegate = context.coordinator
        context.coordinator.nativeAd = nativeAd
        context.coordinator.container = container
        nativeAd.loadAd()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UMUnionNativeAdDelegate {
        weak var nativeAd: UMUnionNativeAd?
        weak var container: UIView?

        func nativeAdLoaded(_ nativeAdDataModel: UMUnionNativeAdDataModel?, error: Error?) {
            if let error {
                print("[UMeng] 信息流广告加载失败: \(error.localizedDescription)")
            }
        }

        func nativeAdRenderSuccess(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?) {
            guard let model, let container else { return }
            let bannerAdView = UMUnionNativeBannerAdView()
            bannerAdView.viewController = topViewController()

            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            stack.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            stack.isLayoutMarginsRelativeArrangement = true

            // 标题
            let titleLabel = UILabel()
            titleLabel.text = model.title
            titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
            titleLabel.numberOfLines = 2
            stack.addArrangedSubview(titleLabel)

            // 内容描述
            if !model.content.isEmpty {
                let descLabel = UILabel()
                descLabel.text = model.content
                descLabel.font = .systemFont(ofSize: 13)
                descLabel.textColor = .secondaryLabel
                descLabel.numberOfLines = 2
                stack.addArrangedSubview(descLabel)
            }

            // 广告标识
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

            // 绑定数据模型和可点击视图
            bannerAdView.bindDataModel(model, clickableViews: [titleLabel, stack])

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
}