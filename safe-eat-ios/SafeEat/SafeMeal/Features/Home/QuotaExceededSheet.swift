import SwiftUI

/// 扫描额度耗尽弹窗 — Home 扫描结果页触发
struct QuotaExceededSheet: View {
    let snapshot: DailyQuotaSnapshot
    let onUpgrade: (() -> Void)?
    let onDismiss: () -> Void

    private var isFreeUser: Bool {
        snapshot.planTier == "free"
    }

    var body: some View {
        SafeMealSettingsSheetContainer(
            title: isFreeUser
                ? SafeMealL10n.text(L10nKey.Home.quotaExceededDailyTitle)
                : SafeMealL10n.text(L10nKey.Home.quotaExceededMonthlyTitle),
            subtitle: isFreeUser
                ? SafeMealL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota)
                : SafeMealL10n.text(L10nKey.Home.quotaExceededUpgradeHint),
            contentHeight: 150,
            primaryButton: SheetButton(title: "升级会员") {
                onUpgrade?()
            },
            secondaryButton: SheetButton(title: SafeMealL10n.text(L10nKey.Home.quotaExceededLater)) {
                onDismiss()
            }
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
                            .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeMealTheme.textPrimary)

                        Text(quotaHint)
                            .font(SafeMealFont.textStyle(.footnote))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }
            }
        }
    }

    private var quotaHint: String {
        if isFreeUser {
            return SafeMealL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota)
        }
        if let periodEnd = snapshot.periodEnd {
            return SafeMealL10n.format(L10nKey.Home.quotaExceededMonthlyHintFormat, periodEnd)
        }
        return SafeMealL10n.text(L10nKey.Home.quotaExceededUpgradeHint)
    }
}
