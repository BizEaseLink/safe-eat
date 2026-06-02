import SwiftUI

/// 统一弹窗容器 — 所有设置/提示类 Sheet 的外框。
/// 布局规则：顶部 20 + 内容自适应 + 底部 15，弹窗高度 = 内容高度
struct SafeEatSettingsSheetContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    @State private var contentHeight: CGFloat = 0

    var body: some View {
        ZStack {
            SafeEatMainGradientBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                // 标题区 — 顶部空间 20
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(SafeEatFont.custom(24, relativeTo: .title2, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
                .padding(.top, 20)

                content()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ContentHeightPreferenceKey.self,
                        value: geo.size.height
                    )
                }
            )
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                contentHeight = height
            }
        }
        .presentationDetents([.height(contentHeight > 0 ? contentHeight : 200)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
