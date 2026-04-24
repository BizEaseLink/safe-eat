import SwiftUI

struct UpdateSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Update.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Update.subtitle)
        ) {
            ProfileSurfaceCard {
                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Profile.Update.versionLabel),
                    value: version
                )

                Divider().overlay(SafeEatTheme.line)

                Text(SafeEatL10n.text(L10nKey.Profile.Update.latest))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }
        }
    }
}
