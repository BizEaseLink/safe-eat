import SwiftUI

// MARK: - Advice Stats Helper

struct AdviceStats: Equatable {
    let recommended: Int
    let moderate: Int
    let caution: Int
    let avoid: Int
    let evaluate: Int

    var total: Int { recommended + moderate + caution + avoid + evaluate }

    static func from(items: [LocalHistoryItem]) -> AdviceStats {
        var r = 0, m = 0, c = 0, a = 0, e = 0
        for item in items {
            switch item.adviceLevel.lowercased() {
            case "recommended": r += 1
            case "moderate": m += 1
            case "caution": c += 1
            case "avoid", "non_food": a += 1
            default: e += 1
            }
        }
        return AdviceStats(recommended: r, moderate: m, caution: c, avoid: a, evaluate: e)
    }
}

// MARK: - Advice Ratio Bar (Reusable)

struct AdviceRatioBar: View {
    let stats: AdviceStats
    var showLabels = true
    var barHeight: CGFloat = 10

    @Environment(\.colorScheme) private var colorScheme

    private var displayTotal: Int { max(stats.total, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 单条连续进度条（clipShape 统一圆角，避免多段拼接漏背景色）
            GeometryReader { geo in
                let totalW = geo.size.width

                ZStack(alignment: .leading) {
                    // 背景 track（无数据时可见）
                    RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous)
                        .fill(trackColor)

                    // 各段从左到右
                    HStack(spacing: 0) {
                        barSegment(stats.recommended, totalW, SafeEatTheme.success)
                        barSegment(stats.moderate, totalW, SafeEatTheme.primary)
                        barSegment(stats.caution, totalW, SafeEatTheme.warning)
                        barSegment(stats.avoid, totalW, SafeEatTheme.danger)
                        barSegment(stats.evaluate, totalW, SafeEatTheme.textSecondary)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: barHeight / 2, style: .continuous))
                }
            }
            .frame(height: barHeight)

            // 图例标签（compact 版）
            if showLabels {
                legendRow
            }
        }
    }

    // track 背景色（无数据时可见）
    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    @ViewBuilder
    private func barSegment(_ count: Int, _ totalW: CGFloat, _ color: Color) -> some View {
        if count > 0 {
            Rectangle().fill(color).frame(width: segmentWidth(for: count, totalWidth: totalW))
        }
    }

    private var legendRow: some View {
        HStack(spacing: 0) {
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.compactRecommended),
                count: stats.recommended,
                color: SafeEatTheme.success
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.compactModerate),
                count: stats.moderate,
                color: SafeEatTheme.primary
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.compactCaution),
                count: stats.caution,
                color: SafeEatTheme.warning
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.compactAvoid),
                count: stats.avoid,
                color: SafeEatTheme.danger
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.compactEvaluate),
                count: stats.evaluate,
                color: SafeEatTheme.textSecondary
            )
        }
    }

    private func legendItem(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(label)
                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(count)")
                .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .bold))
                .foregroundStyle(color)
        }
    }

    private func segmentWidth(for count: Int, totalWidth: CGFloat) -> CGFloat {
        guard stats.total > 0 else { return 0 }
        return totalWidth * CGFloat(count) / CGFloat(displayTotal)
    }
}

// MARK: - Daily Performance Card

struct DailyPerformanceCard: View {
    let items: [LocalHistoryItem]
    let date: Date
    var onTapped: (() -> Void)? = nil

    private var stats: AdviceStats { .from(items: items) }

    /// 平均评分
    private var avgScore: String {
        guard !items.isEmpty else { return "--" }
        let total = items.reduce(0) { $0 + $1.foodScore }
        return String(format: "%.0f", Double(total) / Double(items.count))
    }

    /// 总热量（从 effectiveNutrition 读取）
    private var totalCalories: String {
        let calories = items.compactMap { item -> Double? in
            item.cachedRecognition?.effectiveNutrition?.nutrients?.calories.value
        }.reduce(0, +)
        guard calories > 0 else { return "--" }
        return "\(Int(calories))"
    }

