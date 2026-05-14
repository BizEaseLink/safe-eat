import SwiftUI

struct OrderHistoryView: View {
    @EnvironmentObject private var store: AppStore

    @State private var orders: [OrderRecord] = []
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
            await loadOrders()
        }
        .refreshable {
            orders = []
            await loadOrders()
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
                Task { await loadOrders() }
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

    private func loadOrders() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await store.authorizedRequest { token in
                try await store.api.getUserOrders(accessToken: token, page: currentPage)
            }
            orders = result.items
            totalOrders = result.total
        } catch {
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
            orders.append(contentsOf: result.items)
            totalOrders = result.total
        } catch {
            // 静默失败，不影响已加载的数据
        }
    }
}

private struct OrderRow: View {
    let order: OrderRecord

    var body: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                // 订单号 + 状态
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(order.orderNo)
                            .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                            .lineLimit(1)

                        Text(formatDate(order.createdAt))
                            .font(SafeEatFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }

                    Spacer()

                    statusBadge
                }

                Divider().overlay(SafeEatTheme.line)

                // 套餐 + 金额 + 渠道
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        ProfileStaticRow(
                            label: SafeEatL10n.text(L10nKey.Order.planLabel),
                            value: PlanTierMapper.title(order.planTier)
                        )
                        ProfileStaticRow(
                            label: SafeEatL10n.text(L10nKey.Order.channelLabel),
                            value: PaymentChannelMapper.title(order.channel)
                        )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(SafeEatTheme.priceText(order.amountFen))
                            .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        if let paidAt = order.paidAt {
                            Text(formatDate(paidAt))
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var statusBadge: some View {
        let statusText = OrderStatusMapper.title(order.status)
        let color = statusColor
        return Text(statusText)
            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.14))
            )
    }

    private var statusColor: Color {
        switch order.status {
        case "paid":
            return SafeEatTheme.success
        case "pending":
            return SafeEatTheme.warning
        case "failed", "cancelled":
            return SafeEatTheme.danger
        default:
            return SafeEatTheme.textSecondary
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        OrderHistoryView()
            .environmentObject(AppStore())
    }
}
