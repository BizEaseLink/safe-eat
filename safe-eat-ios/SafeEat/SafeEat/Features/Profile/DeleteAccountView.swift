import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var showConfirmDialog = false
    @State private var errorMessage: String?
    @State private var agreedToDelete = false

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

            NavigationLink(value: ProfileRoute.cancellationGuide) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                    Text("查看《账号注销指引》了解注销流程与数据清理规则")
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                }
                .foregroundStyle(SafeEatTheme.primary)
                .padding(.top, 4)
            }
            .buttonStyle(.plain)

            // 注销确认勾选
            HStack(alignment: .top, spacing: 8) {
                Button {
                    agreedToDelete.toggle()
                } label: {
                    Image(systemName: agreedToDelete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(agreedToDelete ? SafeEatTheme.danger : SafeEatTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 1)

                Text("我已了解注销后果，确认注销账号")
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        agreedToDelete.toggle()
                    }
            }
            .padding(.top, 8)
        } footer: {
            Button(role: .destructive, action: { showConfirmDialog = true }) {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmButton))
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SafeEatTheme.danger.opacity(0.85), SafeEatTheme.danger],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(!agreedToDelete || isLoading)
            .opacity(agreedToDelete ? 1.0 : 0.45)
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
