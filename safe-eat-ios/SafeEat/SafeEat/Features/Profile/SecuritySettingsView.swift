import SwiftUI

struct SecuritySettingsView: View {
    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Security.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Security.subtitle)
        ) {
            ProfileSurfaceCard {
                NavigationLink {
                    ChangePhoneView()
                } label: {
                    ProfileNavigationRow(
                        icon: "phone.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.Security.changePhone)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    ProfileNavigationRow(
                        icon: "lock.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.Security.changePassword)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    RestorePurchasesView()
                } label: {
                    ProfileNavigationRow(
                        icon: "arrow.clockwise.icloud.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.Security.restorePurchases)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    DeleteAccountView()
                } label: {
                    ProfileNavigationRow(
                        icon: "person.crop.circle.badge.xmark",
                        title: SafeEatL10n.text(L10nKey.Profile.Security.deleteAccount)
                    )
                }
                .buttonStyle(.plain)
            }

            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.Security.session))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Divider().overlay(SafeEatTheme.line)

                Text(SafeEatL10n.text(L10nKey.Profile.Security.sync))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Divider().overlay(SafeEatTheme.line)

                Text(SafeEatL10n.text(L10nKey.Profile.Security.cache))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }
        }
    }
}
