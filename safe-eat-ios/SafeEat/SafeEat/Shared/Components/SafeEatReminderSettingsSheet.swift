import SwiftUI

struct SafeEatReminderSettingsSheet: View {
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var draftEnabled = false
    @State private var draftStartDayOffset = ReminderStartDay.today.rawValue
    @State private var draftTimeMinutes = 20 * 60 + 30
    @State private var isSaving = false

    private let timeOptions = AppSettingsStore.reminderTimeOptions

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Reminder.sheetTitle),
            subtitle: SafeEatL10n.text(L10nKey.Reminder.sheetSubtitle)
        ) {
            toggleCard
            scheduleCard

            if let message = settings.notificationMessage, !message.isEmpty {
                ProfileSurfaceCard {
                    Text(message)
                        .font(SafeEatFont.textStyle(.footnote))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }

            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Reminder.saveAction),
                isLoading: isSaving
            ) {
                Task {
                    await saveSettings()
                }
            }
        }
        .task {
            settings.notificationMessage = nil
            await settings.refreshNotificationStatus()
            draftEnabled = settings.reminderEnabled
            draftStartDayOffset = settings.reminderStartDayOffset
            draftTimeMinutes = settings.reminderTimeMinutes
        }
    }

    private var toggleCard: some View {
        ProfileSurfaceCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(SafeEatTheme.primary.opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: draftEnabled ? "bell.fill" : "bell")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(SafeEatL10n.text(L10nKey.Reminder.toggleLabel))
                        .font(SafeEatFont.textStyle(.headline))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Text(draftEnabled ? selectedSummary : settings.reminderSummary)
                        .font(SafeEatFont.textStyle(.footnote))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $draftEnabled)
                    .tint(SafeEatTheme.primary)
            }
        }
    }

    private var scheduleCard: some View {
        ProfileSurfaceCard {
            ProfileFieldBlock(
                label: SafeEatL10n.text(L10nKey.Reminder.timeLabel),
                hint: draftEnabled ? nil : SafeEatL10n.text(L10nKey.Reminder.off)
            ) {
                HStack(spacing: 0) {
                    Picker("", selection: $draftStartDayOffset) {
                        ForEach(ReminderStartDay.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("", selection: $draftTimeMinutes) {
                        ForEach(timeOptions, id: \.self) { minutes in
                            Text(timeText(minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 120)
                .disabled(!draftEnabled)
                .opacity(draftEnabled ? 1 : 0.42)
            }

            HStack {
                Spacer()
                Text(selectedSummary)
                    .font(SafeEatFont.custom(14, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SafeEatTheme.primarySoft)
                    )
            }
        }
    }

    private var selectedSummary: String {
        let dayTitle = ReminderStartDay(rawValue: draftStartDayOffset)?.title
            ?? SafeEatL10n.text(L10nKey.Reminder.optionToday)
        return SafeEatL10n.format(L10nKey.Reminder.summaryFormat, dayTitle, timeText(draftTimeMinutes))
    }

    private func timeText(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func saveSettings() async {
        isSaving = true
        defer { isSaving = false }

        let succeeded = await settings.saveReminderSettings(
            enabled: draftEnabled,
            startDayOffset: draftStartDayOffset,
            timeMinutes: draftTimeMinutes
        )

        if succeeded {
            dismiss()
        }
    }
}
