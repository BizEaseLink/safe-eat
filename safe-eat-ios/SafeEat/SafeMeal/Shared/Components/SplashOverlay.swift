import SwiftUI

/// 开屏页（唯一一页）：Logo（加载中停在 Lottie 第一帧）→ 加载完成同页播放动画。
/// 外观只信任 SwiftUI 环境 `colorScheme`（= 系统设置），不缓存、不强制：
/// - 系统切换白天/黑夜 → 自动跟随
/// - ATT 弹窗后不会异常变色（因为在 View 环境内读取，而非 App 结构体层）
struct SplashOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    /// 初始化是否完成（false 时显示底部 loading）
    let bootstrapped: Bool
    /// 是否开始播放 Lottie 动画
    let playingLottie: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.12, green: 0.13, blue: 0.15), Color(red: 0.09, green: 0.10, blue: 0.12)]
                    : [Color(red: 0.99, green: 0.995, blue: 0.99), Color(red: 0.965, green: 0.978, blue: 0.968)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Logo 固定居中：始终是同一个 Lottie 动画
            // 加载阶段：停在第一帧（不播放）；加载完成：同位置开始播放
            LottieLoadingView(size: 160, loop: false, autoplay: false, play: playingLottie)
                .frame(width: 160, height: 160)
                .shadow(
                    color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.18),
                    radius: 12,
                    y: 6
                )

            // 底部 loading：仅初始化未完成时显示（不占 Logo 垂直空间）
            if !bootstrapped {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(SafeMealTheme.primary)
                        .padding(.bottom, 64)
                }
            }
        }
        .transition(.opacity)
    }
}
