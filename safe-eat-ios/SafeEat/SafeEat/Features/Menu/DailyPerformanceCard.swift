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
            // 5 段进度条（无背景 track）
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if stats.recommended > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.success)
                            .frame(width: segmentWidth(for: stats.recommended, totalWidth: geo.size.width))
                    }
                    if stats.moderate > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.primary)
                            .frame(width: segmentWidth(for: stats.moderate, totalWidth: geo.size.width))
                    }
                    if stats.caution > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.warning)
                            .frame(width: segmentWidth(for: stats.caution, totalWidth: geo.size.width))
                    }
                    if stats.avoid > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.danger)
                            .frame(width: segmentWidth(for: stats.avoid, totalWidth: geo.size.width))
                    }
                    if stats.evaluate > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.textSecondary)
                            .frame(width: segmentWidth(for: stats.evaluate, totalWidth: geo.size.width))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: barHeight)

            // 图例标签（compact 版）
            if showLabels {
                legendRow
            }
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

/// 圆角条形段，用于五段进度条的单段
private struct RoundedBarSegment: Shape {
    func path(in rect: CGRect) -> SwiftUI.Path {
        RoundedRectangle(cornerRadius: min(rect.height / 2, 5), style: .continuous)
            .path(in: rect)
    }
}

// MARK: - Daily Performance Card

struct DailyPerformanceCard: View {
    let items: [LocalHistoryItem]
    let date: Date
    var onTapped: (() -> Void)? = nil

    private var stats: AdviceStats { .from(items: items) }

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
            HStack(spacing: 10) {
                Text(SafeEatL10n.format(L10nKey.Menu.dailyTitleFormat, performanceLevel))
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Spacer()

                if let onTapped {
                    Button(action: onTapped) {
                        HStack(spacing: 4) {
                            Text(SafeEatL10n.text(L10nKey.Menu.dayRecordAction))
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

            // 五段进度条 + 图例
            AdviceRatioBar(stats: stats)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.10), radius: 22, y: 14)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let items: [LocalHistoryItem]
    let weekStartDate: Date
    let onTapped: (Date) -> Void

    private var stats: AdviceStats { .from(items: items) }

    /// 按天分组的识别数量
    private var dailyCounts: [(day: String, count: Int)] {
        let cal = Calendar.current
        guard let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStartDate) else { return [] }
        let weekItems = items.filter { $0.createdAt >= weekStartDate && $0.createdAt < weekEnd }

        let grouped = Dictionary(grouping: weekItems) { item in
            cal.component(.day, from: item.createdAt)
        }

        return (0..<7).compactMap { offset -> (String, Int)? in
            guard let date = cal.date(byAdding: .day, value: offset, to: weekStartDate) else { return nil }
            let day = cal.component(.day, from: date)
            let formatter = DateFormatter()
            formatter.locale = AppSettingsStore.shared.displayLocale
            formatter.dateFormat = AppSettingsStore.shared.language == .en ? "E" : "EEE"
            let symbol = formatter.string(from: date)
            let count = grouped[day]?.count ?? 0
            return (symbol, count)
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(SafeEatL10n.text(L10nKey.Menu.weeklyOverview))
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            // 每日柱状图
            WeeklyBarChart(dailyCounts: dailyCounts)

            // 五段进度条 + 图例
            AdviceRatioBar(stats: stats)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.10), radius: 22, y: 14)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped(weekStartDate)
        }
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
    }

    private var cardStroke: Color {
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

    private var barMaxHeight: CGFloat {
        guard maxCount > 0 else { return 20 }
        // 保持柱子饱满：少量时也不会太矮，大量时也不会太高
        return min(CGFloat(maxCount) * 14, 80)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
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
        guard maxCount > 0 else { return 4 }
        return max(CGFloat(count) / CGFloat(maxCount) * barMaxHeight, count > 0 ? 8 : 4)
    }

    private func barColor(for count: Int) -> Color {
        guard count > 0 else {
            return colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
        }
        return SafeEatTheme.primary.opacity(0.75)
    }
}
