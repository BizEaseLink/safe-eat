import SwiftUI

private struct MonthGroup: Identifiable {
    let id: String
    let title: String
    let displayMonthDate: Date
    let items: [LocalHistoryItem]
}

struct HistoryMonthView: View {
    @EnvironmentObject private var store: AppStore

    @State private var scrollOffset: CGFloat = 0
    @State private var showServerHistory = false

    private let scrollCoordinateSpace = "safeeat.history.month.scroll"

    private var monthGroups: [MonthGroup] {
        let grouped = Dictionary(grouping: store.localHistory) { item in
            item.createdAt.monthKey
        }

        return grouped
            .compactMap { key, items in
                let sortedItems = items.sorted { $0.createdAt > $1.createdAt }
                guard let displayMonthDate = sortedItems.first?.createdAt else { return nil }
                return MonthGroup(
                    id: key,
                    title: key,
                    displayMonthDate: displayMonthDate,
                    items: sortedItems
                )
            }
            .sorted { $0.id > $1.id }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if monthGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        SafeEatPageHeader(title: SafeEatL10n.text(L10nKey.Menu.title))
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 8)

                        Spacer()

                        SafeEatEmptyState(
                            title: SafeEatL10n.text(L10nKey.History.dayEmptyTitle),
                            message: SafeEatL10n.text(L10nKey.History.dayEmptyMessage),
                            systemImage: "clock.arrow.circlepath"
                        )
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                            SafeEatPageHeader(title: SafeEatL10n.text(L10nKey.Menu.title))

                            // 服务器历史记录入口
                            serverHistoryEntry

                            LazyVStack(spacing: 14) {
                                ForEach(monthGroups) { group in
                                    NavigationLink {
                                        HistoryWeekView(referenceDate: group.displayMonthDate)
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(group.title)
                                                    .font(SafeEatFont.textStyle(.headline))
                                                    .foregroundStyle(SafeEatTheme.textPrimary)
                                                Text(SafeEatL10n.format(L10nKey.History.recordCountOther, group.items.count))
                                                    .font(SafeEatFont.textStyle(.subheadline))
                                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(SafeEatTheme.textSecondary)
                                        }
                                        .padding(18)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .fill(Color(.secondarySystemBackground))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                                .stroke(SafeEatTheme.line, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 48)
                    }
                    .coordinateSpace(name: scrollCoordinateSpace)
                    .onPreferenceChange(SafeEatScrollOffsetKey.self) { value in
                        scrollOffset = value
                    }
                }

                SafeEatScrollNavChrome(
                    title: SafeEatL10n.text(L10nKey.Menu.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    /// 服务器历史记录入口（对接后端 API）
    private var serverHistoryEntry: some View {
        Button {
            showServerHistory = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundStyle(SafeEatTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(SafeEatL10n.text(L10nKey.History.serverNavTitle))
                        .font(SafeEatFont.textStyle(.headline))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    Text(SafeEatL10n.text(L10nKey.History.dayEmptyMessage))
                        .font(SafeEatFont.textStyle(.caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SafeEatTheme.primary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SafeEatTheme.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showServerHistory) {
            NavigationStack {
                HistoryServerListView()
                    .environmentObject(store)
            }
        }
    }
}

private extension Date {
    var monthKey: String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = AppSettingsStore.shared.language == .en ? "MMMM yyyy" : "yyyy 年 MM 月"
        return formatter.string(from: self)
    }
}

#Preview {
    NavigationStack {
        HistoryMonthView()
            .environmentObject(AppStore())
    }
}
