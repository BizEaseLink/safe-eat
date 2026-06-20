import SwiftUI

struct PreferenceSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTags: Set<String> = []
    @State private var fitnessGoal = ""
    @State private var isSaving = false

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.preferenceTitle),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Preference.subtitle)
        ) {
            ProfileSurfaceCard {
                ProfileFieldBlock(
                    label: SafeEatL10n.text(L10nKey.Profile.Preference.healthTags),
                    hint: SafeEatL10n.text(L10nKey.Profile.Preference.healthTagsHint)
                ) {
                    VStack(spacing: 10) {
                        ForEach(HealthTagMapper.allTags, id: \.self) { tag in
                            ProfileSelectionRow(
                                title: HealthTagMapper.title(tag),
                                isSelected: selectedTags.contains(tag)
                            ) {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        }
                    }
                }
            }

            ProfileSurfaceCard {
                ProfileFieldBlock(
                    label: SafeEatL10n.text(L10nKey.Profile.Preference.fitnessGoal),
                    hint: SafeEatL10n.text(L10nKey.Profile.Preference.fitnessGoalHint)
                ) {
                    VStack(spacing: 10) {
                        ForEach(FitnessGoalMapper.allGoals, id: \.self) { goal in
                            ProfileSelectionRow(
                                title: FitnessGoalMapper.title(goal),
                                isSelected: fitnessGoal == goal
                            ) {
                                fitnessGoal = fitnessGoal == goal ? "" : goal
                            }
                        }
                    }
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Common.save),
                isLoading: isSaving
            ) {
                Task {
                    await savePreferences()
                }
            }
        }
        .task {
            loadFromProfile()
        }
    }

    private func loadFromProfile() {
        guard let profile = store.profile else { return }
        selectedTags = Set(profile.healthTags ?? [])
        fitnessGoal = profile.fitnessGoal ?? ""
    }

    private func savePreferences() async {
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await store.updateUserProfile(
                UserProfileUpdatePayload(
                    displayName: nil,
                    gender: nil,
                    heightCm: nil,
                    weightKg: nil,
                    age: nil,
                    activityLevel: nil,
                    healthTags: Array(selectedTags).sorted(),
                    fitnessGoal: fitnessGoal.isEmpty ? nil : fitnessGoal,
                    avoidIngredients: nil,
                    dietaryPreferences: nil
                )
            )
            dismiss()
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }
}
