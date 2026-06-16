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

    /// 是否还有剩余的看广告次数
    private var canWatchAd: Bool {
        guard isFreeUser, let onWatchAd else { return false }
        // remainingAdWatchCount 为 nil 时（旧版兼容），保守显示
        guard let remaining = snapshot.remainingAdWatchCount else { return true }
        return remaining > 0
    }

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: isFreeUser
                ? SafeEatL10n.text(L10nKey.Home.quotaExceededDailyTitle)
                : SafeEatL10n.text(L10nKey.Home.quotaExceededMonthlyTitle),
            subtitle: isFreeUser
                ? SafeEatL10n.format(L10nKey.Home.quotaExceededDailyHintFormat, snapshot.totalQuota)
                : SafeEatL10n.text(L10nKey.Home.quotaExceededUpgradeHint),
            contentHeight: canWatchAd ? 200 : 150,
            primaryButton: SheetButton(title: "升级会员") {
                onUpgrade?()
            },
            secondaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Home.quotaExceededLater)) {
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
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(quotaHint)
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            // 看广告入口：仅当 Free 用户 + 激励视频启用 + 还有剩余观看次数
            if canWatchAd {
                Button(action: onWatchAd!) {
                    ProfileSurfaceCard {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(SafeEatTheme.primary.opacity(0.12))
                                    .frame(width: 46, height: 46)

                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(SafeEatTheme.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("看广告获取次数")
                                    .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.textPrimary)

                                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededWatchAdHint))
                                    .font(SafeEatFont.textStyle(.footnote))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
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
