import SwiftUI

/// 通用弹窗按钮配置
struct SheetButton {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
}

/// 弹窗容器布局常量（统一管理，改一处全局生效）
private enum SheetLayout {
    static let topPadding: CGFloat = 56
    static let bottomPadding: CGFloat = 20
    static let horizontalPadding: CGFloat = 20
    static let titleSubtitleSpacing: CGFloat = 8
    static let contentTopSpacing: CGFloat = 20
    static let buttonAreaTopSpacing: CGFloat = 20
    static let buttonSpacing: CGFloat = 10

    static let titleLineHeight: CGFloat = 30
    /// subtitle 固定两行空间（36），不管实际显示几行
    static let subtitleBlockHeight: CGFloat = 36

    static let primaryButtonHeightSingle: CGFloat = 52
    static let primaryButtonHeightDouble: CGFloat = 48
    static let secondaryButtonHeight: CGFloat = 44
}

/// 统一弹窗容器 — 所有设置/提示类 Sheet 的外框。
/// 外部只需传入 contentHeight（内容区高度），容器自动计算标题+按钮+间距得到总高度。
struct SafeEatSettingsSheetContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String?
    /// 内容区高度（不含标题、按钮、间距），容器根据此值自动计算 presentationDetents 高度。
    /// 传 nil 时使用 .medium 自动高度，适合内容行数不固定的场景。
    let contentHeight: CGFloat?
    /// 是否允许下滑/遮罩关闭（false 时添加 interactiveDismissDisabled）
    var dismissible: Bool = true
    /// 主按钮（渐变背景）
    var primaryButton: SheetButton?
    /// 次按钮（浅色背景）
    var secondaryButton: SheetButton?
    @ViewBuilder let content: () -> Content

    /// 容器自动计算的总高度（contentHeight 非 nil 时使用）
    private var totalHeight: CGFloat {
        var h: CGFloat = 0
        h += SheetLayout.topPadding
        h += SheetLayout.titleLineHeight
        if subtitle != nil {
            h += SheetLayout.titleSubtitleSpacing
            h += SheetLayout.subtitleBlockHeight
        }
        h += SheetLayout.contentTopSpacing
        h += (contentHeight ?? 0)
        if primaryButton != nil || secondaryButton != nil {
            h += SheetLayout.buttonAreaTopSpacing
            h += buttonAreaHeight
        }
        h += SheetLayout.bottomPadding
        return h
    }

    private var buttonAreaHeight: CGFloat {
        var h: CGFloat = 0
        if primaryButton != nil {
            h += hasTwoButtons ? SheetLayout.primaryButtonHeightDouble : SheetLayout.primaryButtonHeightSingle
        }
        if secondaryButton != nil {
            if primaryButton != nil { h += SheetLayout.buttonSpacing }
            h += SheetLayout.secondaryButtonHeight
        }
        return h
    }

    var body: some View {
        ZStack {
            SafeEatMainGradientBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // 标题区
                VStack(alignment: .leading, spacing: SheetLayout.titleSubtitleSpacing) {
                    Text(title)
                        .font(SafeEatFont.custom(24, relativeTo: .title2, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .frame(height: SheetLayout.subtitleBlockHeight, alignment: .top)
                    }
                }

                // 内容区
                VStack(alignment: .leading, spacing: 16) {
                    content()
                }
                .padding(.top, SheetLayout.contentTopSpacing)

                // 按钮区
                if primaryButton != nil || secondaryButton != nil {
                    buttonArea
                        .padding(.top, SheetLayout.buttonAreaTopSpacing)
                }
            }
            .padding(.horizontal, SheetLayout.horizontalPadding)
            .padding(.top, SheetLayout.topPadding)
            .padding(.bottom, SheetLayout.bottomPadding)
        }
        .presentationDetents(contentHeight != nil ? [.height(totalHeight)] : [.medium])
        .presentationDragIndicator(dismissible ? .visible : .hidden)
        .presentationBackground(.clear)
        .if(!dismissible) { view in
            view.interactiveDismissDisabled()
        }
    }

    // MARK: - 按钮区

    private var buttonArea: some View {
        VStack(spacing: 10) {
            if let primary = primaryButton {
                Button(action: primary.action) {
                    Group {
                        if primary.isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(primary.title)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.vertical, hasTwoButtons ? 14 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(primary.isDisabled || primary.isLoading)
                .opacity(primary.isDisabled ? 0.55 : 1)
            }

            if let secondary = secondaryButton {
                Button(action: secondary.action) {
                    Text(secondary.title)
                        .frame(maxWidth: .infinity)
                        .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(SafeEatTheme.primarySoft)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(SafeEatTheme.primary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var hasTwoButtons: Bool {
        primaryButton != nil && secondaryButton != nil
    }
}

// View modifier 条件扩展
extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
