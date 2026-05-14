import SwiftUI

struct QuotaExceededSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    private var adConfig: AdConfigStore { AdConfigStore.shared }

    let onUpgrade: () -> Void
    var onWatchAd: (() -> Void)? = nil

    private var freeQuotaTotal: Int { max(store.dailyQuota?.totalQuota ?? 3, 0) }
    private var remainingQuota: Int { max(store.dailyQuota?.remainingQuota ?? 0, 0) }
    private var usedQuota: Int { max(store.dailyQuota?.usedCount ?? (freeQuotaTotal - remainingQuota), 0) }

    private var rewardVideoPlacement: AdPlacementConfig? {
        adConfig.placement(for: .rewardVideo)
    }

    private var adRewardPerWatch: Int {
        max(rewardVideoPlacement?.rewardQuota ?? store.dailyQuota?.adRewardPerWatch ?? 3, 1)
    }

    private var adWatchLimit: Int {
        max(rewardVideoPlacement?.dailyLimit ?? store.dailyQuota?.adWatchLimit ?? 3, 0)
    }

    private var remainingAdWatches: Int {
        guard store.profile?.currentPlanTier == nil || store.profile?.currentPlanTier == "free" else { return 0 }
        if let backendRemaining = store.dailyQuota?.remainingAdWatchCount {
            return max(0, backendRemaining)
        }
        return max(0, adWatchLimit - (store.dailyQuota?.adClaimsCount ?? 0))
    }

    private var claimedAdQuota: Int {
        min((store.dailyQuota?.adClaimsCount ?? 0) * adRewardPerWatch, maxAdRecoverableQuota)
    }

    private var maxAdRecoverableQuota: Int {
        adWatchLimit * adRewardPerWatch
    }

    private var maxTotalQuota: Int {
        freeQuotaTotal + maxAdRecoverableQuota
    }

    private var freeQuotaUsed: Int {
        min(usedQuota, freeQuotaTotal)
    }

    private var progressRatio: Double {
        guard maxTotalQuota > 0 else { return 0 }
        return min(Double(usedQuota) / Double(maxTotalQuota), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Capsule()
                    .fill(dragIndicatorColor)
                    .frame(width: 42, height: 6)
                    .padding(.top, 10)
                    .padding(.bottom, 16)

                VStack(spacing: 16) {
                    heroIcon
                    titleBlock
                    quotaCard
                    metricRow
                    actionArea
                }
                .padding(.horizontal, 24)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12))
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
        onWatchAd == nil ? 520 : 610
    }

    // MARK: - Hero

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 58, height: 58)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(SafeEatTheme.warning)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: SafeEatTheme.warning.opacity(0.14), radius: 18, y: 8)
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(spacing: 7) {
            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTitle))
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededSubtitle))
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Quota Card

    private var quotaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTotalTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                Text("\(usedQuota)/\(maxTotalQuota)")
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(progressTrack)

                    Capsule()
                        .fill(progressFill)
                        .frame(width: max(proxy.size.width * progressRatio, progressRatio > 0 ? 10 : 0))
                }
            }
            .frame(height: 12)
            .overlay(
                Capsule()
                    .stroke(progressStroke, lineWidth: 1)
            )

            HStack(spacing: 4) {
                Text(SafeEatL10n.format(L10nKey.Home.quotaExceededTotalFootnoteFormat, usedQuota, maxTotalQuota - usedQuota))
                    .font(SafeEatFont.custom(13, relativeTo: .footnote))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                Spacer()
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(totalCardFill)
        )
    }

    // MARK: - Metric Row

    private var metricRow: some View {
        HStack(spacing: 0) {
            metricCell(
                icon: "lock.fill",
                tint: SafeEatTheme.primary,
                title: SafeEatL10n.text(L10nKey.Home.quotaExceededFreeQuotaTitle),
                value: "\(freeQuotaUsed)/\(freeQuotaTotal)",
                ratio: freeQuotaTotal > 0 ? Double(freeQuotaUsed) / Double(freeQuotaTotal) : 0
            )

            Rectangle()
                .fill(SafeEatTheme.line)
                .frame(width: 1)
                .padding(.vertical, 8)

            metricCell(
                icon: "play.rectangle.fill",
                tint: SafeEatTheme.warning,
                title: SafeEatL10n.text(L10nKey.Home.quotaExceededAdQuotaTitle),
                value: "\(claimedAdQuota)/\(maxAdRecoverableQuota)",
                ratio: maxAdRecoverableQuota > 0 ? Double(claimedAdQuota) / Double(maxAdRecoverableQuota) : 0
            )
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

    private var actionArea: some View {
        VStack(spacing: 12) {
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
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                        Text(SafeEatL10n.format(L10nKey.Home.quotaExceededWatchAdRecoverFormat, adRewardPerWatch))
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
                            .stroke(adButtonStroke, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(remainingAdWatches <= 0)
            }

            VStack(alignment: .leading, spacing: 6) {
                infoRow(icon: "clock", text: SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                infoRow(
                    icon: "info.circle",
                    text: SafeEatL10n.format(L10nKey.Home.quotaExceededRuleFormat, adWatchLimit, adRewardPerWatch)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func metricCell(
        icon: String,
        tint: Color,
        title: String,
        value: String,
        ratio: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.18 : 0.14))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(tint)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SafeEatFont.custom(13, relativeTo: .footnote))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Text(value)
                        .font(SafeEatFont.custom(24, relativeTo: .title2, weight: .bold))
                        .foregroundStyle(tint)
                }
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(tint.opacity(colorScheme == .dark ? 0.14 : 0.12))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(proxy.size.width * ratio, ratio > 0 ? 8 : 0))
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
                .frame(width: 16, height: 16)
            Text(text)
                .font(SafeEatFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: - Colors

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
        colorScheme == .dark ? Color.white.opacity(0.10) : Color(red: 0.90, green: 0.92, blue: 0.91).opacity(0.92)
    }

    private var progressStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.68)
    }

    private var progressFill: LinearGradient {
        LinearGradient(
            colors: [SafeEatTheme.warning, SafeEatTheme.danger],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var totalCardFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.12) : SafeEatTheme.primarySoft.opacity(0.36)
    }

    private var adButtonFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.96)
    }

    private var adButtonStroke: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.34) : SafeEatTheme.primary.opacity(0.24)
    }
}
