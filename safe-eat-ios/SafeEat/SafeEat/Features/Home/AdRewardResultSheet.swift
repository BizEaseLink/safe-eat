import SwiftUI

struct AdRewardResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let resultType: AdRewardResultType

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
                    statusCard
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
        isSuccess ? 404 : 364
    }

    private var isSuccess: Bool {
        if case .success = resultType { return true }
        return false
    }

    // MARK: - Hero

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(heroTint.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 58, height: 58)

            Image(systemName: heroSymbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(heroTint)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: heroTint.opacity(0.14), radius: 18, y: 8)
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(spacing: 7) {
            Text(titleText)
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(messageText)
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
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

    // MARK: - Quota Badge

    @ViewBuilder
    private var statusCard: some View {
        switch resultType {
        case .success(let quota):
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SafeEatTheme.success.opacity(colorScheme == .dark ? 0.18 : 0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.success)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(SafeEatL10n.format(L10nKey.Home.adRewardSuccessQuotaFormat, quota))
                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(stateCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(stateCardStroke, lineWidth: 1)
            )

        case .claimFailed, .loadFailed:
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.18 : 0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.warning)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(messageText)
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .lineLimit(2)
                    Text(SafeEatL10n.text(L10nKey.Home.adRewardRetry))
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(stateCardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(stateCardStroke, lineWidth: 1)
            )
        }
    }

    // MARK: - Action

    private var actionArea: some View {
        VStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isSuccess ? "checkmark" : "arrow.clockwise")
                        .font(.system(size: 16, weight: .bold))
                    Text(SafeEatL10n.text(L10nKey.Home.adRewardRetry))
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

            if isSuccess {
                Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                    .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Colors

    private var heroTint: Color {
        isSuccess ? SafeEatTheme.success : SafeEatTheme.warning
    }

    private var heroSymbol: String {
        isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
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

    private var stateCardFill: Color {
        isSuccess
            ? (colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primarySoft.opacity(0.72))
            : (colorScheme == .dark ? SafeEatTheme.warning.opacity(0.12) : SafeEatTheme.warning.opacity(0.10))
    }

    private var stateCardStroke: Color {
        isSuccess
            ? (colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primary.opacity(0.08))
            : (colorScheme == .dark ? SafeEatTheme.warning.opacity(0.18) : SafeEatTheme.warning.opacity(0.16))
    }
}
