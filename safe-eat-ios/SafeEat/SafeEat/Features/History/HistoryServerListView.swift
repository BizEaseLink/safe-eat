import SwiftUI

/// 服务器端历史记录列表视图（MOB-2）
/// 对接后端 listForUser API，展示用户识别记录 + 套餐限制提示
struct HistoryServerListView: View {
    @EnvironmentObject var store: AppStore
    @State private var isLoading = false
    @State private var showMembership = false

    private var records: [RecognitionRecord] { store.serverHistory }
    private var totalCount: Int { store.serverHistoryTotal }

    /// 当前套餐允许的历史记录数（nil = 无限）
    private var limit: Int? { store.maxHistoryRecords }

    /// 是否达到限制
    private var isLimitReached: Bool { store.isHistoryLimitReached }

    /// 升级目标 tier 名称
    private var upgradeTierName: String {
        let tier = store.profile?.currentPlanTier ?? "free"
        switch tier {
        case "free": return "Lite"
        case "lite": return "Pro"
        default: return "Premium"
        }
    }

    var body: some View {
        List {
            // 记录计数
            if totalCount > 0 {
                Section {
                    Text(SafeEatL10n.format(L10nKey.History.serverRecordCountFormat, totalCount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // 识别记录列表
            ForEach(records) { record in
                NavigationLink {
                    HistoryRecordDetailView(record: record)
                } label: {
                    HistoryRecordRow(record: record)
                }
            }

            // 加载更多
            if records.count < totalCount {
                Section {
                    Button {
                        Task { await loadMore() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text(SafeEatL10n.text(L10nKey.History.serverEmptyMessage))
                                    .font(.subheadline)
                            }
                            Spacer()
                        }
                    }
                    .disabled(isLoading)
                }
            }

            // 套餐限制提示
            if isLimitReached, let limit = limit {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text(SafeEatL10n.text(L10nKey.History.upgradePromptTitle))
                                .font(.subheadline.bold())
                        }
                        Text(SafeEatL10n.format(L10nKey.History.upgradePromptMessageFormat, limit))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            showMembership = true
                        } label: {
                            Text(SafeEatL10n.text(L10nKey.History.upgradePromptAction))
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(SafeEatL10n.text(L10nKey.History.serverNavTitle))
        .overlay {
            if records.isEmpty && !isLoading {
                ContentUnavailableView(
                    SafeEatL10n.text(L10nKey.History.serverEmptyTitle),
                    systemImage: "clock.arrow.circlepath",
                    description: Text(SafeEatL10n.text(L10nKey.History.serverEmptyMessage))
                )
            }
        }
        .overlay {
            if isLoading && records.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(SafeEatL10n.text(L10nKey.History.loadingTitle))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showMembership) {
            MembershipPurchaseView()
        }
        .task {
            if records.isEmpty {
                await loadHistory()
            }
        }
        .refreshable {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        await store.loadServerHistory(refresh: true)
    }

    private func loadMore() async {
        isLoading = true
        defer { isLoading = false }
        await store.loadServerHistory(refresh: false)
    }
}

/// 单条历史记录行视图
struct HistoryRecordRow: View {
    let record: RecognitionRecord
    @Environment(\.colorScheme) private var colorScheme

    private var scoreColor: Color {
        guard let score = record.overallScore else { return .gray }
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        guard let score = record.overallScore else { return "--" }
        return String(score)
    }

    private var recommendationLabel: String {
        switch record.recommendationLevel {
        case "recommended": return SafeEatL10n.text(L10nKey.Result.recommendYes)
        case "moderate": return SafeEatL10n.text(L10nKey.Result.recommendModerate)
        case "cautious": return SafeEatL10n.text(L10nKey.Result.recommendCautious)
        default: return ""
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 评分圆
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 48, height: 48)
                Text(scoreLabel)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
            }

            // 食物名称 + 时间
            VStack(alignment: .leading, spacing: 4) {
                Text(record.recognizedName)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                if let createdAt = record.createdAt {
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // 推荐等级
            if !recommendationLabel.isEmpty {
                Text(recommendationLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .foregroundStyle(scoreColor)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}
