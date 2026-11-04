import SwiftUI

// MARK: - 候选选择页（挂在系统 sheet 里，高度固定、内容从上到下）
// 顶部：标题 + 右上角 X 关闭（无取消按钮）；列表：分组层级（一级组头可展开/收起 → 二级选项）
struct CandidateSheetView: View {
    let groups: [MatchGroup]
    let onSelect: (String?, String?) -> Void   // (foodId, name) 二者互斥
    let onCancel: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedGroupIDs: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 顶部：关闭按钮放左边（与其他页返回键一致），标题紧随其后
            HStack(spacing: 12) {
                Button { onCancel() } label: {
                    HugeIcon(glyph: .cancel01, size: 20, stroke: true)
                        .foregroundStyle(SafeMealTheme.textPrimary)
                        .frame(width: 50, height: 50)
                        .background(
                            Circle().fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.76))
                        )
                        .overlay(
                            Circle().stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Text(SafeMealL10n.text(L10nKey.Candidate.title))
                    .font(SafeMealFont.custom(20, relativeTo: .title2, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // 候选列表（从上到下）
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                        candidateGroup(group)
                        if index < groups.count - 1 {
                            Divider()
                                .overlay(SafeMealTheme.line.opacity(0.55))
                                .padding(.top, 8)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { SafeMealMainGradientBackground().ignoresSafeArea() }
    }

    @ViewBuilder
    private func candidateGroup(_ group: MatchGroup) -> some View {
        let multi = group.mode != "direct" && group.effectiveMatches.count > 1
        if multi {
            // 一级组头（可展开/收起）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    toggleExpanded(group.aiName)
                }
            } label: {
                HStack(spacing: 12) {
                    HugeIcon(glyph: .restaurant02, size: 18)
                        .foregroundStyle(SafeMealTheme.primary)
                    Text(group.aiName)
                        .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                        .lineSpacing(3)
                        .foregroundStyle(SafeMealTheme.textPrimary)
                    Spacer()
                    Text(SafeMealL10n.isZh ? "\(group.effectiveMatches.count) 项" : "\(group.effectiveMatches.count) items")
                        .font(SafeMealFont.custom(12, relativeTo: .caption, weight: .semibold))
                        .foregroundStyle(SafeMealTheme.textSecondary)
                    HugeIcon(glyph: expandedGroupIDs.contains(group.aiName) ? .arrowDown01 : .arrowRight01, size: 16)
                        .foregroundStyle(SafeMealTheme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 二级展开项（缩进 + 层级）
            if expandedGroupIDs.contains(group.aiName) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(group.effectiveMatches.enumerated()), id: \.element.id) { idx, match in
                        Button {
                            onSelect(match.foodId, nil)
                        } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(SafeMealTheme.primary.opacity(0.12))
                                    .frame(width: 6, height: 6)
                                Text(match.canonicalName)
                                    .font(SafeMealFont.textStyle(.subheadline))
                                    .lineSpacing(3)
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                                Spacer()
                                HugeIcon(glyph: .arrowRight01, size: 14)
                                    .foregroundStyle(SafeMealTheme.textSecondary.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 13)
                            .padding(.leading, 26)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if idx < group.effectiveMatches.count - 1 {
                            Divider()
                                .overlay(SafeMealTheme.line.opacity(0.4))
                                .padding(.leading, 64)
                        }
                    }
                }
            }
        } else {
            // 单候选/草稿：整行直选
            let match = group.effectiveMatches.first
            Button {
                onSelect(match?.foodId, match == nil ? group.aiName : nil)
            } label: {
                HStack(spacing: 12) {
                    HugeIcon(glyph: .restaurant02, size: 18)
                        .foregroundStyle(SafeMealTheme.primary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.aiName)
                            .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                            .lineSpacing(3)
                            .foregroundStyle(SafeMealTheme.textPrimary)
                        if let secondary = match?.canonicalName, !secondary.isEmpty {
                            Text(secondary)
                                .font(SafeMealFont.textStyle(.caption))
                                .lineSpacing(2)
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }
                    Spacer()
                    HugeIcon(glyph: .arrowRight01, size: 16)
                        .foregroundStyle(SafeMealTheme.textSecondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 15)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleExpanded(_ id: String) {
        if expandedGroupIDs.contains(id) {
            expandedGroupIDs.remove(id)
        } else {
            expandedGroupIDs.insert(id)
        }
    }
}
