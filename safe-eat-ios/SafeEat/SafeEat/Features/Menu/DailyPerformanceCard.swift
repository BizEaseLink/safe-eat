import SwiftUI

// MARK: - Advice Stats Helper

struct AdviceStats: Equatable {
    let recommended: Int
    let caution: Int
    let avoid: Int

    var total: Int { recommended + caution + avoid }

    static func from(items: [LocalHistoryItem]) -> AdviceStats {
        var r = 0, c = 0, a = 0
        for item in items {
            switch item.adviceLevel.lowercased() {
            case "recommended": r += 1
            case "caution": c += 1
            case "avoid", "non_food": a += 1
            default: break
            }
        }
        return AdviceStats(recommended: r, caution: c, avoid: a)
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
        VStack(alignment: .leading, spacing: 8) {
            // 三段进度条
            GeometryReader { geo in
                HStack(spacing: 2) {
                    if stats.recommended > 0 {
                        RoundedBarSegment()
                            .fill(SafeEatTheme.success)
                            .frame(width: segmentWidth(for: stats.recommended, totalWidth: geo.size.width))
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
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: barHeight)
            .background(
                Capsule().fill(trackColor)
            )
            .clipShape(Capsule())

            // 图例标签
            if showLabels {
                legendRow
            }
        }
    }

    private var legendRow: some View {
        HStack(spacing: 0) {
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.titleRecommended),
                count: stats.recommended,
                color: SafeEatTheme.success
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.titleCaution),
                count: stats.caution,
                color: SafeEatTheme.warning
            )
            Spacer()
            legendItem(
                label: SafeEatL10n.text(L10nKey.Advice.titleAvoid),
                count: stats.avoid,
                color: SafeEatTheme.danger
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

            Text("\(count)")
                .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .bold))
                .foregroundStyle(color)
        }
    }

    private func segmentWidth(for count: Int, totalWidth: CGFloat) -> CGFloat {
        guard stats.total > 0 else { return 0 }
        return totalWidth * CGFloat(count) / CGFloat(displayTotal)
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }
}

/// 圆角条形段，用于三段进度条的单段
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
        let ratio = Double(stats.recommended) / Double(stats.total)
        if ratio >= 0.7 { return SafeEatL10n.text(L10nKey.Menu.performanceExcellent) }
        if ratio >= 0.4 { return SafeEatL10n.text(L10nKey.Menu.performanceMedium) }
        if stats.avoid > stats.recommended { return SafeEatL10n.text(L10nKey.Menu.performanceNeedsImprove) }
        return SafeEatL10n.text(L10nKey.Menu.performanceMedium)
    }

    private var statusColor: Color {
        guard stats.total > 0 else { return SafeEatTheme.textSecondary }
        let ratio = Double(stats.recommended) / Double(stats.total)
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

            // 三段进度条 + 图例
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

            // 三段进度条 + 图例
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
