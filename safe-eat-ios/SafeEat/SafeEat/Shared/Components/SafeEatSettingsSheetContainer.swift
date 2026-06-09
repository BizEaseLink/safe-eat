import SwiftUI

/// 统一弹窗容器 — 所有设置/提示类 Sheet 的外框。
/// 布局规则：顶部 20 + 内容自适应 + 底部 15，弹窗高度由 detentHeight 参数指定
struct SafeEatSettingsSheetContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    /// 弹窗内容区总高度（含顶部20 + 内容 + 底部15），用于 .presentationDetents
    let detentHeight: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            SafeEatMainGradientBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                // 标题区 — 顶部空间与左右留白一致(20)
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

                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 15)
        }
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.clear)
    }
}
