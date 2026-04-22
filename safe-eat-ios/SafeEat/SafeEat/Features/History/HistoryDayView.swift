import SwiftUI

private struct HistoryDayResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID
}

struct HistoryDayView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var resultRoute: HistoryDayResultRoute?
    @State private var scrollOffset: CGFloat = 0

    private let columns = [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
    private let stickerOffsets: [(offset: CGFloat, rotation: Double)] = [
        (0, -2), (8, 3), (0, -4), (-4, 2),
        (0, 0), (12, -3), (0, 2), (-6, 4)
    ]

    private var dayItems: [LocalHistoryItem] {
        store.localHistory
            .filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
            .sorted { $0.createdAt > $1.createdAt }
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
                        .id(date.historyDayIdentity)

                        Color.clear
                            .frame(height: topInset + 36)

                        heroHeader

                        if dayItems.isEmpty {
                            emptyState
                        } else {
                            LazyVGrid(columns: columns, spacing: 22) {
                                ForEach(Array(dayItems.enumerated()), id: \.element.id) { index, item in
                                    stickerCard(for: item, index: index)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }

                SafeEatTopBackChrome(
                    title: date.chromeDateText,
                    scrollOffset: scrollOffset,
                    topInset: topInset,
                    minimumBackdropOpacity: 0,
                    emphasizesSafeAreaFill: true,
                    onBack: { dismiss() }
                )
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(item: $resultRoute) { route in
            ResultView(itemId: route.itemId)
        }
        .onAppear {
            scrollOffset = 0
            StickerImageCache.preload(for: Array(dayItems.prefix(10)))
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date.heroDateText)
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(dayItems.isEmpty ? "暂无记录" : "\(dayItems.count) 条记录")
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
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
            resultRoute = HistoryDayResultRoute(id: item.id, itemId: item.id)
        }
    }

    private var emptyState: some View {
        SafeEatEmptyState(
            title: "当天暂无本地记录",
            message: "先去首页完成一次识别，日记录会把同一天的内容集中展示在这里。",
            systemImage: "square.stack.3d.up.slash"
        )
        .padding(.top, 28)
    }
}

private extension Date {
    var historyDayIdentity: String {
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
}
