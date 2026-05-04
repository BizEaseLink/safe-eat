import SwiftUI

struct LanguageSettingsView: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Profile.Language.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Language.subtitle)
        ) {
            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.Language.sectionTitle)) {
                ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element.id) { index, language in
                    Button {
                        settings.language = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(language.displayName)
                                .font(SafeEatFont.textStyle(.body))
                                .foregroundStyle(SafeEatTheme.textPrimary)
                            Spacer()
                            if settings.language == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(SafeEatTheme.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 44)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < AppLanguage.allCases.count - 1 {
                        Divider().overlay(SafeEatTheme.line)
                    }
                }
            }
        }
    }
}
