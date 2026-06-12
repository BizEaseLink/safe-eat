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
                            LazyVGrid(columns: columns, spacing: 32) {
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

            Text(dayItems.isEmpty ? SafeEatL10n.text(L10nKey.History.noRecords) : SafeEatHistoryL10n.recordCount(dayItems.count))
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
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
                Label(SafeEatL10n.text(L10nKey.Common.delete), systemImage: "trash")
            }
        }
        .onTapGesture {
            resultRoute = HistoryDayResultRoute(id: item.id, itemId: item.id)
        }
    }

    private var emptyState: some View {
        SafeEatEmptyState(
            title: SafeEatL10n.text(L10nKey.History.dayEmptyTitle),
            message: SafeEatL10n.text(L10nKey.History.dayEmptyMessage),
            systemImage: "square.stack.3d.up.slash"
        )
        .padding(.top, 28)
    }
}

private extension Date {
    var historyDayIdentity: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var chromeDateText: String {
        SafeEatHistoryL10n.shortDate(self)
    }

    var heroDateText: String {
        SafeEatHistoryL10n.shortDate(self)
    }
}
