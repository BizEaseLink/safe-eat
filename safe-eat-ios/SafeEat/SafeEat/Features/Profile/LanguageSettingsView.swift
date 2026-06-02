import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Profile.Language.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Language.subtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(SafeEatL10n.text(L10nKey.Profile.Language.sectionTitle))
                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    ForEach(AppLanguage.allCases) { language in
                        ProfileSelectionRow(
                            title: language.displayName,
                            isSelected: settings.language == language
                        ) {
                            settings.language = language
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}