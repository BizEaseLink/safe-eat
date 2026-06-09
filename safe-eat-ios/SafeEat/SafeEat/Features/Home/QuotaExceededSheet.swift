import SwiftUI

/// 扫描额度耗尽弹窗 — Home 扫描结果页触发
struct QuotaExceededSheet: View {
    let snapshot: DailyQuotaSnapshot
    let onWatchAd: (() -> Void)?
    let onUpgrade: (() -> Void)?
    let onDismiss: () -> Void

    private var isFreeUser: Bool {
        snapshot.planTier == "free"
    }

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: isFreeUser
                ? SafeEatL10n.text(L10nKey.Home.quotaExceededDailyTitle)
                : SafeEatL10n.text(L10nKey.Home.quotaExceededMonthlyTitle),
            subtitle: isFreeUser
                ? SafeEatL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota)
                : SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradeHint),
            detentHeight: (isFreeUser && onWatchAd != nil) ? 430 : 380
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(isFreeUser ? "今日次数已用完" : "本月次数已用完")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(quotaHint)
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            VStack(spacing: 10) {
                if isFreeUser, let onWatchAd {
                    ProfilePrimaryActionButton(title: "看广告获取次数", isLoading: false) {
                        onWatchAd()
                    }
                }

                ProfilePrimaryActionButton(title: "升级会员", isLoading: false) {
                    onUpgrade?()
                }

                ProfileSecondaryActionButton(title: SafeEatL10n.text(L10nKey.Home.quotaExceededLater)) {
                    onDismiss()
                }
            }
        }
    }

    private var quotaHint: String {
        if isFreeUser {
            return SafeEatL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota)
        }
        if let periodEnd = snapshot.periodEnd {
            return SafeEatL10n.format(L10nKey.Home.quotaExceededMonthlyHintFormat, periodEnd)
        }
        return SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradeHint)
    }
}
