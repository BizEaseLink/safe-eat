import SwiftUI

struct RedeemCodeSheet: View {
    @ObservedObject var store: AppStore
    @State private var code = ""
    @State private var isRedeeming = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "ticket")
                    .font(.system(size: 36))
                    .foregroundStyle(SafeEatTheme.primary)

                Text(SafeEatL10n.text(L10nKey.Membership.redeemCodeSheetTitle))
                    .font(SafeEatFont.custom(18, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                TextField(SafeEatL10n.text(L10nKey.Membership.redeemCodePlaceholder), text: $code)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .font(SafeEatFont.textStyle(.body))
                    .padding(.horizontal, 20)

                if let error = errorMessage {
                    Text(error)
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(.red)
                }

                if let success = successMessage {
                    Text(success)
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(.green)
                }

                ProfilePrimaryActionButton(
                    title: SafeEatL10n.text(L10nKey.Membership.redeemCodeAction),
                    isLoading: isRedeeming,
                    isDisabled: code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    Task {
                        await redeem()
                    }
                }
            }
            .padding(20)
            .navigationTitle(SafeEatL10n.text(L10nKey.Membership.redeemCodeTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SafeEatL10n.text(L10nKey.Common.cancel)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func redeem() async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isRedeeming = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await store.redeemCode(trimmed)
            successMessage = SafeEatL10n.text(L10nKey.Membership.redeemCodeSuccess)
            code = ""
            await store.loadMembershipStatus()
        } catch {
            errorMessage = SafeEatL10n.text(L10nKey.Membership.redeemCodeInvalid)
        }

        isRedeeming = false
    }
}
