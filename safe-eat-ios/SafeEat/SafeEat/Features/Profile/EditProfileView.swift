import SwiftUI

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var gender = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var isSaving = false
    @State private var bmiCache: String?

    private let genderOptions = ["", "male", "female"]

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.editTitle),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Edit.subtitle)
        ) {
            // 基本信息
            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.Edit.basicSection))
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.displayName)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.Edit.displayName),
                        text: $displayName
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.gender)) {
                    ProfileMenuField(
                        value: gender,
                        options: genderOptions.map { option in
                            (
                                id: option,
                                title: UserGenderMapper.title(option.isEmpty ? nil : option)
                            )
                        },
                        onSelect: { gender = $0 }
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.height)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.Edit.height),
                        text: $heightText,
                        keyboardType: .numberPad
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.weight)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.Edit.weight),
                        text: $weightText,
                        keyboardType: .decimalPad
                    )
                }
            }

            // BMI 结果
            ProfileSurfaceCard {
                ProfileFieldBlock(
                    label: SafeEatL10n.text(L10nKey.Profile.bmiLabel),
                    hint: SafeEatL10n.text(L10nKey.Profile.Edit.bmiHint)
                ) {
                    HStack {
                        Text(bmiCache ?? SafeEatL10n.text(L10nKey.Common.notSet))
                            .font(SafeEatFont.custom(28, relativeTo: .title2, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primaryDeep)

                        Spacer()

                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(SafeEatTheme.primary.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(profileControlFill(for: colorScheme))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
                    )
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Common.save),
                isLoading: isSaving
            ) {
                Task {
                    await saveProfile()
                }
            }
        }
        .task {
            loadFromProfile()
        }
        .onChange(of: heightText) { _ in updateBmiCache() }
        .onChange(of: weightText) { _ in updateBmiCache() }
    }

    private func updateBmiCache() {
        guard
            let height = Double(heightText),
            let weight = Double(weightText),
            height > 0
        else {
            bmiCache = SafeEatL10n.text(L10nKey.Common.notSet)
            return
        }
        let bmi = weight / pow(height / 100, 2)
        bmiCache = String(format: "%.1f", bmi)
    }

    private func loadFromProfile() {
        guard let profile = store.profile else { return }
        displayName = profile.displayName ?? ""
        gender = genderOptions.contains(profile.gender ?? "") ? (profile.gender ?? "") : ""
        if let heightCm = profile.heightCm {
            heightText = String(Int(heightCm.rounded()))
        }
        if let weightKg = profile.weightKg {
            let rounded = abs(weightKg.rounded() - weightKg) < 0.01
            weightText = rounded ? String(Int(weightKg.rounded())) : String(format: "%.1f", weightKg)
        }
        updateBmiCache()
    }

    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await store.updateUserProfile(
                UserProfileUpdatePayload(
                    displayName: trimmedOrNil(displayName),
                    gender: gender.isEmpty ? nil : gender,
                    heightCm: Double(heightText),
                    weightKg: Double(weightText),
                    healthTags: nil,
                    fitnessGoal: nil,
                    avoidIngredients: nil,
                    dietaryPreferences: nil
                )
            )

            dismiss()
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func trimmedOrNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
