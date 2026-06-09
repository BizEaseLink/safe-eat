import SwiftUI
import Lottie

/// 全屏加载动画视图 — 使用 Lottie 播放品牌 logo 动画
struct LottieLoadingView: UIViewRepresentable {
    var size: CGFloat = 160
    var text: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let animationName = colorScheme == .dark ? "logo-dark" : "logo-light"
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = .loop
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        container.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalToConstant: size),
            animationView.heightAnchor.constraint(equalToConstant: size),
            animationView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // colorScheme 变化时重建视图
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        uiView.subviews.compactMap { $0 as? LottieAnimationView }.forEach { $0.stop() }
    }
}

/// 带 Lottie 动画和文字提示的加载视图
struct LottieLoadingContent: View {
    var size: CGFloat = 160
    var text: String? = nil

    var body: some View {
        VStack(spacing: 24) {
            LottieLoadingView(size: size)
            if let text {
                Text(text)
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }
}

#Preview {
    VStack {
        LottieLoadingContent(size: 160, text: "正在分析营养数据...")
            .preferredColorScheme(.light)
        LottieLoadingContent(size: 160, text: "正在分析营养数据...")
            .preferredColorScheme(.dark)
    }
}
