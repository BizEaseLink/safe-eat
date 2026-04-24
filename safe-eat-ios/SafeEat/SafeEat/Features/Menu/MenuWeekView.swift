import SwiftUI

// MARK: - Week Day Model

struct WeekDayItem: Identifiable {
    let id = UUID()
    let date: Date
    let weekdaySymbol: String
    let dayNumber: String
    let isToday: Bool
    let isSelected: Bool
}

// MARK: - Week Date Picker

struct WeekDatePicker: View {
    @Binding var selectedDate: Date

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = AppSettingsStore.shared.displayLocale
        return calendar
    }
    private var weekDays: [WeekDayItem] {
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let symbols = calendar.shortStandaloneWeekdaySymbols
        // Reorder to Sunday-first: [日, 一, 二, 三, 四, 五, 六]
        let reorderedSymbols = [symbols[0]] + Array(symbols.dropFirst())

        return (0..<7).compactMap { index -> WeekDayItem? in
            guard let date = calendar.date(byAdding: .day, value: index, to: startOfWeek) else { return nil }
            let weekdayIndex = calendar.component(.weekday, from: date)
            let symbolIndex = (weekdayIndex + 6) % 7
            return WeekDayItem(
                date: date,
                weekdaySymbol: reorderedSymbols[symbolIndex],
                dayNumber: calendar.isDateInToday(date)
                    ? SafeEatL10n.text(L10nKey.Menu.todayMarker)
                    : "\(calendar.component(.day, from: date))",
                isToday: calendar.isDateInToday(date),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
            )
        }
    }
    
    
    
    private var weekRangeString: String {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = AppSettingsStore.shared.language == .en ? "MMM d" : "M月d日"
        let startStr = formatter.string(from: interval.start)
        let endStr = formatter.string(from: interval.end.addingTimeInterval(-86400))
        return "\(startStr) - \(endStr)"
    }

    /// Whether selected date is NOT today — show "back to today" button
    private var isNotCurrentWeek: Bool {
        guard
            let selectedWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start,
            let currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start
        else {
            return !calendar.isDateInToday(selectedDate)
        }

        return !calendar.isDate(selectedWeek, inSameDayAs: currentWeek)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Week range title row with optional "back to today"
            HStack(spacing: 12) {
                Text(weekRangeString)
//                    .font(SafeEatFont.textStyle(.headline))
                    .font(SafeEatFont.custom(20, relativeTo: .title))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                if isNotCurrentWeek {
                    Button(action: backToToday) {
                        Text(SafeEatL10n.text(L10nKey.Menu.backToToday))
                            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear.frame(width: 1)
                }
            }

            // 7 day cells equally filling the horizontal width
            GeometryReader { geo in
                let cellWidth = geo.size.width / 7
                HStack(spacing: 0) {
                    ForEach(weekDays) { day in
                        dayCell(for: day, cellWidth: cellWidth)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.22)) {
                                    selectedDate = day.date
                                }
                            }
                    }
                }
                // Gesture: swipe to navigate weeks
                .gesture(DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width < -threshold {
                            navigateWeek(1)
                        } else if value.translation.width > threshold {
                            navigateWeek(-1)
                        }
                    }
                )
            }
            .frame(height: 72)
        }
    }

    private func backToToday() {
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedDate = Date()
        }
    }

    private func navigateWeek(_ direction: Int) {
        withAnimation(.easeInOut(duration: 0.22)) {
            if let newDate = calendar.date(byAdding: .weekOfYear, value: direction, to: selectedDate) {
                selectedDate = newDate
            }
        }
    }

    private func dayCell(for item: WeekDayItem, cellWidth: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(item.weekdaySymbol)
                .font(SafeEatFont.custom(13, relativeTo: .caption2))
                .foregroundStyle(item.isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary)

            ZStack {
                if item.isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(item.isToday ? SafeEatTheme.primary : SafeEatTheme.primarySoft)
                        // 让背景也一起动画，更统一
                        .animation(.easeInOut(duration: 0.2), value: item.isSelected)
                }

                VStack(spacing: 2) {
                    Text(item.dayNumber)
                        .font(
                            item.isSelected
                                ? SafeEatFont.custom(20, relativeTo: .body, weight: .bold)
                                : SafeEatFont.custom(16, relativeTo: .body, weight: .bold)
                        )
                        .foregroundStyle(item.isSelected ? (item.isToday ? .white : SafeEatTheme.primary) : SafeEatTheme.textPrimary)
                        .animation(.easeInOut(duration: 0.2), value: item.isSelected)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
            }
        }
        .frame(width: cellWidth)
    }
}

// MARK: - Menu Week View (Main Page)

