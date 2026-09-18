import SwiftUI

private struct WeekDayGroup: Identifiable {
    let id: String
    let date: Date
    let items: [LocalHistoryItem]

    var subtitle: String {
        SafeMealHistoryL10n.recordCount(items.count)
    }
}

private struct HistoryWeekResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID
}

private struct WeekDayMarkerOffsetKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct HistoryWeekView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.resultDetailPresented) private var resultDetailPresented

    let referenceDate: Date

    @State private var resultRoute: HistoryWeekResultRoute?
    @State private var scrollOffset: CGFloat = 0
    @State private var currentVisibleDate: Date?
    @State private var showSearch = false

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
    private let scrollCoordinateSpace = "safemeal.history.week.scroll"

    private var weekInterval: DateInterval? {
        Calendar.current.dateInterval(of: .weekOfYear, for: referenceDate)
    }

    private var weekItems: [LocalHistoryItem] {
        guard let weekInterval else { return [] }

        return store.localHistory
            .filter { $0.createdAt >= weekInterval.start && $0.createdAt < weekInterval.end }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var dayGroups: [WeekDayGroup] {
        let grouped = Dictionary(grouping: weekItems) { item in
            item.createdAt.weekDayIdentity
        }

        return grouped
            .compactMap { _, items in
                let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
                guard let date = sortedItems.first?.createdAt else { return nil }
                return WeekDayGroup(id: date.weekDayIdentity, date: date, items: sortedItems)
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = SafeMealSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top)

            ZStack(alignment: .topLeading) {
                SafeMealDottedRecordBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        SafeMealGlobalScrollOffsetReader(
                            scrollOffset: $scrollOffset
                        )
                        .id(referenceDate.weekIdentity)

                        Color.clear
                            .frame(height: topInset + 36)

                        heroHeader

                        if dayGroups.isEmpty {
                            emptyState
                        } else {
                            ForEach(dayGroups) { group in
                                daySection(group)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                    .onPreferenceChange(WeekDayMarkerOffsetKey.self) { markers in
                        updateVisibleDate(with: markers, triggerY: topInset + 98)
                    }
                }
                .coordinateSpace(name: scrollCoordinateSpace)

                SafeMealTopBackChrome(
                    title: currentVisibleDate?.chromeDateText ?? weekRangeText,
                    scrollOffset: scrollOffset,
                    topInset: topInset,
                    minimumBackdropOpacity: 0,
                    emphasizesSafeAreaFill: true,
                    trailingContent: {
                        AnyView(
                            HistorySearchMagnifier {
                                showSearch = true
                            }
                        )
                    },
                    onBack: { dismiss() }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .ignoresSafeArea()
        .navigationDestination(item: $resultRoute) { route in
            ResultView(itemId: route.itemId)
        }
        .sheet(isPresented: $showSearch) {
            HistorySearchView(dateRange: weekInterval.flatMap { $0.start...($0.end.addingTimeInterval(-1)) }, scopeTitle: SafeMealL10n.text(L10nKey.History.searchScopeWeek)) { item in
                resultRoute = HistoryWeekResultRoute(id: item.id, itemId: item.id)
            }
        }
        .onAppear {
            currentVisibleDate = dayGroups.first?.date
            StickerImageCache.preload(for: Array(weekItems.prefix(12)))
        }
        .onChange(of: resultRoute) { _, newValue in
            resultDetailPresented.wrappedValue = newValue != nil
            #if DEBUG
            print("[DBG WeekView onChange resultRoute] newValue=\(newValue != nil) => resultDetailPresented=\(resultDetailPresented.wrappedValue)")
            #endif
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(SafeMealL10n.text(L10nKey.History.weekTitle))
                .font(SafeMealFont.custom(38, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)

            Text(weekRangeText)
                .font(SafeMealFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeMealTheme.textSecondary)

            Text(
                SafeMealL10n.format(
                    L10nKey.History.weekSummaryFormat,
                    SafeMealHistoryL10n.recordCount(weekItems.count),
                    SafeMealHistoryL10n.dayCount(dayGroups.count)
                )
            )
                .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)
        }
    }

    private func daySection(_ group: WeekDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(group.date.heroDateText)
                    .font(SafeMealFont.custom(30, relativeTo: .title, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)

                Text(
                    SafeMealL10n.format(
                        L10nKey.History.weekSectionSubtitleFormat,
                        group.date.weekdayText,
                        group.subtitle
                    )
                )
                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeMealTheme.textSecondary)
            }

            Color.clear
                .frame(height: 1)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: WeekDayMarkerOffsetKey.self,
                            value: [group.id: proxy.frame(in: .named(scrollCoordinateSpace)).minY]
                        )
                    }
                )

            LazyVGrid(columns: columns, spacing: 32) {
                ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                    stickerCard(for: item, index: index)
                }
            }
        }
        .onAppear {
            StickerImageCache.preload(for: Array(group.items.prefix(8)))
        }
    }

    private func stickerCard(for item: LocalHistoryItem, index: Int) -> some View {
        let config = HistoryStickerConfig.offsets[index % HistoryStickerConfig.offsets.count]

        return AsyncRecognitionStickerView(
            item: item,
            imageHeight: 126,
            labelMaxWidth: 200,
            rotationAngle: config.rotation,
            offsetY: config.offset,
            style: .floating
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                store.removeHistoryItem(item)
            } label: {
                Label(SafeMealL10n.text(L10nKey.Common.delete), systemImage: "trash")
            }
        }
        .onTapGesture {
            resultRoute = HistoryWeekResultRoute(id: item.id, itemId: item.id)
        }
    }

    private var emptyState: some View {
        SafeMealEmptyState(
            title: SafeMealL10n.text(L10nKey.History.weekEmptyTitle),
            message: SafeMealL10n.text(L10nKey.History.weekEmptyMessage),
            systemImage: "calendar.badge.exclamationmark"
        )
        .padding(.top, 28)
    }

    private var weekRangeText: String {
        guard let weekInterval else { return "" }

        return SafeMealHistoryL10n.weekRange(
            start: weekInterval.start,
            end: weekInterval.end.addingTimeInterval(-86400)
        )
    }

    private func updateVisibleDate(with markers: [String: CGFloat], triggerY: CGFloat) {
        guard !markers.isEmpty else { return }

        let activeEntry = markers
            .filter { $0.value <= triggerY }
            .max(by: { $0.value < $1.value })
            ?? markers.min(by: { $0.value < $1.value })

        guard
            let activeId = activeEntry?.key,
            let matchedGroup = dayGroups.first(where: { $0.id == activeId })
        else {
            return
        }

        if currentVisibleDate?.weekDayIdentity != matchedGroup.date.weekDayIdentity {
            currentVisibleDate = matchedGroup.date
        }
    }
}

private extension Date {
    var weekIdentity: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-'W'ww"
        return formatter.string(from: self)
    }

    var weekDayIdentity: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var chromeDateText: String {
        SafeMealHistoryL10n.shortDate(self)
    }

    var heroDateText: String {
        SafeMealHistoryL10n.shortDate(self)
    }

    var weekdayText: String {
        SafeMealHistoryL10n.weekday(self)
    }
}
