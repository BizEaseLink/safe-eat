import SwiftUI

enum AdRewardResultType {
    case claimFailed
    case loadFailed
    case success(rewardQuota: Int)
}

/// 看广告奖励结果弹窗
struct AdRewardResultSheet: View {
    @Environment(\.dismiss) private var dismiss

    let resultType: AdRewardResultType

    private var isSuccess: Bool {
        if case .success = resultType { return true }
        return false
    }

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: titleText,
            subtitle: messageText,
            contentHeight: 110,
            primaryButton: SheetButton(title: isSuccess ? "好的" : "重试") {
                dismiss()
            }
        ) {
            switch resultType {
            case .success(let quota):
                ProfileSurfaceCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.success.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.success)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("+\(quota) 次扫描")
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }

            case .claimFailed, .loadFailed:
                ProfileSurfaceCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.warning.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.warning)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("获取失败")
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text(SafeEatL10n.text(L10nKey.Home.adRewardRetry))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var titleText: String {
        switch resultType {
        case .success: return SafeEatL10n.text(L10nKey.Home.adRewardSuccessTitle)
        case .claimFailed: return SafeEatL10n.text(L10nKey.Home.adRewardClaimFailedTitle)
        case .loadFailed: return SafeEatL10n.text(L10nKey.Home.adLoadFailedTitle)
        }
    }

    private var messageText: String {
        switch resultType {
        case .success: return SafeEatL10n.text(L10nKey.Home.adRewardSuccess)
        case .claimFailed: return SafeEatL10n.text(L10nKey.Home.adRewardClaimFailed)
        case .loadFailed: return SafeEatL10n.text(L10nKey.Home.adLoadFailed)
        }
    }
}
