import SwiftUI

/// 兑换码弹窗 — 输入兑换码获取奖励
struct RedeemCodeSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var code = ""
    @State private var isRedeeming = false
    @State private var errorMessage: String?

    var body: some View {
        SafeMealSettingsSheetContainer(
            title: SafeMealL10n.text(L10nKey.Profile.Redeem.title),
            subtitle: SafeMealL10n.text(L10nKey.Profile.Redeem.subtitle),
            contentHeight: 150,
            primaryButton: SheetButton(
                title: SafeMealL10n.text(L10nKey.Profile.Redeem.action),
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
                                .fill(SafeMealTheme.primary.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "ticket.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeMealTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(SafeMealL10n.text(L10nKey.Profile.Redeem.inputLabel))
                                .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeMealTheme.textPrimary)

                            Text(SafeMealL10n.text(L10nKey.Profile.Redeem.inputHint))
                                .font(SafeMealFont.textStyle(.footnote))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }

                    TextField(SafeMealL10n.text(L10nKey.Profile.Redeem.inputPlaceholder), text: $code)
                        .font(SafeMealFont.textStyle(.body))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(SafeMealTheme.primary.opacity(0.2), lineWidth: 1)
                        )
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    if let error = errorMessage {
                        Text(error)
                            .font(SafeMealFont.textStyle(.caption))
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
                errorMessage = SafeMealL10n.text(L10nKey.Profile.Redeem.failedMessage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isRedeeming = false
    }
}
