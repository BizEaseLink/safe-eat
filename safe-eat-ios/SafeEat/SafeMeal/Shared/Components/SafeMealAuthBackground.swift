import SwiftUI

/// 登录页同款背景（App 主背景 + 柔和几何装饰块）
/// 抽成共享组件：登录 / 启动页 / 其他全屏页都可复用
struct SafeMealAuthBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            SafeMealMainGradientBackground()

            Circle()
                .fill(Color(red: 0.89, green: 0.95, blue: 0.90).opacity(colorScheme == .dark ? 0.10 : 0.82))
                .frame(width: 260, height: 260)
                .blur(radius: 4)
                .offset(x: -120, y: -260)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color(red: 0.96, green: 0.90, blue: 0.80).opacity(colorScheme == .dark ? 0.10 : 0.62))
                .frame(width: 220, height: 140)
                .rotationEffect(.degrees(-14))
                .offset(x: 132, y: -280)

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.56))
                .frame(width: 176, height: 118)
                .rotationEffect(.degrees(12))
                .offset(x: 128, y: -116)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(red: 0.86, green: 0.93, blue: 0.88).opacity(colorScheme == .dark ? 0.08 : 0.66))
                .frame(width: 154, height: 104)
                .rotationEffect(.degrees(-9))
                .offset(x: -128, y: -38)

            Circle()
                .fill(SafeMealTheme.primarySoft.opacity(colorScheme == .dark ? 0.08 : 0.35))
                .frame(width: 280, height: 280)
                .offset(x: 118, y: 320)
        }
        .ignoresSafeArea()
    }
}

#Preview("浅色模式") {
    SafeMealAuthBackground()
        .preferredColorScheme(.light)
}

#Preview("深色模式") {
    SafeMealAuthBackground()
        .preferredColorScheme(.dark)
}
