import SwiftUI

struct LoginPromptSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    let featureHint: String?

    init(featureHint: String? = nil) {
        self.featureHint = featureHint
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
                    iconView

                    titleBlock

                    featureHintCard

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
        .presentationDetents([.height(featureHint != nil ? 340 : 300)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(36)
    }

    private var hintMessage: String {
        if let featureHint {
            return SafeEatL10n.format(L10nKey.Auth.loginPromptFeatureFormat, featureHint)
        }
        return SafeEatL10n.text(L10nKey.Auth.loginPromptMessage)
    }

    private var titleBlock: some View {
        VStack(spacing: 7) {
            Text(SafeEatL10n.text(L10nKey.Auth.loginPromptTitle))
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(hintMessage)
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
    private var featureHintCard: some View {
        if let featureHint {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(memberIconFill)
                        .frame(width: 42, height: 42)

                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                }

                Text(featureHint)
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
    }

    private var actionArea: some View {
        VStack(spacing: 10) {
                Button {
                    dismiss()
                    store.dismissLoginPrompt()
                    store.goToLogin()
                } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 16, weight: .bold))
                    Text(SafeEatL10n.text(L10nKey.Auth.goLogin))
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

            Button {
                dismiss()
                store.dismissLoginPrompt()
            } label: {
                Text(SafeEatL10n.text(L10nKey.Auth.loginPromptLater))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 58, height: 58)

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: SafeEatTheme.primary.opacity(0.14), radius: 18, y: 8)
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

    private var memberCardFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primarySoft.opacity(0.72)
    }

    private var memberCardStroke: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.16) : SafeEatTheme.primary.opacity(0.08)
    }

    private var memberIconFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.accent.opacity(0.46)
    }
}
