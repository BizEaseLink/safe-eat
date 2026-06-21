import SwiftUI

/// 消息行卡片 — 未读红点 + 已读灰色
struct MessageRowView: View {
    let message: NotificationMessage
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - 颜色

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(message.isRead ? 0.03 : 0.06)
            : Color.white
    }

    private var cardStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(message.isRead ? 0.05 : 0.08)
            : SafeEatTheme.line
    }

    private var titleColor: Color {
        message.isRead ? SafeEatTheme.textSecondary : SafeEatTheme.textPrimary
    }

    private var timeColor: Color {
        SafeEatTheme.textSecondary.opacity(message.isRead ? 0.4 : 0.6)
    }

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // 左侧：未读红点
                VStack {
                    Circle()
                        .fill(message.isRead ? Color.clear : SafeEatTheme.danger)
                        .frame(width: 8, height: 8)
                    Spacer()
                }

                // 中间：标签 + 标题 + 时间
                VStack(alignment: .leading, spacing: 8) {
                    // 类型标签（已读变灰）
                    typeTag

                    // 标题
                    Text(SafeEatL10n.isZh ? (message.title ?? "") : (message.titleEn ?? message.title ?? ""))
                        .font(SafeEatFont.custom(16, relativeTo: .body, weight: message.isRead ? .regular : .semibold))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)

                    // 时间
                    if let createdAt = message.createdAt {
                        Text(createdAt.notificationTimeText)
                            .font(SafeEatFont.custom(12, relativeTo: .caption2))
                            .foregroundStyle(timeColor)
                    }
                }

                Spacer()

                // 右箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(cardStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.0 : 0.04), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 类型标签（已读灰色，未读彩色）

    private var typeTag: some View {
        let colors = message.typeColor
        let label = SafeEatL10n.isZh ? message.typeLabel : message.enTypeLabel

        if message.isRead {
            // 已读：灰色标签
            return AnyView(
                Text(label)
                    .font(SafeEatFont.custom(12, relativeTo: .caption2))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(SafeEatTheme.line.opacity(colorScheme == .dark ? 0.12 : 0.6)))
            )
        } else {
            // 未读：彩色标签
            return AnyView(
                Text(label)
                    .font(SafeEatFont.custom(12, relativeTo: .caption2, weight: .bold))
                    .foregroundStyle(Color(hex: colors.fg))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: colors.bg).opacity(colorScheme == .dark ? 0.15 : 1.0)))
            )
        }
    }
}

// MARK: - 时间格式化

extension String {
    var notificationTimeText: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: self) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: self) else { return self }
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

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
