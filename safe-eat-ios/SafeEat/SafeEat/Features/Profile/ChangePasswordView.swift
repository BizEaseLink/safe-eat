import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var isMismatch: Bool {
        newPassword.count >= 6 && confirmPassword.count >= 6 && newPassword != confirmPassword
    }

    private var isValid: Bool {
        oldPassword.count >= 6
        && newPassword.count >= 6
        && confirmPassword.count >= 6
        && newPassword == confirmPassword
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.ChangePassword.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.ChangePassword.subtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.ChangePassword.oldPassword)) {
                        SecureField(SafeEatL10n.text(L10nKey.Profile.ChangePassword.oldPasswordPlaceholder), text: $oldPassword)
                            .textContentType(.password)
                            .font(SafeEatFont.custom(16, relativeTo: .body))
                    }

                    Divider().overlay(SafeEatTheme.line)

                    ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.ChangePassword.newPassword)) {
                        SecureField(SafeEatL10n.text(L10nKey.Profile.ChangePassword.newPasswordPlaceholder), text: $newPassword)
                            .textContentType(.newPassword)
                            .font(SafeEatFont.custom(16, relativeTo: .body))
                    }

                    Divider().overlay(SafeEatTheme.line)

                    ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.ChangePassword.confirmPassword)) {
                        SecureField(SafeEatL10n.text(L10nKey.Profile.ChangePassword.confirmPasswordPlaceholder), text: $confirmPassword)
                            .textContentType(.newPassword)
                            .font(SafeEatFont.custom(16, relativeTo: .body))
                    }
                }
            }

            if isMismatch {
                Text(SafeEatL10n.text(L10nKey.Profile.ChangePassword.mismatchError))
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.danger)
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Profile.ChangePassword.title),
                isLoading: isLoading,
                isDisabled: !isValid
            ) {
                changePassword()
            }
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: .constant(errorMessage != nil)) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(SafeEatL10n.text(L10nKey.Profile.ChangePassword.success), isPresented: $showSuccess) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) { dismiss() }
        }
    }

    private func changePassword() {
        isLoading = true
        Task {
            do {
                let updated = try await store.authorizedRequest { token in
                    try await store.api.changePassword(
                        accessToken: token,
                        oldPassword: oldPassword,
                        newPassword: newPassword
                    )
                }
                store.profile = updated
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
