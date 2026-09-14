import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeMealSettingsSheetContainer(
            title: SafeMealL10n.text(L10nKey.Profile.Language.title),
            subtitle: SafeMealL10n.text(L10nKey.Profile.Language.subtitle),
            contentHeight: 142
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text(SafeMealL10n.text(L10nKey.Profile.Language.sectionTitle))
                        .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                        .foregroundStyle(SafeMealTheme.textPrimary)

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