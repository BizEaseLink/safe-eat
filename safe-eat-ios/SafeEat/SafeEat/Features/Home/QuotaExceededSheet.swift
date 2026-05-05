import SwiftUI

struct QuotaExceededSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    let onUpgrade: () -> Void
    var onWatchAd: (() -> Void)? = nil

    private var totalQuota: Int { store.dailyQuota?.totalQuota ?? 3 }

    private var remainingQuota: Int { store.dailyQuota?.remainingQuota ?? 0 }

    private var remainingAdWatches: Int {
        guard store.profile?.currentPlanTier == nil || store.profile?.currentPlanTier == "free" else { return 0 }
        return max(0, 3 - (store.dailyQuota?.adClaimsCount ?? 0))
    }

    private var rewardPerWatch: Int { 3 }

    private var progressValue: Double {
        guard totalQuota > 0 else { return 0 }
        return min(Double(remainingQuota) / Double(totalQuota), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Capsule()
                    .fill(dragIndicatorColor)
                    .frame(width: 42, height: 6)
                    .padding(.top, 10)
                    .padding(.bottom, 14)

                VStack(spacing: 16) {
                    warningIcon

                    titleBlock

                    quotaProgress

                    if onWatchAd != nil && remainingAdWatches > 0 {
                        adRewardHint
                    }

                    memberHintCard

                    actionArea
                }
                .padding(.horizontal, 24)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 10))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(sheetFill)
            .background(.ultraThinMaterial)
            .shadow(color: sheetShadow, radius: 28, y: -8)
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(36)
    }

    private var sheetHeight: CGFloat {
        if onWatchAd != nil && remainingAdWatches > 0 {
            return 500
        }
        return onWatchAd == nil ? 382 : 440
    }

    private var titleBlock: some View {
        VStack(spacing: 7) {
            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTitle))
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(SafeEatL10n.format(L10nKey.Home.quotaExceededStatusFormat, remainingQuota, totalQuota))
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var adRewardHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 13, weight: .semibold))
            Text(SafeEatL10n.format(L10nKey.Home.quotaExceededAdRewardFormat, rewardPerWatch, remainingAdWatches))
                .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(SafeEatTheme.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(adHintFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(adHintStroke, lineWidth: 1)
        )
    }

    private var quotaProgress: some View {
        VStack(spacing: 10) {
            HStack {
                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededProgressLabel))
                    .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                Spacer()
                Text("\(remainingQuota)/\(totalQuota)")
                    .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(progressTrack)

                    Capsule()
                        .fill(progressFill)
                        .frame(width: max(proxy.size.width * progressValue, 10))
                }
            }
            .frame(height: 10)
            .overlay(
                Capsule()
                    .stroke(progressStroke, lineWidth: 1)
            )
            .animation(.easeOut(duration: 0.24), value: progressValue)
        }
        .padding(.horizontal, 12)
    }

    private var memberHintCard: some View {
        Button {
            dismiss()
            onUpgrade()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(memberIconFill)
                        .frame(width: 42, height: 42)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                }

                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededMemberHint))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.74))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(memberCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(memberCardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var actionArea: some View {
        VStack(spacing: 10) {
            Button {
                dismiss()
                onUpgrade()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(SafeEatL10n.text(L10nKey.Home.quotaExceededUpgrade))
                        .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.86)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.20), radius: 18, y: 10)
            }
            .buttonStyle(.plain)

            if let onWatchAd {
                Button {
                    dismiss()
                    onWatchAd()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.rectangle.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text(remainingAdWatches > 0
                            ? SafeEatL10n.format(L10nKey.Home.quotaExceededWatchAdWithCount, remainingAdWatches)
                            : SafeEatL10n.text(L10nKey.Home.quotaExceededWatchAd))
                            .font(SafeEatFont.custom(16, relativeTo: .subheadline, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(remainingAdWatches > 0 ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(adButtonFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(adButtonStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(remainingAdWatches <= 0)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .semibold))
                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(SafeEatTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var warningIcon: some View {
        ZStack {
            Circle()
                .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 58, height: 58)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(SafeEatTheme.warning)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: SafeEatTheme.warning.opacity(0.14), radius: 18, y: 8)
    }

    private var sheetFill: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.72)
            : Color.white.opacity(0.78)
    }

    private var sheetShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.32) : SafeEatTheme.primaryDeep.opacity(0.12)
    }

    private var dragIndicatorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.24)
    }

    private var progressTrack: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.89, green: 0.86, blue: 0.80).opacity(0.62)
    }

    private var progressStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.68)
    }

    private var progressFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.72, green: 0.36, blue: 0.27),
                Color(red: 0.84, green: 0.48, blue: 0.34),
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var memberCardFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primarySoft.opacity(0.72)
    }

    private var memberCardStroke: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primary.opacity(0.08)
    }

    private var memberIconFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.accent.opacity(0.46)
    }

    private var adButtonFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.56)
    }

    private var adButtonStroke: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.34) : SafeEatTheme.primary.opacity(0.32)
    }

    private var adHintFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.12) : SafeEatTheme.primarySoft.opacity(0.56)
    }

    private var adHintStroke: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.20) : SafeEatTheme.primary.opacity(0.16)
    }
}