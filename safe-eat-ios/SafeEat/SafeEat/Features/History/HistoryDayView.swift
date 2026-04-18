import SwiftUI

private struct DayGroup: Identifiable {
    let id: String
    let date: Date
    let subtitle: String
    let items: [LocalHistoryItem]
}

private struct HistoryResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID
}

struct HistoryDayView: View {
    @EnvironmentObject private var store: AppStore

    let monthKey: String
    let monthDate: Date

    @State private var resultRoute: HistoryResultRoute?

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]

    private var monthItems: [LocalHistoryItem] {
        store.localHistory
            .filter { $0.createdAt.historyMonthKey == monthKey }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var dayGroups: [DayGroup] {
        let grouped = Dictionary(grouping: monthItems) { item in
            item.createdAt.dayKey
        }

        return grouped
            .compactMap { _, value in
                let sortedItems = value.sorted { $0.createdAt > $1.createdAt }
                guard let date = sortedItems.first?.createdAt else { return nil }
                return DayGroup(
                    id: date.dayKey,
                    date: date,
                    subtitle: "\(sortedItems.count) 条记录",
                    items: sortedItems
                )
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            StickerPaperBackground()

            if dayGroups.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SafeEatDateTitle(
                        date: monthDate,
                        showsMonth: true,
                        showsDay: false,
                        color: SafeEatTheme.textPrimary,
                        largeSize: 34,
                        smallSize: 16
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    Spacer()

                    SafeEatEmptyState(
                        title: "本月暂无本地记录",
                        message: "删除完成后，这个月已经没有可展示的识别记录。",
                        systemImage: "square.stack.3d.up.slash"
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        SafeEatDateTitle(
                            date: monthDate,
                            showsMonth: true,
                            showsDay: false,
                            color: SafeEatTheme.textPrimary,
                            largeSize: 34,
                            smallSize: 16
                        )

                        ForEach(dayGroups) { group in
                            VStack(alignment: .leading, spacing: 18) {
                                dayHeader(for: group)

                                LazyVGrid(columns: columns, spacing: 26) {
                                    ForEach(group.items) { item in
                                        collapsedSticker(for: item)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationDestination(item: $resultRoute) { route in
            ResultView(itemId: route.itemId)
        }
    }

    private func dayHeader(for group: DayGroup) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SafeEatDateTitle(
                date: group.date,
                showsMonth: true,
                showsDay: true,
                color: SafeEatTheme.textPrimary,
                largeSize: 32,
                smallSize: 15
            )

            Text(group.subtitle)
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private func collapsedSticker(for item: LocalHistoryItem) -> some View {
        RecognitionStickerThumbnailView(
            item: item,
            imageHeight: 126,
            labelMaxWidth: 200
        )
        .frame(maxWidth: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                store.removeHistoryItem(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .onTapGesture {
            resultRoute = HistoryResultRoute(id: item.id, itemId: item.id)
        }
    }
}

private extension Date {
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: self)
    }

    var historyMonthKey: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 MM 月"
        return formatter.string(from: self)
    }
}
