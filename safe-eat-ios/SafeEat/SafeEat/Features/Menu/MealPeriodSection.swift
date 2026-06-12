import SwiftUI

// MARK: - Meal Period Type

enum MealPeriod: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case lateNight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast:
            return SafeEatL10n.text(L10nKey.Menu.mealBreakfast)
        case .lunch:
            return SafeEatL10n.text(L10nKey.Menu.mealLunch)
        case .dinner:
            return SafeEatL10n.text(L10nKey.Menu.mealDinner)
        case .lateNight:
            return SafeEatL10n.text(L10nKey.Menu.mealLateNight)
        }
    }

    func containsHour(_ hour: Int) -> Bool {
        switch self {
        case .breakfast:  return hour >= 5 && hour <= 11
        case .lunch:      return hour >= 12 && hour <= 17
        case .dinner:     return hour >= 18 && hour <= 21
        case .lateNight:  return hour >= 22 || hour <= 4
        }
    }
}

// MARK: - Meal Period Section

struct MealPeriodSection: View {
    let items: [LocalHistoryItem]
    let selectedDate: Date
    let onDayTapped: (Date) -> Void

    @State private var selectedPeriod: MealPeriod = .breakfast
    @State private var scrollOffset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private var filteredItems: [LocalHistoryItem] {
        items.filter { item in
            let hour = Calendar.current.component(.hour, from: item.createdAt)
            return selectedPeriod.containsHour(hour)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 饮食报告标题
            Text(SafeEatL10n.text(L10nKey.Menu.mealSectionTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            mealPeriodPicker

            // Food grid or empty state
            if !filteredItems.isEmpty {
                foodGrid(items: filteredItems)
            } else {
                emptyState
            }
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: Period Picker (Pill Style)

    private var mealPeriodPicker: some View {
        HStack(spacing: 0) {
            ForEach(MealPeriod.allCases) { period in
                periodTab(for: period)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(red: 0.94, green: 0.94, blue: 0.94))
        )
    }

    private func periodTab(for period: MealPeriod) -> some View {
        let isSelected = selectedPeriod == period

        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedPeriod = period
            }
        }) {
            Text(period.displayName)
                .font(SafeEatFont.custom(13, relativeTo: .subheadline, weight: isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white)
                                .shadow(color: Color.black.opacity(0.06), radius: 2, y: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Food Grid (Two-row + Horizontal Scroll + Direction Arrows)

    private let stickerWidth: CGFloat = 132
    private let stickerHeight: CGFloat = 140
    private let stickerSpacing: CGFloat = 24
    private let scrollThreshold: CGFloat = 5

    private func foodGrid(items: [LocalHistoryItem]) -> some View {
        let rows: [GridItem] = [
            GridItem(.fixed(stickerHeight), spacing: stickerSpacing),
            GridItem(.fixed(stickerHeight), spacing: stickerSpacing)
        ]

        return ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: rows, spacing: stickerSpacing) {
                    ForEach(items) { item in
                        foodCard(item: item)
                    }
                }
                .padding(.vertical, 6)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("foodGridScroll")).minX
                            )
                            .onAppear {
                                contentWidth = geo.size.width
                            }
                            .onChange(of: geo.size.width) { _, newWidth in
                                contentWidth = newWidth
                            }
                    }
                )
            }
            .scrollDisabled(contentWidth <= containerWidth)
            .coordinateSpace(name: "foodGridScroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear { containerWidth = geo.size.width }
                        .onChange(of: geo.size.width) { _, newWidth in
                            containerWidth = newWidth
                        }
                }
            )
    }

    private func foodCard(item: LocalHistoryItem) -> some View {
        AsyncRecognitionStickerView(
            item: item,
            imageHeight: 104,
            labelMaxWidth: 124,
            style: .floating
        )
        .frame(width: stickerWidth, alignment: .top)
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: isEnabled ? "bell.fill" : "bell")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isEnabled ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isEnabled ? bellActiveFill : bellBackground)
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

    private var bellActiveFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.18) : SafeEatTheme.primarySoft
    }

    private var bellBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.76)
    }

    private var bellBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }
}

// MARK: - Record Shortcut Button (Redesigned)

struct RecordShortcutButton: View {
    let title: String
    let icon: String
    let count: Int
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // 图标区域
                ZStack {
                    Circle()
                        .fill(iconCircleFill)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                }
                .padding(.top, 16)

                // 标题
                Text(title)
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .padding(.top, 10)

                // 计数标签
                Text("\(count)")
                    .font(SafeEatFont.custom(24, relativeTo: .title2, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconCircleFill: Color {
        colorScheme == .dark ? SafeEatTheme.primary.opacity(0.18) : SafeEatTheme.primarySoft
    }

    private var cardGradient: some ShapeStyle {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                : [Color.white.opacity(0.92), Color(red: 0.95, green: 0.98, blue: 0.95).opacity(0.92)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
