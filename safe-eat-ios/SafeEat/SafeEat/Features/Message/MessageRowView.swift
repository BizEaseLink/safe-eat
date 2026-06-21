import SwiftUI

/// 消息列表行组件 — 可在 MessageCenterView 内复用
struct MessageRowView: View {
    let message: NotificationMessage
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color {
        message.isRead ? SafeEatTheme.textSecondary : SafeEatTheme.textPrimary
    }

    private var contentColor: Color {
        message.isRead ? SafeEatTheme.textSecondary.opacity(0.7) : SafeEatTheme.textSecondary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // 未读小圆点
                Circle()
                    .fill(message.isRead ? Color.clear : SafeEatTheme.danger)
                    .frame(width: 8, height: 8)
                    .padding(.top, 7)

                VStack(alignment: .leading, spacing: 6) {
                    // 类型标签 + 时间
                    HStack(spacing: 8) {
                        Text(message.typeLabel)
                            .font(SafeEatFont.custom(12, relativeTo: .caption2))
                            .foregroundStyle(SafeEatTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SafeEatTheme.primary.opacity(0.10))
                            .clipShape(Capsule())

                        Spacer()

                        Text(message.createdAt.notificationTimeText)
                            .font(SafeEatFont.custom(12, relativeTo: .caption2))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }

                    // 标题
                    Text(message.displayTitle)
                        .font(SafeEatFont.custom(16, relativeTo: .body))
                        .foregroundStyle(titleColor)
                        .lineLimit(2)

                    // 内容
                    Text(message.displayContent)
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                        .foregroundStyle(contentColor)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 时间格式化

private extension String {
    var notificationTimeText: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: self) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: self) else {
                return self
            }
            return formatRelative(date)
        }
        return formatRelative(date)
    }

    private func formatRelative(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale

        if calendar.isDate(date, inSameDayAs: now) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return SafeEatL10n.isZh ? "昨天" : "Yesterday"
        }

        if let daysDiff = calendar.dateComponents([.day], from: date, to: now).day, daysDiff < 7 {
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }

        formatter.dateFormat = SafeEatL10n.isZh ? "M月d日" : "MMM d"
        return formatter.string(from: date)
    }
}
