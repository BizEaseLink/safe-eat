import SwiftUI

struct QuotaStatusBar: View {
    let snapshot: DailyQuotaSnapshot
    var onShowMembership: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var isFreeUser: Bool {
        snapshot.planTier == "free"
    }

    var body: some View {
        VStack(spacing: 14) {
            // 标题行：图标 + 标签 + 次数
            HStack(spacing: 10) {
                Image(systemName: isFreeUser ? "sun.max.fill" : "calendar.badge.clock")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isFreeUser ? .orange : .blue)

                Text(isFreeUser
                    ? SafeMealL10n.text(L10nKey.Home.quotaStatusBarDailyLabel)
                    : SafeMealL10n.text(L10nKey.Home.quotaStatusBarMonthlyLabel))
                    .font(SafeMealFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeMealTheme.textSecondary)

                Spacer()

                Text(SafeMealL10n.format(
                    L10nKey.Home.quotaStatusBarCountFormat,
                    isFreeUser ? snapshot.remainingQuota : (snapshot.monthlyRemaining ?? snapshot.remainingQuota)
                ))
                .font(SafeMealFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
            }

            // 进度条（全宽）
            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .tint(progressColor)

            // 底部行：看会员按钮 + 周期信息
            HStack {
                // 看会员按钮
                Button {
                    onShowMembership?()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "military_tech")
                            .font(.system(size: 12, weight: .semibold))
                        Text(SafeMealL10n.text(L10nKey.Home.memberAction))
                            .font(SafeMealFont.custom(12, relativeTo: .caption, weight: .bold))
                    }
                    .foregroundStyle(SafeMealTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(SafeMealTheme.primarySoft)
                    )
                    .overlay(
                        Capsule()
                            .stroke(SafeMealTheme.primary.opacity(0.18), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // 周期信息
                if isFreeUser {
                    if !snapshot.quotaDate.isEmpty {
                        Text(SafeMealL10n.format(L10nKey.Home.quotaStatusBarCycleEndFormat, snapshot.quotaDate))
                            .font(SafeMealFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                } else {
                    if let periodEnd = snapshot.periodEnd {
                        Text(SafeMealL10n.format(L10nKey.Home.quotaStatusBarCycleEndFormat, periodEnd))
                            .font(SafeMealFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: SafeMealTheme.primaryDeep.opacity(0.10), radius: 22, y: 14)
    }

    private var cardGradient: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                : [Color.white.opacity(0.92), Color(red: 0.95, green: 0.98, blue: 0.95).opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line
    }

    private var progressValue: Double {
        if isFreeUser {
            return snapshot.totalQuota > 0
                ? Double(snapshot.remainingQuota) / Double(snapshot.totalQuota)
                : 0
        }
        let total = snapshot.monthlyTotalQuota ?? snapshot.totalQuota
        let remaining = snapshot.monthlyRemaining ?? snapshot.remainingQuota
        return total > 0 ? Double(remaining) / Double(total) : 0
    }

    private var progressColor: Color {
        if progressValue > 0.5 { return .green }
        if progressValue > 0.2 { return .orange }
        return .red
    }
}

#Preview {
    VStack(spacing: 16) {
        QuotaStatusBar(
            snapshot: DailyQuotaSnapshot(
                planTier: "free",
                totalQuota: 3,
                usedCount: 1,
                remainingQuota: 2,
                adClaimsCount: 0,
                adRewardPerWatch: 1,
                adWatchLimit: 2,
                remainingAdWatchCount: 2,
                quotaDate: "2026-05-14",
                monthlyTotalQuota: nil,
                monthlyUsedCount: nil,
                monthlyRemaining: nil,
                periodStart: nil,
                periodEnd: nil
            ),
            onShowMembership: { print("看会员") }
        )
        QuotaStatusBar(
            snapshot: DailyQuotaSnapshot(
                planTier: "PRO",
                totalQuota: 0,
                usedCount: 0,
                remainingQuota: 0,
                adClaimsCount: 0,
                adRewardPerWatch: nil,
                adWatchLimit: nil,
                remainingAdWatchCount: nil,
                quotaDate: "2026-05-14",
                monthlyTotalQuota: 600,
                monthlyUsedCount: 200,
                monthlyRemaining: 400,
                periodStart: "2026-05-01",
                periodEnd: "2026-05-31"
            ),
            onShowMembership: { print("看会员") }
        )
    }
    .padding()
}
