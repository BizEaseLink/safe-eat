import SwiftUI
import UserNotifications

// MARK: - Meal Period Type

enum MealPeriod: String, CaseIterable, Identifiable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"

    var id: String { rawValue }

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
            Text(period.rawValue)
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
            metaText: "\(AdviceLevelMapper.compactTitle(item.adviceLevel)) · \(item.foodScore) 分",
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

            Text("暂无\(selectedPeriod.rawValue)记录")
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
    @Binding var isEnabled: Bool
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

// MARK: - Notification Settings Sheet

struct NotificationSettingsSheet: View {
    @Binding var isEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDayIndex = 0 // 0=今天, 1=明天
    @State private var selectedTimeIndex = 36 // default 09:00 (index in timeOptions)

    private let dayOptions = ["今天", "明天"]
    private let timeOptions: [String] = {
        var opts: [String] = []
        for h in 6..<23 {
            for m in stride(from: 0, through: 45, by: 15) {
                opts.append(String(format: "%02d:%02d", h, m))
            }
        }
        return opts
    }()

    var body: some View {
        VStack(spacing: 24) {
            header

            toggleSection

            dualWheelPicker

            confirmButton
        }
        .padding(24)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("饮食提醒")
                .font(SafeEatFont.custom(20, relativeTo: .title2, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text("每日定时推送今日食用表现总结")
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private var toggleSection: some View {
        HStack {
            Text("开启通知提醒")
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Spacer()

            Toggle("", isOn: $isEnabled)
                .tint(SafeEatTheme.primary)
        }
    }

    // MARK: Dual Wheel Picker (Day + Time)

    private var dualWheelPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("提醒时间")
                .font(SafeEatFont.textStyle(.caption))
                .foregroundStyle(SafeEatTheme.textSecondary)

            HStack(spacing: 0) {
                // Left wheel: 今天 / 明天
                Picker("日期", selection: $selectedDayIndex) {
                    ForEach(0..<dayOptions.count, id: \.self) { idx in
                        Text(dayOptions[idx]).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                // Right wheel: Time options
                Picker("时间", selection: $selectedTimeIndex) {
                    ForEach(0..<timeOptions.count, id: \.self) { idx in
                        Text(timeOptions[idx]).tag(idx)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 140)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1 : 0.45)

            // Selected value display
            HStack {
                Spacer()
                Text("\(dayOptions[selectedDayIndex]) \(timeOptions[selectedTimeIndex])")
                    .font(SafeEatFont.custom(14, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(SafeEatTheme.primarySoft)
                    )
            }
        }
    }

    private var confirmButton: some View {
        Button(action: {
            scheduleNotification()
            dismiss()
        }) {
            Text("保存设置")
                .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [SafeEatTheme.primary, SafeEatTheme.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: SafeEatTheme.primary.opacity(0.25), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func scheduleNotification() {
        guard isEnabled else { return }
        
        // 1. 先请求通知权限（你原来完全没写，这是核心！）
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted, error == nil else {
                print("用户拒绝通知权限 或 出错：\(error?.localizedDescription ?? "")")
                return
            }
            
            // 2. 有权限后才执行通知逻辑
            let timeStr = timeOptions[selectedTimeIndex]
            let parts = timeStr.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2 else { return }
            
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests() // 先清掉旧的，避免重复
            
            // 每日定时通知
            let content = UNMutableNotificationContent()
            content.title = "Safe-Eat 今日饮食总结"
            content.body = "点击查看今日食用表现详情"
            content.sound = .default
            
            var dateComponents = DateComponents()
            dateComponents.hour = parts[0]
            dateComponents.minute = parts[1]
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "safe-eat-daily-summary", content: content, trigger: trigger)
            center.add(request)
            
            // 测试通知（3秒后弹出）
            let testContent = UNMutableNotificationContent()
            testContent.title = "Safe-Eat 提醒已开启"
            testContent.body = "您将在每天 \(timeStr) 收到饮食总结通知"
            testContent.sound = .default
            
            let testTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let testRequest = UNNotificationRequest(identifier: "safe-eat-test", content: testContent, trigger: testTrigger)
            center.add(testRequest)
        }
    }
}
