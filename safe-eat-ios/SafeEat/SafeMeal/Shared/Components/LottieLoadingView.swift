import SwiftUI
import Lottie

/// 全屏加载动画视图 — 使用 Lottie 播放品牌 logo 动画
struct LottieLoadingView: UIViewRepresentable {
    var size: CGFloat = 160
    var text: String? = nil
    /// 是否循环播放（启动页用 false：播放一次后进入首页）
    var loop: Bool = true
    /// 是否自动播放（false = 停在第一帧，等 play 变 true 再播；用于加载页与动画无缝衔接）
    var autoplay: Bool = true
    /// 播放控制：autoplay=false 时，变为 true 开始播放
    var play: Bool = false
    /// 外部指定是否深色（统一与背景的判定源）；nil 则用 SwiftUI colorScheme
    var useDark: Bool? = nil

    @Environment(\.colorScheme) private var colorScheme

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = .clear

        let isDark = useDark ?? (colorScheme == .dark)
        let animationName = isDark ? "logo-dark" : "logo-light"
        let animationView = LottieAnimationView(name: animationName)
        animationView.loopMode = loop ? .loop : .playOnce
        // autoplay=false：只显示第一帧，等 play 触发
        animationView.currentProgress = 0
        if autoplay {
            animationView.play()
        }
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
        // 播放控制：外部把 play 置 true 时开始播放（加载完成 → 动图）
        guard play,
              let animationView = uiView.subviews.compactMap({ $0 as? LottieAnimationView }).first,
              !animationView.isAnimationPlaying else { return }
        animationView.play()
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
                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeMealTheme.textSecondary)
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
