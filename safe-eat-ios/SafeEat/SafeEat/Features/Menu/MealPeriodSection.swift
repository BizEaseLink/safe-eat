import SwiftUI

// MARK: - Meal Period Type

enum MealPeriod: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast:
            return SafeEatL10n.text(L10nKey.Menu.mealBreakfast)
        case .lunch:
            return SafeEatL10n.text(L10nKey.Menu.mealLunch)
        case .dinner:
            return SafeEatL10n.text(L10nKey.Menu.mealDinner)
        }
    }

    var hourRange: ClosedRange<Int> {
        switch self {
        case .breakfast: 5...11
        case .lunch: 12...17
        case .dinner: 18...23
        }
    }
}

// MARK: - Meal Period Section

struct MealPeriodSection: View {
    let items: [LocalHistoryItem]
    let selectedDate: Date
    let onDayTapped: (Date) -> Void

    @State private var selectedPeriod: MealPeriod = .breakfast

    private var filteredItems: [LocalHistoryItem] {
        items.filter { item in
            let hour = Calendar.current.component(.hour, from: item.createdAt)
            return selectedPeriod.hourRange.contains(hour)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            mealPeriodPicker

            // Food grid or empty state
            if !filteredItems.isEmpty {
                foodGrid(items: filteredItems)
            } else {
                emptyState
            }
        }
        .padding(18)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(SafeEatTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.84)
            } else {
                Color.white.opacity(0.84)
            }
        }
    }

    // MARK: Period Picker

    private var mealPeriodPicker: some View {
        HStack(spacing: 20) {
            ForEach(MealPeriod.allCases) { period in
                periodTab(for: period)
            }
        }
    }

    private func periodTab(for period: MealPeriod) -> some View {
        let isSelected = selectedPeriod == period

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPeriod = period
            }
        }) {
            Text(period.displayName)
                .font(SafeEatFont.custom(14, relativeTo: .body, weight: .bold))
                .foregroundStyle(isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                .padding(.bottom, 6)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle()
                            .fill(SafeEatTheme.primary)
                            .frame(height: 2.5)
                            .cornerRadius(1.5)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Food Grid

    private func foodGrid(items: [LocalHistoryItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(items.prefix(4)) { item in
                    foodCard(item: item)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func foodCard(item: LocalHistoryItem) -> some View {
        RecognitionStickerThumbnailView(
            image: LocalImageLoader.loadStickerImage(for: item),
            titleText: item.recognizedName,
            metaText: StickerTextFormatter.adviceScore(for: item),
            imageHeight: 104,
            labelMaxWidth: 124,
            style: .floating
        )
        .frame(width: 132, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture {
            onDayTapped(selectedDate)
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 28))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))

            Text(SafeEatL10n.format(L10nKey.Menu.mealEmptyFormat, selectedPeriod.displayName))
                .font(SafeEatFont.textStyle(.caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundStyle(SafeEatTheme.line.opacity(0.4))
        )
    }
}

// MARK: - Notification Bell Button

struct NotificationBellButton: View {
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: isEnabled ? "bell.fill" : "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isEnabled ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isEnabled ? SafeEatTheme.primarySoft : bellBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(bellBorder, lineWidth: 1)
                    )

                if isEnabled {
                    Circle()
                        .fill(SafeEatTheme.primary)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @Environment(\.colorScheme) private var colorScheme

    private var bellBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.76)
    }

    private var bellBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }
}
