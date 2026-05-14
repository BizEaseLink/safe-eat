import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = false
    @State private var showConfirmDialog = false
    @State private var errorMessage: String?

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.DeleteAccount.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.DeleteAccount.subtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.warningTitle))
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(SafeEatTheme.danger)
                    }

                    Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.warningBody))
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
        } footer: {
            Button(role: .destructive, action: { showConfirmDialog = true }) {
                Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmButton))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SafeEatTheme.danger)
            .disabled(isLoading)
        }
        .alert(
            SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmDialogTitle),
            isPresented: $showConfirmDialog
        ) {
            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
            Button(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmButton), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmDialogMessage))
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: .constant(errorMessage != nil)) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func deleteAccount() {
        isLoading = true
        Task {
            do {
                try await store.authorizedRequest { token in
                    try await store.api.deleteAccount(accessToken: token)
                }
                store.logout(message: SafeEatL10n.text(L10nKey.Profile.DeleteAccount.success))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
