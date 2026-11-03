import SwiftUI

/// 启动页径向光晕背景
/// - 深色模式：圆心 #2E7D5A 绿色光晕，向外极度柔和弥散，外圈近黑墨绿
/// - 浅色模式：圆心极淡白色柔光，外圈 #F2FAF6 浅薄荷绿
/// 全屏铺满、忽略安全区，不含任何图标或文字
struct SafeMealSplashBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    /// #2E7D5A 品牌绿
    private static let centerGreen = Color(red: 0.18, green: 0.49, blue: 0.353)
    /// #F2FAF6 浅薄荷绿
    private static let lightOuter = Color(red: 0.949, green: 0.980, blue: 0.965)
    /// 深色外圈：近黑墨绿
    private static let darkOuter = Color(red: 0.055, green: 0.078, blue: 0.067)

    var body: some View {
        GeometryReader { geo in
            // 半径覆盖屏幕最长边，保证光晕从中心一直衰减到四角
            let maxRadius = max(geo.size.width, geo.size.height) * 0.95

            ZStack {
                (colorScheme == .dark ? Self.darkOuter : Self.lightOuter)

                if colorScheme == .dark {
                    // 深色：中心绿色光晕 → 柔和弥散 → 融入外圈深色（无生硬边缘）
                    RadialGradient(
                        stops: [
                            .init(color: Self.centerGreen.opacity(0.62), location: 0.00),
                            .init(color: Self.centerGreen.opacity(0.38), location: 0.22),
                            .init(color: Self.centerGreen.opacity(0.16), location: 0.50),
                            .init(color: Self.centerGreen.opacity(0.05), location: 0.78),
                            .init(color: .clear, location: 1.00),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxRadius
                    )
                } else {
                    // 浅色：中心极淡白色柔光 → 过渡到 #F2FAF6 外圈
                    RadialGradient(
                        stops: [
                            .init(color: .white, location: 0.00),
                            .init(color: .white.opacity(0.88), location: 0.25),
                            .init(color: Self.lightOuter.opacity(0.92), location: 0.60),
                            .init(color: Self.lightOuter, location: 1.00),
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxRadius
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("浅色模式") {
    SafeMealSplashBackground()
        .preferredColorScheme(.light)
}

#Preview("深色模式") {
    SafeMealSplashBackground()
        .preferredColorScheme(.dark)
}
