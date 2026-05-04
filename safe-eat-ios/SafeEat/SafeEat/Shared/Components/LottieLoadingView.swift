import SwiftUI

/// Lottie 风格的 Loading 动画组件
/// 使用 SwiftUI 原生动画实现，无需第三方依赖
/// 后续替换为真正的 Lottie 动画时，只需修改此组件内部实现
struct LottieLoadingView: View {
    let size: CGFloat
    let text: String

    init(size: CGFloat = 120, text: String = "加载中") {
        self.size = size
        self.text = text
    }

    var body: some View {
        VStack(spacing: 16) {
            LoadingDotsAnimation(size: size)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

/// 黄色圆点跳动动画 — 模拟 Loading Dots In Yellow Lottie 效果
private struct LoadingDotsAnimation: View {
    let size: CGFloat
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: size * 0.1) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.yellow)
                    .frame(width: size * 0.2, height: size * 0.2)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .offset(y: isAnimating ? -size * 0.15 : 0)
                    .animation(
                        .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .frame(width: size, height: size)
        .onAppear { isAnimating = true }
    }
}

struct LottieLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LottieLoadingView()
    }
}
