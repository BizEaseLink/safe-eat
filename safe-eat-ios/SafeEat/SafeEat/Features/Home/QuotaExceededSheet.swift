import SwiftUI

struct QuotaExceededSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let onUpgrade: () -> Void

    private var freeDailyLimit: Int { 3 }

    private var todayScanCount: Int {
        let calendar = Calendar.current
        let todayItems = store.localHistory.filter { calendar.isDateInToday($0.createdAt) }
        return todayItems.count
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .padding(.top, 20)

            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTitle))
                .font(SafeEatFont.custom(20, relativeTo: .headline))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text(SafeEatL10n.text(L10nKey.Home.quotaExceededMessage))
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            quotaProgress

            VStack(spacing: 12) {
                Button {
                    dismiss()
                    onUpgrade()
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Home.quotaExceededUpgrade))
                        .font(SafeEatFont.custom(17, relativeTo: .headline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SafeEatTheme.primaryDeep)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Home.quotaExceededTomorrow))
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
        .background(colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12) : Color(.systemBackground))
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var quotaProgress: some View {
        VStack(spacing: 8) {
            HStack {
                Text(SafeEatL10n.text(L10nKey.User.tierFreeShort))
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                Spacer()
                Text("\(todayScanCount)/\(freeDailyLimit)")
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            ProgressView(value: Double(todayScanCount), total: Double(freeDailyLimit))
                .tint(todayScanCount >= freeDailyLimit ? SafeEatTheme.danger : SafeEatTheme.primary)
        }
        .padding(.horizontal, 40)
    }
}