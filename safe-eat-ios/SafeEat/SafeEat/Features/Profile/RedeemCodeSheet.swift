import SwiftUI

/// 兑换码弹窗 — 输入兑换码获取奖励
struct RedeemCodeSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isRedeeming = false
    @State private var errorMessage: String?

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Profile.Redeem.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Redeem.subtitle),
            contentHeight: 150,
            primaryButton: SheetButton(
                title: SafeEatL10n.text(L10nKey.Profile.Redeem.action),
                isLoading: isRedeeming,
                isDisabled: code.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                Task { await redeemCode() }
            }
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.primary.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "ticket.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(SafeEatL10n.text(L10nKey.Profile.Redeem.inputLabel))
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text(SafeEatL10n.text(L10nKey.Profile.Redeem.inputHint))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }

                    TextField(SafeEatL10n.text(L10nKey.Profile.Redeem.inputPlaceholder), text: $code)
                        .font(SafeEatFont.textStyle(.body))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(SafeEatTheme.primary.opacity(0.2), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    if let error = errorMessage {
                        Text(error)
                            .font(SafeEatFont.textStyle(.caption))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func redeemCode() async {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isRedeeming = true
        errorMessage = nil

        do {
            let result = try await store.redeemCode(trimmed)
            if result.success {
                dismiss()
            } else {
                errorMessage = SafeEatL10n.text(L10nKey.Profile.Redeem.failedMessage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isRedeeming = false
    }
}
