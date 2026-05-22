import SwiftUI

struct QuotaStatusBar: View {
    let snapshot: DailyQuotaSnapshot

    private var isFreeUser: Bool {
        snapshot.planTier == "free"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isFreeUser ? "sun.max.fill" : "calendar.badge.clock")
                .foregroundStyle(isFreeUser ? .orange : .blue)

            if isFreeUser {
                VStack(alignment: .leading, spacing: 2) {
                    Text(SafeEatL10n.text(L10nKey.Home.quotaStatusBarDailyLabel))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(SafeEatL10n.format(L10nKey.Home.quotaStatusBarCountFormat, snapshot.remainingQuota))
                        .font(.subheadline)
                        .bold()
                }

                if let remaining = snapshot.remainingAdWatchCount, remaining > 0,
                   let reward = snapshot.adRewardPerWatch, reward > 0 {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.caption)
                        Text(SafeEatL10n.format(L10nKey.Home.quotaStatusBarAdRewardFormat, reward))
                            .font(.caption2)
                    }
                    .foregroundStyle(.green)
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(SafeEatL10n.text(L10nKey.Home.quotaStatusBarMonthlyLabel))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(SafeEatL10n.format(L10nKey.Home.quotaStatusBarCountFormat, snapshot.monthlyRemaining ?? snapshot.remainingQuota))
                        .font(.subheadline)
                        .bold()
                }

                if let periodEnd = snapshot.periodEnd {
                    Spacer()
                    Text(SafeEatL10n.format(L10nKey.Home.quotaStatusBarCycleEndFormat, periodEnd))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 额度进度条
            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .frame(width: 60)
                .tint(progressColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            )
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
            )
        )
    }
    .padding()
}
