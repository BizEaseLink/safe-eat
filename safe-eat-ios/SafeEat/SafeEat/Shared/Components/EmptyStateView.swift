import SwiftUI

/// 通用空状态占位视图
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String, title: String, message: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))

            VStack(spacing: 8) {
                Text(title)
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                if let message {
                    Text(message)
                        .font(SafeEatFont.custom(14, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

#Preview {
    EmptyStateView(
        icon: "fork.knife",
        title: "暂无菜单数据",
     message: "登录后即可查看菜单和识别记录"
    )
}