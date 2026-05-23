import SwiftUI

struct QuotaExceededSheet: View {
    let snapshot: DailyQuotaSnapshot
    let onWatchAd: (() -> Void)?
    let onUpgrade: (() -> Void)?
    let onDismiss: () -> Void

    private var isFreeUser: Bool {
        snapshot.planTier == "free"
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(isFreeUser
                ? SafeEatL10n.text(L10nKey.Home.quotaExceededDailyTitle)
                : SafeEatL10n.text(L10nKey.Home.quotaExceededMonthlyTitle))
                .font(.headline)

            if isFreeUser {
                Text(SafeEatL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                if let periodEnd = snapshot.periodEnd {
                    Text(SafeEatL10n.format(L10nKey.Home.quotaExceededMonthlyHintFormat, periodEnd))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradeHint))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                if isFreeUser, let onWatchAd {
                    Button(action: onWatchAd) {
                        Label(SafeEatL10n.text(L10nKey.Home.quotaExceededWatchAdAction), systemImage: "play.rectangle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Button(action: { onUpgrade?() }) {
                    Label(isFreeUser
                        ? SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradeMembership)
                        : SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradePlan), systemImage: "crown.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(SafeEatL10n.text(L10nKey.Home.quotaExceededLater)) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
    }
}

#Preview {
    QuotaExceededSheet(
        snapshot: DailyQuotaSnapshot(
            planTier: "free",
            totalQuota: 1,
            usedCount: 1,
            remainingQuota: 0,
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
        onWatchAd: {},
        onUpgrade: {},
        onDismiss: {}
    )
}