    private var performanceLevel: String {
        guard stats.total > 0 else { return SafeEatL10n.text(L10nKey.Menu.performanceNoRecord) }
        let ratio = Double(stats.recommended + stats.moderate) / Double(stats.total)
        if ratio >= 0.7 { return SafeEatL10n.text(L10nKey.Menu.performanceExcellent) }
        if ratio >= 0.4 { return SafeEatL10n.text(L10nKey.Menu.performanceMedium) }
        if stats.avoid > stats.recommended { return SafeEatL10n.text(L10nKey.Menu.performanceNeedsImprove) }
        return SafeEatL10n.text(L10nKey.Menu.performanceMedium)
    }

    private var statusColor: Color {
        guard stats.total > 0 else { return SafeEatTheme.textSecondary }
        let ratio = Double(stats.recommended + stats.moderate) / Double(stats.total)
        if ratio >= 0.7 { return SafeEatTheme.success }
        if ratio >= 0.4 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 标题行
            HStack(spacing: 10) {
                Text(SafeEatL10n.text(L10nKey.Menu.dailyHealthOverview))
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Spacer()

                if let onTapped {
                    Button(action: onTapped) {
                        HStack(spacing: 4) {
                            Text(SafeEatL10n.text(L10nKey.Menu.dailyScanLog))
                                .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(SafeEatTheme.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(SafeEatTheme.primarySoft.opacity(0.82))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // 2. 核心指标行（扫描次数 + 平均评分 + 总热量）
            HStack(spacing: 8) {
                metricChip(
                    title: SafeEatL10n.text(L10nKey.Menu.dailyScanCount),
                    value: "\(items.count)",
                    icon: "barcode.viewfinder",
                    iconColor: SafeEatTheme.primary
                )
                .frame(maxWidth: .infinity)
                metricChip(
                    title: SafeEatL10n.text(L10nKey.Menu.dailyAvgScore),
                    value: avgScore,
                    icon: "star.fill",
                    iconColor: SafeEatTheme.warning
                )
                .frame(maxWidth: .infinity)
                metricChip(
                    title: SafeEatL10n.text(L10nKey.Menu.dailyTotalCalories),
                    value: totalCalories,
                    icon: "flame.fill",
                    iconColor: SafeEatTheme.danger
                )
                .frame(maxWidth: .infinity)
            }

            // 3. 五段进度条 + 图例
            AdviceRatioBar(stats: stats)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroCardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(heroCardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Metric Chip

    private func metricChip(title: String, value: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SafeEatFont.custom(11, relativeTo: .caption2))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                Text(value)
                    .font(SafeEatFont.custom(16, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.03))
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

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let items: [LocalHistoryItem]
    let weekStartDate: Date
    let onTapped: (Date) -> Void

    /// 静态 DateFormatter 实例，避免每次计算属性调用都创建新实例
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private var stats: AdviceStats { .from(items: items) }

    /// 本周 items（只取本周范围内的）
    private var weekItems: [LocalHistoryItem] {
        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStartDate) else { return items }
        return items.filter { $0.createdAt >= weekStartDate && $0.createdAt < weekEnd }
    }

    /// 趋势描述
    private var trendDescription: String {
        guard stats.total > 0 else { return SafeEatL10n.text(L10nKey.Menu.weeklyTrendGood) }
        let ratio = Double(stats.recommended + stats.moderate) / Double(stats.total)
        if ratio >= 0.7 { return SafeEatL10n.text(L10nKey.Menu.weeklyTrendGood) }
        if ratio >= 0.4 { return SafeEatL10n.text(L10nKey.Menu.weeklyTrendModerate) }
        return SafeEatL10n.text(L10nKey.Menu.weeklyTrendPoor)
    }

    /// 连续达标天数
    private var consecutiveDays: Int {
        let cal = Calendar.current
        // 按天分组
        let grouped = Dictionary(grouping: weekItems) { item in
            cal.startOfDay(for: item.createdAt)
        }
        var streak = 0
        for offset in (0..<7).reversed() {
            guard let date = cal.date(byAdding: .day, value: offset, to: weekStartDate) else { continue }
            let dayStart = cal.startOfDay(for: date)
            if let dayItems = grouped[dayStart], !dayItems.isEmpty {
                // 达标条件：推荐+适量 > 谨慎+避免
                let dayStats = AdviceStats.from(items: dayItems)
                if dayStats.recommended + dayStats.moderate >= dayStats.caution + dayStats.avoid {
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        return streak
    }

    /// 周平均分
    private var weekAvgScore: String {
        guard !weekItems.isEmpty else { return "--" }
        let total = weekItems.reduce(0) { $0 + $1.foodScore }
        return String(format: "%.0f", Double(total) / Double(weekItems.count))
    }

    /// 按天分组的识别数量
    private var dailyCounts: [(day: String, count: Int)] {
        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStartDate) else { return [] }
        let weekRangeItems = items.filter { $0.createdAt >= weekStartDate && $0.createdAt < weekEnd }

        let grouped = Dictionary(grouping: weekRangeItems) { item in
            cal.component(.day, from: item.createdAt)
        }

        return (0..<7).compactMap { offset -> (String, Int)? in
            guard let date = cal.date(byAdding: .day, value: offset, to: weekStartDate) else { return nil }
            let day = cal.component(.day, from: date)
            Self.dayFormatter.locale = AppSettingsStore.shared.displayLocale
            Self.dayFormatter.dateFormat = AppSettingsStore.shared.language == .en ? "E" : "EEE"
            let symbol = Self.dayFormatter.string(from: date)
            let count = grouped[day]?.count ?? 0
            return (symbol, count)
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. 标题行 + 连续达标标签
            HStack {
                Text(SafeEatL10n.text(L10nKey.Menu.weeklyOverview))
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                if consecutiveDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                        Text(SafeEatL10n.format(L10nKey.Menu.weeklyConsecutiveDaysFormat, consecutiveDays))
                    }
                    .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(SafeEatTheme.primarySoft))
                }
            }

            // 2. 趋势描述
            Text(trendDescription)
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)

            // 3. 本周使用统计行
            HStack {
                Text(SafeEatL10n.text(L10nKey.Menu.weeklyUsageStats))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                Spacer()
                Text(SafeEatL10n.format(L10nKey.Menu.weeklyScanCountFormat, weekItems.count))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            // 4. 进度条 + 图例
            AdviceRatioBar(stats: stats)

            // 5. 柱状图（无数据时隐藏）
            if maxCount > 0 {
                WeeklyBarChart(dailyCounts: dailyCounts)
            }

            // 6. 周平均分 + 查看详情
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(SafeEatL10n.text(L10nKey.Menu.weeklyAvgScore))
                        .font(SafeEatFont.custom(12, relativeTo: .caption2))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Text(weekAvgScore)
                        .font(SafeEatFont.custom(34, relativeTo: .title, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                }
                Spacer()
                Button { onTapped(weekStartDate) } label: {
                    HStack(spacing: 4) {
                        Text(SafeEatL10n.text(L10nKey.Menu.weeklyViewDetail))
                        Image(systemName: "arrow.forward")
                    }
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(SafeEatTheme.primarySoft.opacity(0.82)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroCardBackground)
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(heroCardStroke, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    /// 柱状图最大数量（用于条件渲染）
    private var maxCount: Int {
        dailyCounts.map(\.count).max() ?? 0
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

// MARK: - Weekly Bar Chart

struct WeeklyBarChart: View {
    let dailyCounts: [(day: String, count: Int)]

    @Environment(\.colorScheme) private var colorScheme

    private var maxCount: Int {
        dailyCounts.map(\.count).max() ?? 0
    }

    private var barMaxHeight: CGFloat { 80 }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(dailyCounts.enumerated()), id: \.offset) { index, entry in
                VStack(spacing: 4) {
                    // 柱子
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(barColor(for: entry.count))
                        .frame(height: barHeight(for: entry.count))

                    // 星期标签
                    Text(entry.day)
                        .font(SafeEatFont.custom(10, relativeTo: .caption2))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: barMaxHeight + 20)
    }

    private func barHeight(for count: Int) -> CGFloat {
        guard maxCount > 0 else { return 0 }  // 全0时所有柱子0高度
        guard count > 0 else { return 0 }       // 0数据就是0高度
        return max(CGFloat(count) / CGFloat(maxCount) * barMaxHeight, 4)  // 有数据最低4pt
    }

    private func barColor(for count: Int) -> Color {
        guard count > 0 else {
            return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
        }
        return SafeEatTheme.primary.opacity(0.75)
    }
}
