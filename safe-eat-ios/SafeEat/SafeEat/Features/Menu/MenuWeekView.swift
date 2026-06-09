import SwiftUI

// MARK: - Week Day Model

struct WeekDayItem: Identifiable {
    let id = UUID()
    let date: Date
    let weekdaySymbol: String
    let dayNumber: String
    let isToday: Bool
    let isSelected: Bool
    let isFuture: Bool
}

// MARK: - Week Date Picker

struct WeekDatePicker: View {
    @Binding var selectedDate: Date

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = AppSettingsStore.shared.displayLocale
        return calendar
    }
    private var minDate: Date {
        var comps = DateComponents(year: 2020, month: 1, day: 1)
        return calendar.date(from: comps) ?? Date()
    }

    private var maxDate: Date {
        let year = calendar.component(.year, from: Date())
        var comps = DateComponents(year: year, month: 12, day: 31)
        return calendar.date(from: comps) ?? Date()
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
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                isFuture: calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
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
                                guard !day.isFuture else { return }
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
                if calendar.compare(newDate, to: minDate, toGranularity: .day) == .orderedAscending {
                    selectedDate = minDate
                } else if calendar.compare(newDate, to: maxDate, toGranularity: .day) == .orderedDescending {
                    selectedDate = maxDate
                } else {
                    selectedDate = newDate
                }
            }
        }
    }

    private func dayCell(for item: WeekDayItem, cellWidth: CGFloat) -> some View {
        VStack(spacing: 6) {
            Text(item.weekdaySymbol)
                .font(SafeEatFont.custom(13, relativeTo: .caption2))
                .foregroundStyle(
                    item.isFuture ? SafeEatTheme.textSecondary.opacity(0.4)
                    : item.isSelected ? SafeEatTheme.primary
                    : SafeEatTheme.textSecondary
                )

            ZStack {
                if item.isSelected && !item.isFuture {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(item.isToday ? SafeEatTheme.primary : SafeEatTheme.primarySoft)
                        .animation(.easeInOut(duration: 0.2), value: item.isSelected)
                }

                VStack(spacing: 2) {
                    Text(item.dayNumber)
                        .font(
                            item.isSelected && !item.isFuture
                                ? SafeEatFont.custom(20, relativeTo: .body, weight: .bold)
                                : SafeEatFont.custom(16, relativeTo: .body, weight: .bold)
                        )
                        .foregroundStyle(
                            item.isFuture ? SafeEatTheme.textSecondary.opacity(0.4)
                            : item.isSelected ? (item.isToday ? .white : SafeEatTheme.primary)
                            : SafeEatTheme.textPrimary
                        )
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
    @Environment(\.tabNavigationState) private var tabNavState

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

                if store.session == nil {
                    // 未登录时显示空内容模板
                    EmptyStateView(
                        icon: "fork.knife",
                        title: SafeEatL10n.text(L10nKey.Menu.notLoggedInTitle),
                        message: SafeEatL10n.text(L10nKey.Menu.notLoggedInMessage),
                        actionTitle: SafeEatL10n.text(L10nKey.Auth.goLogin),
                        action: { store.goToLogin() }
                    )
                } else {
                    overviewCard

                    WeekDatePicker(selectedDate: $selectedDate)

                    DailyPerformanceCard(items: todayItems, date: selectedDate) {
                        guard store.session != nil else {
                            store.requireLogin()
                            return
                        }
                        dayRoute = HistoryDayRoute(date: selectedDate)
                    }

                    MealPeriodSection(
                        items: todayItems,
                        selectedDate: selectedDate,
                        onDayTapped: { date in
                            guard store.session != nil else {
                                store.requireLogin()
                                return
                            }
                            dayRoute = HistoryDayRoute(date: date)
                        }
                    )

                    WeeklySummaryCard(
                        items: weekItems,
                        weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date(),
                        onTapped: { monday in
                            guard store.session != nil else {
                                store.requireLogin()
                                return
                            }
                            weekRoute = HistoryWeekRoute(referenceDate: monday)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(homeBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showNotificationSheet) {
            SafeEatReminderSettingsSheet()
        }
        .navigationDestination(item: $dayRoute) { route in
            HistoryDayView(date: route.date)
        }
        .navigationDestination(item: $weekRoute) { route in
            HistoryWeekView(referenceDate: route.referenceDate)
        }
        .onChange(of: dayRoute) { _, newValue in
            updateNavRootState()
        }
        .onChange(of: weekRoute) { _, _ in
            updateNavRootState()
        }
        .task {
            await settings.refreshNotificationStatus()
        }
        .onChange(of: store.pendingNotificationDate) { date in
            if let date {
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedDate = date
                }
                store.pendingNotificationDate = nil
            }
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

            // 今日占比精简进度条（只显示条，不显示图例）
            AdviceRatioBar(stats: .from(items: todayItems), showLabels: false, barHeight: 8)
        }
        .padding(20)
        .background(heroCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(heroCardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Navigation State

    private func updateNavRootState() {
        tabNavState.isHistoryAtRoot = dayRoute == nil && weekRoute == nil
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            SafeEatPageHeader(title: SafeEatL10n.text(L10nKey.Menu.title), subtitle: headerSubtitle)

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
