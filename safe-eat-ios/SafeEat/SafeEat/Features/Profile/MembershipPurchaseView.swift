import SwiftUI

struct MembershipPurchaseView: View {
    @EnvironmentObject private var store: AppStore

    @State private var plans: [MembershipPlan] = []
    @State private var selectedPlanID: String?
    @State private var selectedChannel = "wechat"
    @State private var loadingPlans = false
    @State private var creatingOrder = false
    @State private var successMessage: String?

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Membership.title),
            subtitle: SafeEatL10n.text(L10nKey.Membership.subtitle)
        ) {
            heroSection

            if loadingPlans {
                ProgressView()
                    .tint(SafeEatTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else {
                planListSection
                channelSection
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Membership.createOrder),
                isLoading: creatingOrder,
                isDisabled: selectedPlanID == nil
            ) {
                Task {
                    await createOrder()
                }
            }
        }
        .task {
            await loadPlans()
        }
        .alert(SafeEatL10n.text(L10nKey.Membership.noticeTitle), isPresented: Binding(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) {
                successMessage = nil
            }
        } message: {
            Text(successMessage ?? "")
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(SafeEatL10n.text(L10nKey.Membership.promo))
                .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(SafeEatTheme.primarySoft)
                )

            Text(SafeEatL10n.text(L10nKey.Membership.heroTitle))
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Membership.heroBody))
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ProfileSurfaceCard {
                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Membership.currentTier),
                    value: PlanTierMapper.title(store.profile?.currentPlanTier)
                )
                if let highlightedPlan = highlightedPlan {
                    Divider().overlay(SafeEatTheme.line)
                    ProfileStaticRow(
                        label: SafeEatL10n.text(L10nKey.Membership.recommendedPlan),
                        value: "\(highlightedPlan.localizedDisplayName) · \(priceText(highlightedPlan.priceFen))"
                    )
                }
            }
        }
    }

    private var planListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SafeEatSectionHeader(title: SafeEatL10n.text(L10nKey.Membership.sectionPlans))

            ForEach(plans) { plan in
                Button {
                    selectedPlanID = plan.id
                } label: {
                    ProfileSurfaceCard {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Text(plan.localizedDisplayName)
                                        .font(SafeEatFont.textStyle(.headline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)

                                    Text(planBadge(for: plan))
                                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                        .foregroundStyle(planBadgeColor(for: plan))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(planBadgeColor(for: plan).opacity(0.14))
                                        )
                                }

                                Text(planSubtitle(for: plan))
                                    .font(SafeEatFont.textStyle(.subheadline))
                                    .foregroundStyle(SafeEatTheme.textSecondary)

                                Text(
                                    SafeEatL10n.format(
                                        L10nKey.Membership.dailyQuota,
                                        plan.dailyQuota ?? 0
                                    )
                                )
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                Text(priceText(plan.priceFen))
                                    .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.textPrimary)

                                Image(systemName: selectedPlanID == plan.id ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(selectedPlanID == plan.id ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.6))
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SafeEatSectionHeader(title: SafeEatL10n.text(L10nKey.Membership.sectionChannel))

            ProfileSurfaceCard {
                HStack(spacing: 10) {
                    ForEach(PaymentChannelMapper.allChannels, id: \.self) { channel in
                        ProfileChoiceChip(
                            title: PaymentChannelMapper.title(channel),
                            isSelected: selectedChannel == channel
                        ) {
                            selectedChannel = channel
                        }
                    }
                }
            }
        }
    }

    private var highlightedPlan: MembershipPlan? {
        plans
            .filter { $0.tier != "free" }
            .min(by: { $0.priceFen < $1.priceFen })
    }

    private func loadPlans() async {
        guard plans.isEmpty else { return }

        loadingPlans = true
        defer { loadingPlans = false }

        do {
            plans = try await store.authorizedRequest { token in
                try await store.api.getPlans(accessToken: token)
            }
            selectedPlanID = plans.first(where: { $0.tier != "free" })?.id ?? plans.first?.id
        } catch {
            store.handleAPIError(error)
        }
    }

    private func createOrder() async {
        guard let selectedPlanID else { return }

        creatingOrder = true
        defer { creatingOrder = false }

        do {
            let order = try await store.createMembershipOrder(planId: selectedPlanID, channel: selectedChannel)
            successMessage = SafeEatL10n.format(L10nKey.Membership.orderCreated, order.orderNo)
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func priceText(_ fen: Int) -> String {
        let amount = Double(fen) / 100
        return String(format: "¥%.2f", amount)
    }

    private func planSubtitle(for plan: MembershipPlan) -> String {
        let cycleText = plan.billingCycle == "yearly"
            ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
            : SafeEatL10n.text(L10nKey.Membership.cycleMonthly)

        switch plan.tier {
        case "pro":
            return SafeEatL10n.format(L10nKey.Membership.subtitlePro, cycleText)
        case "lite":
            return SafeEatL10n.format(L10nKey.Membership.subtitleLite, cycleText)
        default:
            return SafeEatL10n.text(L10nKey.Membership.subtitleFree)
        }
    }

    private func planBadge(for plan: MembershipPlan) -> String {
        switch plan.tier {
        case "lite":
            return SafeEatL10n.text(L10nKey.Membership.badgeRecommended)
        case "pro":
            return SafeEatL10n.text(L10nKey.Membership.badgeAdvanced)
        default:
            return SafeEatL10n.text(L10nKey.Membership.badgeDefault)
        }
    }

    private func planBadgeColor(for plan: MembershipPlan) -> Color {
        switch plan.tier {
        case "lite":
            return SafeEatTheme.primary
        case "pro":
            return SafeEatTheme.warning
        default:
            return SafeEatTheme.textSecondary
        }
    }
}
