import SwiftUI

/// 应用 Logo 组件
/// - Light 模式：笑脸白（浅色背景上的深色笑脸）
/// - Dark 模式：笑脸黑（深色背景上的浅色笑脸）
/// 使用 xcassets 的 AppLogo，自动适配 light/dark 外观
struct AppLogoView: View {
    var size: CGFloat = 120
    var animate: Bool = false

    @State private var isAnimating = false

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(animate ? (isAnimating ? 1.0 : 0.6) : 1.0)
            .opacity(animate ? (isAnimating ? 1.0 : 0.0) : 1.0)
            .animation(
                animate ? .easeOut(duration: 0.8) : .default,
                value: isAnimating
            )
            .onAppear {
                if animate {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        AppLogoView(size: 80)
        AppLogoView(size: 120, animate: true)
        AppLogoView(size: 200)
    }
    .padding()
}
