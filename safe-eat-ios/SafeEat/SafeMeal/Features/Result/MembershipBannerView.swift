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
                ? SafeMealL10n.text(L10nKey.Result.membershipBannerTitleFree)
                : SafeMealL10n.text(L10nKey.Result.membershipBannerSubtitleFree)
        case .lite:
            return isFront
                ? SafeMealL10n.text(L10nKey.Result.membershipBannerTitleLite)
                : SafeMealL10n.text(L10nKey.Result.membershipBannerSubtitleLite)
        case .pro:
            return isFront
                ? SafeMealL10n.text(L10nKey.Result.membershipBannerTitlePro)
                : SafeMealL10n.text(L10nKey.Result.membershipBannerSubtitlePro)
        case .premium:
            return ""
        }
    }

    private var subtitleText: String {
        switch tier {
        case .free:
            return SafeMealL10n.text(L10nKey.Result.membershipBannerDescFree)
        case .lite:
            return SafeMealL10n.text(L10nKey.Result.membershipBannerDescLite)
        case .pro:
            return SafeMealL10n.text(L10nKey.Result.membershipBannerDescPro)
        case .premium:
            return ""
        }
    }

    var body: some View {
        if tier != .premium {
            VStack(alignment: .leading, spacing: 12) {
                // 标题行：皇冠 + 升级文案
                HStack(spacing: 10) {
                    HugeIcon(glyph: .crown03, size: 22)
                        .foregroundStyle(.white)

                    Text(titleText)
                        .font(SafeMealFont.custom(16, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                // 说明：当前 tier 能看什么 / 升级后解锁什么
                Text(subtitleText)
                    .font(SafeMealFont.custom(13, relativeTo: .footnote))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // 全宽主按钮（白底绿字，与 Paywall 的 CTA 风格一致）
                Button {
                    onUpgrade()
                } label: {
                    Text(SafeMealL10n.text(L10nKey.Result.membershipBannerAction))
                        .font(SafeMealFont.custom(14, relativeTo: .subheadline, weight: .semibold))
                        .foregroundStyle(SafeMealTheme.primaryDeep)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            // 深色模式：稍亮绿 → 深绿，避免深背景上整块发黑
                            colors: colorScheme == .dark
                                ? [SafeMealTheme.primary, SafeMealTheme.primaryDeep]
                                : [SafeMealTheme.primaryDeep, SafeMealTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                colorScheme == .dark ? Color.white.opacity(0.16) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
