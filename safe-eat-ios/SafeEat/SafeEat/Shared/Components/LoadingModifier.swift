import SwiftUI

/// Loading 覆盖层 ViewModifier
/// 用法：.loading(isShowing: isLoading, text: "加载中")
struct LoadingModifier: ViewModifier {
    let isShowing: Bool
    let text: String

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isShowing)
                .blur(radius: isShowing ? 2 : 0)

            if isShowing {
                Color.black
                    .opacity(0.2)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .tint(SafeEatTheme.primary)
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(32)
                .background(Color.white.opacity(0.85))
                .cornerRadius(16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowing)
    }
}

extension View {
    /// 添加 Loading 覆盖层
    func loading(isShowing: Bool, text: String = "加载中") -> some View {
        modifier(LoadingModifier(isShowing: isShowing, text: text))
    }
}