struct MenuWeekView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDate = Date()
    @State private var showNotificationSheet = false

    @State private var dayRoute: HistoryDayRoute?
    @State private var weekRoute: HistoryWeekRoute?

    private var todayItems: [LocalHistoryItem] {
        store.localHistory.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
    }

    private var weekItems: [LocalHistoryItem] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return store.localHistory.filter { $0.createdAt >= interval.start && $0.createdAt < interval.end }
    }

    private var headerSubtitle: String {
        SafeEatL10n.format(L10nKey.Menu.headerSubtitleFormat, todayItems.count, weekItems.count)
    }

    // MARK: - Page Background (Light/Dark)
    
    private var homeBackground: some View {
        SafeEatMainGradientBackground()
    }


    private var pageBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.12, green: 0.12, blue: 0.12) // ~#1E1E1E
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 0.95), // ~#F5F7F3
                        Color(red: 0.94, green: 0.95, blue: 0.93),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                topBar

                overviewCard

                WeekDatePicker(selectedDate: $selectedDate)

                DailyPerformanceCard(items: todayItems, date: selectedDate) {
                    dayRoute = HistoryDayRoute(date: selectedDate)
                }

                MealPeriodSection(
                    items: todayItems,
                    selectedDate: selectedDate,
                    onDayTapped: { date in
                        dayRoute = HistoryDayRoute(date: date)
                    }
                )

                WeeklySummaryCard(
                    items: weekItems,
                    weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date(),
                    onTapped: { monday in
                        weekRoute = HistoryWeekRoute(referenceDate: monday)
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(homeBackground.ignoresSafeArea())
        .sheet(isPresented: $showNotificationSheet) {
            SafeEatReminderSettingsSheet()
                .presentationDetents([.height(600)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.clear)
        }
        .navigationDestination(item: $dayRoute) { route in
            HistoryDayView(date: route.date)
        }
        .navigationDestination(item: $weekRoute) { route in
            HistoryWeekView(referenceDate: route.referenceDate)
        }
        .task {
            await settings.refreshNotificationStatus()
        }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedDate.menuHeroDateText)
                        .font(SafeEatFont.custom(30, relativeTo: .title, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Text(selectedDate.menuHeroWeekdayText)
                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.primary)

                    Text(
                        todayItems.isEmpty
                            ? SafeEatL10n.text(L10nKey.Menu.heroEmptySummary)
                            : SafeEatL10n.format(L10nKey.Menu.heroFilledSummary, todayItems.count, weekItems.count)
                    )
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 10) {
                    heroMetricChip(title: SafeEatL10n.text(L10nKey.Menu.metricToday), value: "\(todayItems.count)")
                    heroMetricChip(title: SafeEatL10n.text(L10nKey.Menu.metricWeek), value: "\(weekItems.count)")
                }
            }

            HStack(spacing: 12) {
                quickAccessButton(
                    title: SafeEatL10n.text(L10nKey.Menu.dayRecordTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Menu.dayRecordSubtitle),
                    systemImage: "calendar"
                ) {
                    dayRoute = HistoryDayRoute(date: selectedDate)
                }

                quickAccessButton(
                    title: SafeEatL10n.text(L10nKey.Menu.weekRecordTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Menu.weekRecordSubtitle),
                    systemImage: "square.stack.3d.up"
                ) {
                    let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
                    weekRoute = HistoryWeekRoute(referenceDate: weekStart)
                }
            }
        }
        .padding(20)
        .background(heroCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(heroCardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            SafeEatPageHeader(title: SafeEatL10n.text(L10nKey.Menu.title), subtitle: headerSubtitle)
//            Text("菜单")
//                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
//                .foregroundStyle(SafeEatTheme.textPrimary)

            Spacer()

            NotificationBellButton(isEnabled: settings.reminderEnabled) {
                showNotificationSheet = true
            }
        }
    }

    private func heroMetricChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(value)
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
        }
        .frame(minWidth: 68, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.62))
        )
    }

    private func quickAccessButton(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.32 : 0.92))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(SafeEatFont.custom(15, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Text(subtitle)
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.54))
            )
        }
        .buttonStyle(.plain)
    }

    private var heroCardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03),
                        ]
                        : [
                            Color.white.opacity(0.92),
                            Color(red: 0.95, green: 0.98, blue: 0.95).opacity(0.92),
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var heroCardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }
}

// MARK: - Navigation Route

private struct HistoryDayRoute: Identifiable, Hashable {
    let id = UUID()
    let date: Date
}

private struct HistoryWeekRoute: Identifiable, Hashable {
    let id = UUID()
    let referenceDate: Date
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MenuWeekView()
            .environmentObject(AppStore())
    }
}

private extension Date {
    var menuHeroDateText: String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = AppSettingsStore.shared.language == .en ? "MMM dd" : "M月d日"
        return formatter.string(from: self)
    }

    var menuHeroWeekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
