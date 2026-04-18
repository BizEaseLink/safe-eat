import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    @State private var plans: [MembershipPlan] = []
    @State private var loadingPlans = false
    @State private var scrollOffset: CGFloat = 0

    private let scrollCoordinateSpace = "safeeat.profile.scroll"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                        SafeEatPageHeader(title: "菜单")

                        profileSection(title: "账户") {
                            profileRow(label: "手机号", value: store.profile?.phone ?? "--")
                            profileRow(label: "当前套餐", value: (store.profile?.currentPlanTier ?? "free").uppercased())

                            Button("刷新资料") {
                                Task {
                                    await store.refreshProfile()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(SafeEatTheme.primary)
                            .padding(.top, 4)
                        }

                        profileSection(title: "健康画像") {
                            if let tags = store.profile?.healthTags, !tags.isEmpty {
                                Text(tags.joined(separator: "、"))
                                    .font(SafeEatFont.textStyle(.body))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                            } else {
                                Text("暂无健康标签")
                                    .font(SafeEatFont.textStyle(.body))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            }

                            Text("目标：\(store.profile?.fitnessGoal ?? "未设置")")
                                .font(SafeEatFont.textStyle(.body))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }

                        profileSection(title: "会员入口（占位）") {
                            if loadingPlans {
                                ProgressView()
                                    .tint(SafeEatTheme.primary)
                            } else if plans.isEmpty {
                                Text("暂无套餐数据")
                                    .font(SafeEatFont.textStyle(.body))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            } else {
                                ForEach(plans) { plan in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(plan.tier.uppercased()) · \(plan.billingCycle)")
                                            .font(SafeEatFont.textStyle(.subheadline))
                                            .foregroundStyle(SafeEatTheme.textPrimary)
                                        Text("¥\(Double(plan.priceFen) / 100, format: .number.precision(.fractionLength(2)))")
                                            .font(SafeEatFont.textStyle(.footnote))
                                            .foregroundStyle(SafeEatTheme.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    if plan.id != plans.last?.id {
                                        Divider()
                                            .overlay(SafeEatTheme.line)
                                    }
                                }
                            }
                        }

                        profileSection(title: "会后扩展") {
                            Text("订单、支付、广告补次保留到下一阶段")
                                .font(SafeEatFont.textStyle(.body))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }

                        Button("退出登录", role: .destructive) {
                            store.logout()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(SafeEatTheme.danger.opacity(0.10))
                        )
                        .foregroundStyle(SafeEatTheme.danger)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .onPreferenceChange(SafeEatScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                SafeEatScrollNavChrome(
                    title: "个人",
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadPlansIfNeeded()
        }
    }

    private func loadPlansIfNeeded() async {
        guard plans.isEmpty else {
            return
        }

        loadingPlans = true
        defer { loadingPlans = false }

        do {
            plans = try await store.authorizedRequest { token in
                try await store.api.getPlans(accessToken: token)
            }
        } catch {
            store.handleAPIError(error)
        }
    }

    @ViewBuilder
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SafeEatSectionHeader(title: title)

            VStack(alignment: .leading, spacing: 12) {
                content()
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
    }

    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textPrimary)
            Spacer()
            Text(value)
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppStore())
    }
}
