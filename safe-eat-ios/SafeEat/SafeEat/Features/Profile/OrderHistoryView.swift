import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject private var store: AppStore

    @State private var orders: [OrderContainer] = []
    @State private var currentPage = 1
    @State private var totalOrders = 0
    @State private var isLoadingMore = false
    @State private var isLoading = false
    @State private var loadError: String?

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Order.title),
            subtitle: SafeEatL10n.text(L10nKey.Order.subtitle)
        ) {
            if isLoading {
                ProgressView()
                    .tint(SafeEatTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else if let error = loadError {
                errorView(message: error)
            } else if orders.isEmpty {
                emptyView
            } else {
                orderList
            }
        }
        .task {
            await loadOrders(isInitial: true)
        }
        .refreshable {
            // 刷新：清错误状态 + 回第 1 页，但不清 orders（保持旧数据，避免闪空）
            // 不设 isLoading（.refreshable 自带刷新动画，设了会闪 ProgressView 盖住旧数据）
            loadError = nil
            currentPage = 1
            await loadOrders(isInitial: false)
        }
    }

    private var orderList: some View {
        LazyVStack(spacing: 14) {
            ForEach(orders) { order in
                OrderRow(order: order)
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(SafeEatL10n.text(L10nKey.Order.emptyTitle))
                .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Order.emptyMessage))
                .font(SafeEatFont.custom(15, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 48)
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(SafeEatTheme.warning)

            Text(message)
                .font(SafeEatFont.custom(15, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                loadError = nil
                orders = []
                Task { await loadOrders(isInitial: true) }
            } label: {
                Text(SafeEatL10n.text(L10nKey.Common.ok))
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(SafeEatTheme.primarySoft)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 48)
        .frame(maxWidth: .infinity)
    }

    /// isInitial=true：首次加载（设 isLoading，显示 ProgressView）
    /// isInitial=false：下拉刷新（不设 isLoading，保持旧数据，.refreshable 自带动画）
    private func loadOrders(isInitial: Bool) async {
        if isInitial { isLoading = true }
        defer { if isInitial { isLoading = false } }

        // 捕获当前页码，await 期间若用户再次刷新（currentPage 变化），本结果不覆盖
        let targetPage = currentPage
        do {
            let result = try await store.authorizedRequest { token in
                try await store.api.getUserOrders(accessToken: token, page: targetPage)
            }
            // 原子赋值：仅当 currentPage 仍是本次请求的页码时才应用结果
            guard currentPage == targetPage else { return }
            // 过滤纯状态变更容器：用户端只展示含付费子订单(status=paid)的容器。
            // 纯状态变更审计容器(全是 notice/expired/revoked/refunded/grace 等无 paid 子订单)
            // 不显示；混合容器(有 paid + 有状态变更)保留,用户能看到付费记录。
            // totalOrders 仍用 result.total，避免后端分页计数错乱。
            orders = result.items.filter { container in
                let subOrders = container.orders ?? []
                return subOrders.contains { $0.status == "paid" }
            }
            totalOrders = result.total
        } catch {
            // 下拉刷新时前一个请求被取消是正常行为（URLError.cancelled），不显示错误
            if let urlError = error as? URLError, urlError.code == .cancelled { return }
            if (error as NSError).code == NSURLErrorCancelled { return }
            #if DEBUG
            print("[OrderHistoryView] loadOrders failed: \(error)")
            #endif
            guard currentPage == targetPage else { return }
            loadError = error.localizedDescription
        }
    }

    private func loadMoreOrders() async {
        guard !isLoadingMore, orders.count < totalOrders else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let result = try await store.authorizedRequest { token in
                try await store.api.getUserOrders(accessToken: token, page: nextPage)
            }
            currentPage = nextPage
            // 翻页加载同样过滤纯状态变更容器，保持与首页一致
            let filtered = result.items.filter { container in
                let subOrders = container.orders ?? []
                return subOrders.contains { $0.status == "paid" }
            }
            orders.append(contentsOf: filtered)
            totalOrders = result.total
        } catch {
            // 静默失败，不影响已加载的数据
        }
    }
}

private struct OrderRow: View {
    let order: OrderContainer

    /// 卡片主时间：优先用容器内最早付款时间（用户感知的"我什么时候买的"），
    /// 没有付款记录时降级到 DB 写库时间 createdAt
    private var displayDate: Date {
        order.firstPaidAt ?? order.createdAt
    }

    var body: some View {
        SafeEatSurfaceCard(cornerRadius: 26) {
            VStack(alignment: .leading, spacing: 14) {
                // 顶部：订单号 + 状态 badge
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(order.orderNo)
                        .font(SafeEatFont.custom(15, relativeTo: .body, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 8)

                    statusBadge
                }

                // 付款时间（用户感知的购买时间）
                Text(formatDate(displayDate))
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                // 细分割线
                Rectangle()
                    .fill(SafeEatTheme.line)
                    .frame(height: 0.5)

                // 底部：tier + 渠道 chip 组（左） / 金额（右，视觉焦点）
                HStack(alignment: .center, spacing: 8) {
                    infoChip(
                        text: PlanTierMapper.title(order.currentPlanTier),
                        color: SafeEatTheme.primary
                    )
                    infoChip(
                        text: PaymentChannelMapper.title(order.channel),
                        color: SafeEatTheme.textSecondary
                    )

                    Spacer()

                    Text(SafeEatTheme.priceText(order.totalAmountFen))
                        .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }

    /// 紧凑型信息 chip：低饱和背景 + 描边 + 12pt 文本
    private func infoChip(text: String, color: Color) -> some View {
        Text(text)
            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.25), lineWidth: 0.5)
            )
    }

    private var statusBadge: some View {
        let statusText = OrderEventMapper.title(order.lastEvent)
        let color = statusColor
        return Text(statusText)
            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
    }

    /// lastEvent 颜色：与 Admin OrderManageView 对齐
    /// - danger(=Admin destructive)：renewal_failed/expired/refund/revoke/family_sharing_revoke/cancel_renewal/downgrade_scheduled
    /// - success(=Admin default)：initial_purchase/renewal/upgrade/renewal_reenabled
    /// - textSecondary(=Admin secondary)：其余(grace_period/change_cycle/upgrade_scheduled 等)
    private var statusColor: Color {
        guard let event = order.lastEvent else {
            return SafeEatTheme.textSecondary
        }
        switch event {
        case "initial_purchase", "renewal", "upgrade", "renewal_reenabled":
            return SafeEatTheme.success
        case "renewal_failed", "expired", "refund", "revoke",
             "family_sharing_revoke", "cancel_renewal", "downgrade_scheduled":
            return SafeEatTheme.danger
        default:
            // grace_period / change_cycle / upgrade_scheduled / 未知事件 → 灰
            return SafeEatTheme.textSecondary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        // 显式设手机本地时区，确保 UTC 时间按用户当前时区展示
        formatter.timeZone = .current
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        #if DEBUG
        print("[OrderHistoryView] formatDate: raw=\(date) epoch=\(date.timeIntervalSince1970) tz=\(formatter.timeZone.identifier) -> \(formatter.string(from: date))")
        #endif
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        OrderHistoryView()
            .environmentObject(AppStore())
    }
}
