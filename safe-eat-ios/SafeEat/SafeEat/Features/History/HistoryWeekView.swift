import SwiftUI

private struct WeekDayGroup: Identifiable {
    let id: String
    let date: Date
    let items: [LocalHistoryItem]

    var subtitle: String {
        "\(items.count) 条记录"
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

    let referenceDate: Date

    @State private var resultRoute: HistoryWeekResultRoute?
    @State private var scrollOffset: CGFloat = 0
    @State private var currentVisibleDate: Date?

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
    private let scrollCoordinateSpace = "safeeat.history.week.scroll"
    private let stickerOffsets: [(offset: CGFloat, rotation: Double)] = [
        (0, -2), (8, 3), (0, -4), (-4, 2),
        (0, 0), (12, -3), (0, 2), (-6, 4)
    ]

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
            let topInset = SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top)

            ZStack(alignment: .topLeading) {
                SafeEatDottedRecordBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        SafeEatGlobalScrollOffsetReader(
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

                SafeEatTopBackChrome(
                    title: currentVisibleDate?.chromeDateText ?? weekRangeText,
                    scrollOffset: scrollOffset,
                    topInset: topInset,
                    minimumBackdropOpacity: 0,
                    emphasizesSafeAreaFill: true,
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
        .onAppear {
            currentVisibleDate = dayGroups.first?.date
            StickerImageCache.preload(for: Array(weekItems.prefix(12)))
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("周记录")
                .font(SafeEatFont.custom(38, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(weekRangeText)
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text("\(weekItems.count) 条记录 · \(dayGroups.count) 天")
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private func daySection(_ group: WeekDayGroup) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(group.date.heroDateText)
                    .font(SafeEatFont.custom(30, relativeTo: .title, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text("\(group.date.weekdayText) · \(group.subtitle)")
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
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

            LazyVGrid(columns: columns, spacing: 22) {
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
        let config = stickerOffsets[index % stickerOffsets.count]

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
                Label("删除", systemImage: "trash")
            }
        }
        .onTapGesture {
            resultRoute = HistoryWeekResultRoute(id: item.id, itemId: item.id)
        }
    }

    private var emptyState: some View {
        SafeEatEmptyState(
            title: "本周暂无记录",
            message: "本周识别记录会按天聚合在这里，继续拍照后就能看到每日贴纸列表。",
            systemImage: "calendar.badge.exclamationmark"
        )
        .padding(.top, 28)
    }

    private var weekRangeText: String {
        guard let weekInterval else { return "" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        let start = formatter.string(from: weekInterval.start)
        let end = formatter.string(from: weekInterval.end.addingTimeInterval(-86400))
        return "\(start) - \(end)"
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-'W'ww"
        return formatter.string(from: self)
    }

    var weekDayIdentity: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var chromeDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }

    var heroDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }

    var weekdayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}
