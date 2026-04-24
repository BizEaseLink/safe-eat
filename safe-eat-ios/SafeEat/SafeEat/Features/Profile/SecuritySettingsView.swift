import SwiftUI

struct SecuritySettingsView: View {
    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Security.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Security.subtitle)
        ) {
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
