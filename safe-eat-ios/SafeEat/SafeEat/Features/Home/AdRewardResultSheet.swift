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
        SafeMealSettingsSheetContainer(
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
                                .fill(SafeMealTheme.success.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeMealTheme.success)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("+\(quota) 次扫描")
                                .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeMealTheme.textPrimary)

                            Text(SafeMealL10n.text(L10nKey.Home.quotaExceededTomorrow))
                                .font(SafeMealFont.textStyle(.footnote))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }
                }

            case .claimFailed, .loadFailed:
                ProfileSurfaceCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeMealTheme.warning.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeMealTheme.warning)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("获取失败")
                                .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeMealTheme.textPrimary)

                            Text(SafeMealL10n.text(L10nKey.Home.adRewardRetry))
                                .font(SafeMealFont.textStyle(.footnote))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var titleText: String {
        switch resultType {
        case .success: return SafeMealL10n.text(L10nKey.Home.adRewardSuccessTitle)
        case .claimFailed: return SafeMealL10n.text(L10nKey.Home.adRewardClaimFailedTitle)
        case .loadFailed: return SafeMealL10n.text(L10nKey.Home.adLoadFailedTitle)
        }
    }

    private var messageText: String {
        switch resultType {
        case .success: return SafeMealL10n.text(L10nKey.Home.adRewardSuccess)
        case .claimFailed: return SafeMealL10n.text(L10nKey.Home.adRewardClaimFailed)
        case .loadFailed: return SafeMealL10n.text(L10nKey.Home.adLoadFailed)
        }
    }
}
