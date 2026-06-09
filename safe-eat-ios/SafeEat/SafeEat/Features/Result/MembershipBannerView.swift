import SwiftUI

// MARK: - 会员引导横幅

/// 正面（替换 NativeAdView）和背面（所有 section 之后）复用
/// 根据用户 tier 传入不同文案

struct MembershipBannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    let tier: MembershipTier
    let isFront: Bool
    let onUpgrade: () -> Void

    private var titleText: String {
        switch tier {
        case .free:
            return isFront
                ? SafeEatL10n.text(L10nKey.Result.membershipBannerTitleFree)
                : SafeEatL10n.text(L10nKey.Result.membershipBannerSubtitleFree)
        case .lite:
            return isFront
                ? SafeEatL10n.text(L10nKey.Result.membershipBannerTitleLite)
                : SafeEatL10n.text(L10nKey.Result.membershipBannerSubtitleLite)
        case .pro:
            return isFront
                ? SafeEatL10n.text(L10nKey.Result.membershipBannerTitlePro)
                : SafeEatL10n.text(L10nKey.Result.membershipBannerSubtitlePro)
        case .premium:
            return ""
        }
    }

    private var subtitleText: String {
        switch tier {
        case .free:
            return SafeEatL10n.text(L10nKey.Result.membershipBannerDescFree)
        case .lite:
            return SafeEatL10n.text(L10nKey.Result.membershipBannerDescLite)
        case .pro:
            return SafeEatL10n.text(L10nKey.Result.membershipBannerDescPro)
        case .premium:
            return ""
        }
    }

    var body: some View {
        if tier != .premium {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleText)
                            .font(SafeEatFont.custom(16, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(.white)

                        Text(subtitleText)
                            .font(SafeEatFont.custom(13, relativeTo: .footnote))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    Button {
                        onUpgrade()
                    } label: {
                        Text(SafeEatL10n.text(L10nKey.Result.membershipBannerAction))
                            .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .semibold))
                            .foregroundStyle(Color(red: 0.62, green: 0.44, blue: 0.20))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.76, green: 0.58, blue: 0.28),
                                Color(red: 0.62, green: 0.44, blue: 0.20),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
    }
}