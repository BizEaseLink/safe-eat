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

    private var calendar: Calendar { Calendar.current }
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
                dayNumber: calendar.isDateInToday(date) ? "今" : "\(calendar.component(.day, from: date))",
                isToday: calendar.isDateInToday(date),
                isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
            )
        }
    }

    private var weekRangeString: String {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let startStr = formatter.string(from: interval.start)
        let endStr = formatter.string(from: interval.end.addingTimeInterval(-86400))
        return "\(startStr) - \(endStr)"
    }

    /// Whether selected date is NOT today — show "back to today" button
    private var isNotCurrentWeek: Bool {
        !calendar.isDateInToday(selectedDate)
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
                        Text("[ 回到今天 ]")
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
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedDate = Date()
    @State private var showNotificationSheet = false
    @State private var notificationEnabled = false

    @State private var dayRoute: HistoryDayRoute?

    private var todayItems: [LocalHistoryItem] {
        store.localHistory.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
    }

    private var weekItems: [LocalHistoryItem] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return store.localHistory.filter { $0.createdAt >= interval.start && $0.createdAt < interval.end }
    }

    // MARK: - Page Background (Light/Dark)

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

                WeekDatePicker(selectedDate: $selectedDate)

                DailyPerformanceCard(items: todayItems, date: selectedDate)

                MealPeriodSection(
                    items: todayItems,
                    selectedDate: selectedDate,
                    onDayTapped: { date in
                        dayRoute = HistoryDayRoute(date: date, title: "日列表")
                    }
                )

                WeeklySummaryCard(
                    items: weekItems,
                    weekStartDate: Calendar.current.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? Date(),
                    onTapped: { monday in
                        dayRoute = HistoryDayRoute(date: monday, title: "本周详情")
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(pageBackground.ignoresSafeArea())
        .sheet(isPresented: $showNotificationSheet) {
            NotificationSettingsSheet(isEnabled: $notificationEnabled)
                .presentationDetents([.height(460)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(.systemBackground))
        }
        .navigationDestination(item: $dayRoute) { route in
            HistoryDayView(monthKey: route.monthKey, monthDate: route.monthDate)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            SafeEatPageHeader(title: "个人")
//            Text("菜单")
//                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
//                .foregroundStyle(SafeEatTheme.textPrimary)

            Spacer()

            NotificationBellButton(isEnabled: $notificationEnabled) {
                showNotificationSheet = true
            }
        }
    }
}

// MARK: - Navigation Route

private struct HistoryDayRoute: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let title: String

    var monthKey: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy 年 MM 月"
        return f.string(from: date)
    }

    var monthDate: Date { date }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MenuWeekView()
            .environmentObject(AppStore())
    }
}
