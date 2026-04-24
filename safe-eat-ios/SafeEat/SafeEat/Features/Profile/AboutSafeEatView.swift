import SwiftUI

struct AboutSafeEatView: View {
    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.About.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.About.subtitle)
        ) {
            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.About.appName))
                    .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(SafeEatL10n.text(L10nKey.Profile.About.intro))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.About.sectionTitle))
                    .font(SafeEatFont.textStyle(.headline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(SafeEatL10n.text(L10nKey.Profile.About.sectionBody))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }
}
