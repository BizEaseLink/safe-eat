import SwiftUI

// MARK: - Daily Performance Card

struct DailyPerformanceCard: View {
    let items: [LocalHistoryItem]
    let date: Date
    var onTapped: (() -> Void)? = nil

    private var stats: (recommended: Int, caution: Int, avoid: Int) {
        var r = 0, c = 0, a = 0
        for item in items {
            switch item.adviceLevel.lowercased() {
            case "recommended": r += 1
            case "caution": c += 1
            case "avoid", "non_food": a += 1
            default: break
            }
        }
        return (r, c, a)
    }

    private var performanceLevel: String {
        let total = stats.recommended + stats.caution + stats.avoid
        guard total > 0 else { return SafeEatL10n.text(L10nKey.Menu.performanceNoRecord) }

        let ratio = Double(stats.recommended) / Double(total)
        if ratio >= 0.7 { return SafeEatL10n.text(L10nKey.Menu.performanceExcellent) }
        if ratio >= 0.4 { return SafeEatL10n.text(L10nKey.Menu.performanceMedium) }
        if stats.avoid > stats.recommended { return SafeEatL10n.text(L10nKey.Menu.performanceNeedsImprove) }
        return SafeEatL10n.text(L10nKey.Menu.performanceMedium)
    }

    private var statusColor: Color {
        let total = stats.recommended + stats.caution + stats.avoid
        guard total > 0 else { return SafeEatTheme.textSecondary }

        let ratio = Double(stats.recommended) / Double(total)
        if ratio >= 0.7 { return SafeEatTheme.success }
        if ratio >= 0.4 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

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

                Button(action: {}) {
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(SafeEatTheme.warning)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(SafeEatTheme.warning.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            summaryRow

            progressBar

            markerDots
        }
        .padding(18)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(SafeEatTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    // MARK: Summary Row

    private var summaryRow: some View {
        let total = stats.recommended + stats.caution + stats.avoid

        return Group {
            if total > 0 {
                HStack(spacing: 4) {
                    statBadge(SafeEatL10n.format(L10nKey.Menu.statRecommendedFormat, stats.recommended), color: .success)
                    statBadge(SafeEatL10n.format(L10nKey.Menu.statCautionFormat, stats.caution), color: .warning)
                    statBadge(SafeEatL10n.format(L10nKey.Menu.statAvoidFormat, stats.avoid), color: .danger)
                }
            } else {
                Text(SafeEatL10n.text(L10nKey.Menu.todayNoRecord))
                    .font(SafeEatFont.textStyle(.caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }

    private func statBadge(_ text: String, color: ColorType) -> some View {
        let fg: Color = switch color {
        case .success: SafeEatTheme.success; case .warning: SafeEatTheme.warning; case .danger: SafeEatTheme.danger
        }
        return Text(text)
            .font(SafeEatFont.textStyle(.body))
            .foregroundStyle(fg)
    }

    private enum ColorType { case success, warning, danger }

    // MARK: Progress Bar

    private var progressBar: some View {
        let total = stats.recommended + stats.caution + stats.avoid
        let displayTotal = max(total, 1)

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track (background rail) — always visible
                Capsule()
                    .fill(trackColor)

                // Colored segments on top
                if total > 0 {
                    HStack(spacing: 0) {
                        if stats.recommended > 0 {
                            Capsule()
                                .fill(SafeEatTheme.success)
                                .frame(width: geo.size.width * CGFloat(stats.recommended) / CGFloat(displayTotal))
                        }
                        if stats.caution > 0 {
                            Capsule()
                                .fill(SafeEatTheme.warning)
                                .frame(width: geo.size.width * CGFloat(stats.caution) / CGFloat(displayTotal))
                        }
                        if stats.avoid > 0 {
                            Capsule()
                                .fill(SafeEatTheme.danger)
                                .frame(width: geo.size.width * CGFloat(stats.avoid) / CGFloat(displayTotal))
                        }
                    }
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    @Environment(\.colorScheme) private var colorScheme

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    // MARK: Marker Dots (3 colors: success / warning / danger)

    private var markerDots: some View {
        let total = stats.recommended + stats.caution + stats.avoid
        let hasData = total > 0

        return HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(markerColor(at: index, hasData: hasData))
                    .frame(width: 8, height: 8)
            }
            Spacer(minLength: 0)
        }
    }

    private func markerColor(at index: Int, hasData: Bool) -> Color {
        let colors: [Color] = [
            SafeEatTheme.success,
            SafeEatTheme.warning,
            SafeEatTheme.danger,
        ]
        guard hasData else {
            return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
        }
        return colors[index]
    }

    // MARK: Background

    private var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.84)
            } else {
                Color.white.opacity(0.84)
            }
        }
    }
}

// MARK: - Weekly Summary Card

struct WeeklySummaryCard: View {
    let items: [LocalHistoryItem]
    let weekStartDate: Date
    let onTapped: (Date) -> Void

    private var stats: (recommended: Int, caution: Int, avoid: Int) {
        var r = 0, c = 0, a = 0
        for item in items {
            switch item.adviceLevel.lowercased() {
            case "recommended": r += 1
            case "caution": c += 1
            case "avoid", "non_food": a += 1
            default: break
            }
        }
        return (r, c, a)
    }

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

            summaryTags

            weekProgressBar

            weekMarkerDots
        }
        .padding(18)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(SafeEatTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .contentShape(Rectangle())
        .onTapGesture {
            onTapped(weekStartDate)
        }
    }

    private var summaryTags: some View {
        let total = stats.recommended + stats.caution + stats.avoid

        return VStack(alignment: .leading, spacing: 10) {
            if total > 0 {
                HStack(spacing: 10) {
                    weekStatTag(SafeEatL10n.format(L10nKey.Menu.weeklyStatRecommendedFormat, stats.recommended), color: .success)
                    weekStatTag(SafeEatL10n.format(L10nKey.Menu.weeklyStatCautionFormat, stats.caution), color: .warning)
                    weekStatTag(SafeEatL10n.format(L10nKey.Menu.weeklyStatAvoidFormat, stats.avoid), color: .danger)
                }
            } else {
                // Three empty-state placeholder tags
                HStack(spacing: 10) {
                    emptyWeekStatTag(SafeEatL10n.text(L10nKey.Menu.weeklyEmptyRecommendedFormat), color: .success)
                    emptyWeekStatTag(SafeEatL10n.text(L10nKey.Menu.weeklyEmptyCautionFormat), color: .warning)
                    emptyWeekStatTag(SafeEatL10n.text(L10nKey.Menu.weeklyEmptyAvoidFormat), color: .danger)
                }

                Text(SafeEatL10n.text(L10nKey.Menu.weeklyEmpty))
                    .font(SafeEatFont.textStyle(.caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }

    private func weekStatTag(_ text: String, color: TagColor) -> some View {
        let (fg, bg): (Color, Color) = switch color {
        case .success: (SafeEatTheme.success, SafeEatTheme.success.opacity(0.12))
        case .warning: (SafeEatTheme.warning, SafeEatTheme.warning.opacity(0.12))
        case .danger: (SafeEatTheme.danger, SafeEatTheme.danger.opacity(0.12))
        }

        return Text(text)
            .font(SafeEatFont.textStyle(.body))
            .foregroundStyle(fg)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(bg)
            )
    }

    private func emptyWeekStatTag(_ text: String, color: TagColor) -> some View {
        let (fg, bg): (Color, Color) = switch color {
        case .success: (SafeEatTheme.success.opacity(0.4), SafeEatTheme.success.opacity(0.06))
        case .warning: (SafeEatTheme.warning.opacity(0.4), SafeEatTheme.warning.opacity(0.06))
        case .danger: (SafeEatTheme.danger.opacity(0.4), SafeEatTheme.danger.opacity(0.06))
        }

        return Text(text)
            .font(SafeEatFont.textStyle(.body))
            .foregroundStyle(fg)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(bg)
            )
    }

    private enum TagColor { case success, warning, danger }

    // MARK: Week Progress Bar (same style as DailyPerformanceCard)

    private var weekProgressBar: some View {
        let total = stats.recommended + stats.caution + stats.avoid
        let displayTotal = max(total, 1)

        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                if total > 0 {
                    HStack(spacing: 0) {
                        if stats.recommended > 0 {
                            Capsule()
                                .fill(SafeEatTheme.success)
                                .frame(width: geo.size.width * CGFloat(stats.recommended) / CGFloat(displayTotal))
                        }
                        if stats.caution > 0 {
                            Capsule()
                                .fill(SafeEatTheme.warning)
                                .frame(width: geo.size.width * CGFloat(stats.caution) / CGFloat(displayTotal))
                        }
                        if stats.avoid > 0 {
                            Capsule()
                                .fill(SafeEatTheme.danger)
                                .frame(width: geo.size.width * CGFloat(stats.avoid) / CGFloat(displayTotal))
                        }
                    }
                }
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    // MARK: Week Marker Dots

    private var weekMarkerDots: some View {
        let total = stats.recommended + stats.caution + stats.avoid
        let hasData = total > 0

        return HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(markerDotColor(at: index, hasData: hasData))
                    .frame(width: 8, height: 8)
            }
            Spacer(minLength: 0)
        }
    }

    private func markerDotColor(at index: Int, hasData: Bool) -> Color {
        let colors: [Color] = [
            SafeEatTheme.success,
            SafeEatTheme.warning,
            SafeEatTheme.danger,
        ]
        guard hasData else {
            return colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.08)
        }
        return colors[index]
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
}
