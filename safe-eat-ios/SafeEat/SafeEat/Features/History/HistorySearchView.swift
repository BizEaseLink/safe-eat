import SwiftUI

// 历史记录秒搜：顶部对齐 iOS 原生照片选择器（白底 + 圆形 X + 胶囊分段），结果用贴纸流
// 用法：
//   HistorySearchMagnifier(onTap: { showSearch = true })
//   .sheet(isPresented: $showSearch) {
//       HistorySearchView(
//           dateRange: nil,              // nil = 全部历史；传 ClosedRange = 限定
//           scopeTitle: nil,             // 当前范围标签（如「今天」「本周」）；nil = 不分段（全局搜索）
//           onSelect: { item in ... }
//       )
//   }

// MARK: - 放大镜按钮（圆形，对齐主页铃铛）

struct HistorySearchMagnifier: View {
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SafeEatL10n.text(L10nKey.History.searchTitle))
    }
}

// MARK: - 搜索范围分段

private enum HistorySearchScope: Hashable {
    case current  // 当前范围（日/周/月，由 dateRange 决定）
    case all      // 全部历史
}

// MARK: - 搜索层（原生选图器风格顶部）

struct HistorySearchView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    /// 时间范围：nil = 全部历史；传 ClosedRange 限定（当天 / 本周 / 某月）
    var dateRange: ClosedRange<Date>? = nil
    /// 当前范围标签（如「今天」「本周」）；nil 时顶部分段不显示（全局搜索场景）
    var scopeTitle: String? = nil
    /// 结果点击回调：由承载页触发既有 navigationDestination（ResultView(itemId:)）
    var onSelect: (LocalHistoryItem) -> Void = { _ in }

    @State private var query = ""
    @State private var scope: HistorySearchScope = .current

    /// 全局搜索（dateRange 为 nil）时固定全部历史
    private var effectiveScope: HistorySearchScope {
        dateRange == nil ? .all : scope
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 范围内全部记录（按时间倒序）
    private var scopedItems: [LocalHistoryItem] {
        store.localHistory
            .filter { item in
                switch effectiveScope {
                case .all:
                    return true
                case .current:
                    guard let range = dateRange else { return true }
                    return range.contains(item.createdAt)
                }
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// 搜索结果：食物名子串匹配（大小写不敏感，兼容中英文）
    private var results: [LocalHistoryItem] {
        let kw = trimmedQuery.lowercased()
        guard !kw.isEmpty else { return [] }
        return scopedItems.filter { item in
            item.recognizedName.lowercased().contains(kw)
            || (item.alternateNames?.contains { $0.lowercased().contains(kw) } ?? false)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                backgroundLayer

                VStack(spacing: 0) {
                    topBar(topInset: proxy.safeAreaInsets.top)

                    searchField
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    if trimmedQuery.isEmpty {
                        scopeHint
                    } else if results.isEmpty {
                        emptyResults
                    } else {
                        resultList
                    }
                }
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - 背景（贴近原生选图器的浅色底）

    private var backgroundLayer: some View {
        Color(.systemBackground)
    }

    // MARK: - 顶部（X 圆形关闭 + 胶囊分段 / 标题）

    private func topBar(topInset: CGFloat) -> some View {
        HStack(spacing: 12) {
            closeButton

            Spacer(minLength: 0)

            if scopeTitle != nil {
                scopeSegmentedControl
            } else {
                Text(SafeEatL10n.text(L10nKey.History.searchTitle))
                    .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }

            Spacer(minLength: 0)

            // 右侧占位与 X 对称
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, topInset + 10)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(SafeEatL10n.text(L10nKey.Common.close))
    }

    /// 胶囊分段：当前范围 | 全部
    private var scopeSegmentedControl: some View {
        HStack(spacing: 4) {
            scopeTab(
                title: scopeTitle ?? "",
                selected: scope == .current
            ) { scope = .current }

            scopeTab(
                title: SafeEatL10n.text(L10nKey.History.searchScopeAll),
                selected: scope == .all,
            ) { scope = .all }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
        )
    }

    private func scopeTab(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? SafeEatTheme.textPrimary : SafeEatTheme.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            selected
                                ? (colorScheme == .dark ? Color.white.opacity(0.14) : Color.white)
                                : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 搜索框

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(SafeEatTheme.textSecondary)

            TextField(
                SafeEatL10n.text(L10nKey.History.searchPlaceholder),
                text: $query
            )
            .font(SafeEatFont.textStyle(.body))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .autocorrectionDisabled()

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
        )
    }

    // MARK: - 范围提示（未输入时）

    private var scopeHint: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(scopeHintText)
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
        .padding(.horizontal, 40)
    }

    private var scopeHintText: String {
        if effectiveScope == .current, let scopeTitle {
            return SafeEatL10n.format(L10nKey.History.searchScopeFormat, scopeTitle)
        }
        return SafeEatL10n.text(L10nKey.History.searchAllHint)
    }

    // MARK: - 空结果

    private var emptyResults: some View {
        SafeEatEmptyState(
            title: SafeEatL10n.text(L10nKey.History.searchEmptyTitle),
            message: SafeEatL10n.text(L10nKey.History.searchEmptyMessage),
            systemImage: "magnifyingglass"
        )
        .padding(.top, 40)
    }

    // MARK: - 结果列表（贴纸流，对齐日/周视图）

    private var resultList: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: searchColumns, spacing: 26) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, item in
                    stickerCard(for: item, index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    private var searchColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)]
    }

    private func stickerCard(for item: LocalHistoryItem, index: Int) -> some View {
        let config = HistoryStickerConfig.offsets[index % HistoryStickerConfig.offsets.count]

        return AsyncRecognitionStickerView(
            item: item,
            imageHeight: 126,
            labelMaxWidth: 200,
            rotationAngle: config.rotation,
            offsetY: config.offset,
            style: .floating,
        )
        .contentShape(Rectangle())
        .onTapGesture {
            dismiss()
            onSelect(item)
        }
    }
}
