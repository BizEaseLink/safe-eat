import SwiftUI

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
        nativeAd.load()
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UMUnionNativeAdDelegate {
        weak var nativeAd: UMUnionNativeAd?
        weak var container: UIView?

        func nativeAdLoaded(_ nativeAdDataModel: UMUnionNativeAdDataModel?, error: Error?) {
            guard error == nil else { return }
        }

        func nativeAdRenderSuccess(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?) {
            guard let model = model, let container = container else { return }
            let adView = buildAdView(from: model)
            container.addSubview(adView)
            adView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                adView.topAnchor.constraint(equalTo: container.topAnchor),
                adView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                adView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                adView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }

        func nativeAdRenderFail(_ nativeAd: UMUnionNativeAd, model: UMUnionNativeAdDataModel?, error: Error?) {}

        private func buildAdView(from model: UMUnionNativeAdDataModel) -> UIView {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8

            if !model.title.isEmpty {
                let label = UILabel()
                label.text = model.title
                label.font = .systemFont(ofSize: 14, weight: .medium)
                label.numberOfLines = 2
                stack.addArrangedSubview(label)
            }

            if !model.content.isEmpty {
                let label = UILabel()
                label.text = model.content
                label.font = .systemFont(ofSize: 12)
                label.textColor = .secondaryLabel
                label.numberOfLines = 2
                stack.addArrangedSubview(label)
            }

            return stack
        }
    }
}
