import Combine
import SwiftUI
import StoreKit

struct MembershipPurchaseView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedPlanID: String?
    @State private var selectedBillingCycle = "monthly"
    @State private var loadingPlans = false
    @State private var creatingOrder = false
    @State private var successMessage: String?
    @State private var plansLoadError: String?
    @State private var now = Date()
    @State private var showPriceBreakdownSheet = false
    @State private var showTrialPrompt = false
    @State private var showPurchaseConfirmSheet = false

    private var isNewUser: Bool {
        guard let tier = store.profile?.currentPlanTier else { return true }
        return tier == "free"
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Membership.title),
            subtitle: SafeEatL10n.text(L10nKey.Membership.subtitle)
        ) {
            // 新用户赠送提示
            if isNewUser {
                newUserGiftBanner
            }

            if loadingPlans {
                ProgressView()
                    .tint(SafeEatTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else if let error = plansLoadError {
                plansLoadErrorView
            } else if sortedPaidPlans.isEmpty {
                noPlansView
            } else {
                planListSection
            }
        } footer: {
            VStack(spacing: 12) {
                // 活动权益标签区
                if let plan = selectedPlan, !store.campaignBenefits.isEmpty {
                    campaignBenefitTags(for: plan)
                }

                // 价格明细弹层入口
                if let plan = selectedPlan, hasAnyBenefit(for: plan) {
                    Button {
                        showPriceBreakdownSheet = true
                    } label: {
                        Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownTitle))
                            .font(SafeEatFont.custom(13, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                    .buttonStyle(.plain)
                }

                // 购买/订阅按钮
                ProfilePrimaryActionButton(
                    title: purchaseButtonText,
                    isLoading: creatingOrder || store.isPurchasingMembership,
                    isDisabled: selectedPlanID == nil
                ) {
                    showPurchaseConfirmSheet = true
                }

                // 恢复购买按钮
                Button {
                    Task {
                        await store.restorePurchases()
                    }
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Membership.restorePurchases))
                        .font(SafeEatFont.textStyle(.caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .disabled(store.isRestoringPurchases)
            }
        }
        .task {
            await loadPlans()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { time in
            now = time
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
        .sheet(isPresented: $showTrialPrompt) {
            trialPromptSheet
        }
        .sheet(isPresented: $showPriceBreakdownSheet) {
            if let plan = selectedPlan {
                priceBreakdownSheet(for: plan)
            }
        }
        .sheet(isPresented: $showPurchaseConfirmSheet) {
            if let plan = selectedPlan {
                purchaseConfirmSheet(for: plan)
            }
        }
        .onChange(of: store.purchaseError) { newValue in
            if newValue != nil && isNewUser {
                showTrialPrompt = true
            }
        }
    }

    // MARK: - 新用户赠送提示

    private var newUserGiftBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "gift.fill")
                .foregroundStyle(SafeEatTheme.warning)
            Text(SafeEatL10n.text(L10nKey.Membership.newUserGiftBanner))
                .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                .foregroundStyle(SafeEatTheme.warning)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(SafeEatTheme.warning.opacity(0.10))
        )
    }

    // MARK: - Plan List Section

    private var plansLoadErrorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text(SafeEatL10n.text(L10nKey.Membership.plansLoadError))
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                plansLoadError = nil
                Task { await loadPlans() }
            } label: {
                Text(SafeEatL10n.text(L10nKey.Common.retry))
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
            }
        }
        .padding(.top, 40)
    }

    private var noPlansView: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(SafeEatTheme.textSecondary)
            Text(SafeEatL10n.text(L10nKey.Membership.noPlansAvailable))
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var planListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SafeEatSectionHeader(title: SafeEatL10n.text(L10nKey.Membership.sectionPlans))
                Spacer()
                billingCyclePicker
            }

            if let error = plansLoadError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Retry") {
                        plansLoadError = nil
                        Task { await loadPlans() }
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // 按 sortOrder 排序展示：Lite -> Pro -> Premium
            ForEach(sortedPaidPlans) { plan in
                paidPlanCard(plan)
            }
        }
    }

    // MARK: - Paid Plan Card（动态权益展示）

    private func paidPlanCard(_ plan: MembershipPlan) -> some View {
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

                            // 推荐标签：Pro 标"推荐"
                            if plan.tier == "pro" {
                                Text(SafeEatL10n.text(L10nKey.Membership.badgeRecommended))
                                    .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(SafeEatTheme.primary.opacity(0.14))
                                    )
                            } else {
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
                        }

                        // 动态权益展示：优先用后端 benefitsDescription
                        planBenefitsView(plan)

                        // 试用标签 + 扣费提示（Apple 审核指南 3.1.2(a)）
                        Group {
                            if let product = storeKitProduct(for: plan),
                               let intro = product.subscription?.introductoryOffer,
                               intro.paymentMode == .freeTrial {
                                HStack(spacing: 6) {
                                    Text(SafeEatL10n.format(L10nKey.Membership.freeTrialDays, intro.period.value))
                                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.warning)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(SafeEatTheme.warning.opacity(0.14))
                                        )

                                    Text(SafeEatL10n.text(L10nKey.Membership.trialDisclaimer))
                                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 8) {
                        // 活动权益标签
                        ForEach(campaignBenefitsForPlan(plan)) { benefit in
                            Text(campaignBenefitText(benefit))
                                .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .bold))
                                .foregroundStyle(SafeEatTheme.warning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(SafeEatTheme.warning.opacity(0.14))
                                )
                        }

                        // 价格
                        Text(displayPrice(for: plan))
                            .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Image(systemName: selectedPlanID == plan.id ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(selectedPlanID == plan.id ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.6))

                        // 年费对比
                        if selectedBillingCycle == "monthly", let yearlyPlan = store.membershipPlans.first(where: { $0.tier == plan.tier && $0.billingCycle == "yearly" }), yearlyPlan.priceFen > 0 {
                            Text(SafeEatL10n.format(
                                L10nKey.Membership.yearlyPriceHint,
                                SafeEatTheme.priceText(yearlyPlan.priceFen),
                                SafeEatTheme.priceText(yearlyPlan.priceFen / 12)
                           ))
                            .font(SafeEatFont.custom(11, relativeTo: .caption2))
                            .foregroundStyle(SafeEatTheme.primary.opacity(0.72))
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 动态权益展示

    /// 优先使用后端 benefitsDescription，降级使用本地额度文案
    private func planBenefitsView(_ plan: MembershipPlan) -> some View {
        Group {
            if let desc = plan.benefitsDescription, !desc.isEmpty {
                // 后端动态权益描述
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(desc.split(separator: "\n"), id: \.self) { line in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(String(line))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            } else {
                // 降级：本地额度文案
                VStack(alignment: .leading, spacing: 4) {
                    if let quota = plan.recognitionQuotaMonthly {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(SafeEatL10n.format(L10nKey.Membership.benefitRecognitionMonthly, quota))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                    if let aiQuota = plan.aiQuotaMonthly {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(SafeEatL10n.format(L10nKey.Membership.benefitAiMonthly, aiQuota))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                    if let daily = plan.dailyQuota, daily > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(SafeEatL10n.format(L10nKey.Membership.benefitDailyQuota, daily))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                    if let level = plan.aiAdviceLevel, !level.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(SafeEatL10n.format(L10nKey.Membership.benefitAiAdviceLevel, AiAdviceLevelMapper.title(level)))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                    if let profiles = plan.maxHealthProfiles, profiles > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(SafeEatL10n.format(L10nKey.Membership.benefitMaxHealthProfiles, profiles))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                    if let limit = plan.historyLimit {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                            Text(limit == -1
                                ? SafeEatL10n.text(L10nKey.Membership.benefitHistoryLimitUnlimited)
                                : SafeEatL10n.format(L10nKey.Membership.benefitHistoryLimit, limit))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Campaign Benefit Tags

    private func campaignBenefitTags(for plan: MembershipPlan) -> some View {
        Group {
            ForEach(campaignBenefitsForPlan(plan)) { benefit in
                HStack(spacing: 4) {
                    Image(systemName: "gift")
                        .font(SafeEatFont.custom(10, relativeTo: .caption2))
                    Text(campaignBenefitText(benefit))
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                }
                .foregroundStyle(SafeEatTheme.warning)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(SafeEatTheme.warning.opacity(0.1))
                )
            }
        }
    }

    // MARK: - Price Breakdown Sheet

    private func priceBreakdownSheet(for plan: MembershipPlan) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 套餐原价
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownOriginal))
                    Spacer()
                    Text(displayPrice(for: plan))
                        .strikethrough()
                }
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

                Divider().overlay(SafeEatTheme.line)

                // Apple 优惠
                if let product = storeKitProduct(for: plan),
                   let intro = product.subscription?.introductoryOffer, intro.paymentMode != .freeTrial {
                    HStack {
                        Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownAppleOffer))
                        Spacer()
                        Text(appleOfferText(intro))
                    }
                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.warning)
                }

                // 后台活动
                ForEach(campaignBenefitsForPlan(plan)) { benefit in
                    HStack {
                        Text(benefit.name)
                        Spacer()
                        Text("-\(campaignBenefitText(benefit))")
                    }
                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.warning)
                }

                // 额外权益
                let bonusText = bonusSummaryText(for: plan)
                if !bonusText.isEmpty {
                    HStack {
                        Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownBonus))
                        Spacer()
                        Text(bonusText)
                    }
                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.warning)
                }

                Divider().overlay(SafeEatTheme.line)

                // 实际支付
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownPayment))
                    Spacer()
                    Text(SafeEatL10n.text(L10nKey.Membership.priceBreakdownAppleFinal))
                }
                .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
            }
            .padding(20)
            .navigationTitle(SafeEatL10n.text(L10nKey.Membership.priceBreakdownTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SafeEatL10n.text(L10nKey.Common.cancel)) {
                        showPriceBreakdownSheet = false
                    }
                }
            }
        }
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Trial Prompt Sheet

    private var trialPromptSheet: some View {
        VStack(spacing: 24) {
            Image(systemName: "gift")
                .font(.system(size: 48))
                .foregroundStyle(SafeEatTheme.primary)

            Text(SafeEatL10n.text(L10nKey.Membership.trialPromptTitle))
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Membership.trialPromptBody))
                .font(SafeEatFont.custom(15, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)

            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Membership.trialPromptAction)
            ) {
                showTrialPrompt = false
            }

            Button(SafeEatL10n.text(L10nKey.Common.cancel)) {
                showTrialPrompt = false
            }
            .font(SafeEatFont.custom(15, relativeTo: .body))
            .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .padding(24)
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Purchase Confirm Sheet（付款折扣展示）

    private func purchaseConfirmSheet(for plan: MembershipPlan) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 套餐名称
                Text(plan.localizedDisplayName)
                    .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Divider().overlay(SafeEatTheme.line)

                // 原价
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.confirmOriginalPrice))
                    Spacer()
                    Text(displayPrice(for: plan))
                }
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

                // 赠送权益明细
                let benefits = campaignBenefitsForPlan(plan)
                if !benefits.isEmpty {
                    Divider().overlay(SafeEatTheme.line)

                    Text(SafeEatL10n.text(L10nKey.Membership.confirmBonusTitle))
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.warning)

                    ForEach(benefits) { benefit in
                        HStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .font(SafeEatFont.custom(12, relativeTo: .caption))
                                .foregroundStyle(SafeEatTheme.warning)
                            Text(benefit.name)
                            Spacer()
                            Text(campaignBenefitText(benefit))
                                .bold()
                        }
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    }
                }

                // Apple 优惠（试用/首期折扣）
                if let product = storeKitProduct(for: plan),
                   let intro = product.subscription?.introductoryOffer {
                    Divider().overlay(SafeEatTheme.line)

                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(SafeEatFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.primary)
                        Text(SafeEatL10n.text(L10nKey.Membership.confirmAppleOffer))
                        Spacer()
                        Text(appleOfferText(intro))
                            .bold()
                    }
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.primary)
                }

                Spacer()

                // 最终价格提示
                VStack(spacing: 8) {
                    Text(SafeEatL10n.text(L10nKey.Membership.confirmFinalPriceHint))
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    ProfilePrimaryActionButton(
                        title: SafeEatL10n.format(L10nKey.Membership.confirmPayButton, displayPrice(for: plan)),
                        isLoading: creatingOrder || store.isPurchasingMembership
                    ) {
                        showPurchaseConfirmSheet = false
                        Task {
                            await purchase()
                        }
                    }
                }
            }
            .padding(20)
            .navigationTitle(SafeEatL10n.text(L10nKey.Membership.confirmSheetTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SafeEatL10n.text(L10nKey.Common.cancel)) {
                        showPurchaseConfirmSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Billing Cycle Picker

    private var billingCyclePicker: some View {
        HStack(spacing: 0) {
            ForEach(["monthly", "yearly"], id: \.self) { cycle in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedBillingCycle = cycle
                        selectedPlanID = sortedPaidPlans.first?.id
                    }
                } label: {
                    Text(cycle == "yearly"
                        ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
                        : SafeEatL10n.text(L10nKey.Membership.cycleMonthly))
                        .font(SafeEatFont.custom(13, relativeTo: .callout, weight: selectedBillingCycle == cycle ? .bold : .regular))
                        .foregroundStyle(selectedBillingCycle == cycle ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(selectedBillingCycle == cycle ? SafeEatTheme.primarySoft : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Computed Properties

    /// 按 sortOrder 排序的付费套餐列表（Lite -> Pro -> Premium）
    private var sortedPaidPlans: [MembershipPlan] {
        filteredPlans
            .filter { $0.tier != "free" }
            .sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
    }

    private var filteredPlans: [MembershipPlan] {
        store.membershipPlans.filter { $0.billingCycle == selectedBillingCycle }
    }

    private var selectedPlan: MembershipPlan? {
        store.membershipPlans.first(where: { $0.id == selectedPlanID })
    }

    // MARK: - Purchase Button Text

    private var purchaseButtonText: String {
        if store.isPurchasingMembership || creatingOrder {
            return SafeEatL10n.text(L10nKey.Membership.purchasing)
        }

        if let plan = store.membershipPlans.first(where: { $0.id == selectedPlanID }),
           let product = storeKitProduct(for: plan) {
            let bonusDays = totalBonusDays(for: plan)
            if bonusDays > 0 {
                return SafeEatL10n.format(L10nKey.Membership.buyNowWithBonus, bonusDays)
            }
            return SafeEatL10n.format(L10nKey.Membership.subscribeWithPrice, product.displayPrice)
        }

        return SafeEatL10n.text(L10nKey.Membership.createOrder)
    }

    // MARK: - Price Display

    private func displayPrice(for plan: MembershipPlan) -> String {
        if let product = storeKitProduct(for: plan) {
            return product.displayPrice
        }
        return SafeEatTheme.priceText(plan.priceFen)
    }

    private func storeKitProduct(for plan: MembershipPlan) -> Product? {
        if let appleId = plan.appleProductId {
            return store.membershipProducts.first { $0.id == appleId }
        }
        return store.membershipProducts.first { product in
            MembershipProductID.planTier(from: product.id) == plan.tier
            && MembershipProductID.billingCycle(from: product.id) == plan.billingCycle
        }
    }

    // MARK: - Campaign Benefits

    private func campaignBenefitsForPlan(_ plan: MembershipPlan) -> [CampaignBenefit] {
        if let applicable = plan.applicableCampaigns, !applicable.isEmpty {
            return applicable
        }
        return store.campaignBenefits.filter { benefit in
            guard let targetPlans = benefit.targetPlanIds, !targetPlans.isEmpty else { return true }
            return targetPlans.contains(plan.id)
        }
    }

    private func campaignBenefitText(_ benefit: CampaignBenefit) -> String {
        if let days = benefit.bonusDays, days > 0 {
            return SafeEatL10n.format(L10nKey.Membership.campaignBonusDays, days)
        }
        if let quota = benefit.bonusRecognitionQuota, quota > 0 {
            return SafeEatL10n.format(L10nKey.Membership.campaignBonusQuota, quota)
        }
        if let aiQuota = benefit.bonusAiQuota, aiQuota > 0 {
            return SafeEatL10n.format(L10nKey.Membership.campaignBonusAiQuota, aiQuota)
        }
        return benefit.name
    }

    private func hasAnyBenefit(for plan: MembershipPlan) -> Bool {
        !campaignBenefitsForPlan(plan).isEmpty || hasAppleOffer(for: plan)
    }

    private func hasAppleOffer(for plan: MembershipPlan) -> Bool {
        guard let product = storeKitProduct(for: plan) else { return false }
        return product.subscription?.introductoryOffer != nil
    }

    private func appleOfferText(_ offer: Product.SubscriptionOffer) -> String {
        switch offer.paymentMode {
        case .freeTrial:
            let period: String
            switch offer.period.unit {
            case .day: period = offer.period.value == 1 ? "天" : "\(offer.period.value)天"
            case .week: period = offer.period.value == 1 ? "周" : "\(offer.period.value)周"
            case .month: period = offer.period.value == 1 ? "个月" : "\(offer.period.value)个月"
            case .year: period = offer.period.value == 1 ? "年" : "\(offer.period.value)年"
            @unknown default: period = ""
            }
            return "免费试用 \(period)"
        case .payUpFront:
            return "首期优惠"
        case .payAsYouGo:
            return "首期折扣"
        default:
            return "Apple 优惠"
        }
    }

    private func totalBonusDays(for plan: MembershipPlan) -> Int {
        campaignBenefitsForPlan(plan).reduce(0) { sum, benefit in
            sum + (benefit.bonusDays ?? 0)
        }
    }

    private func bonusSummaryText(for plan: MembershipPlan) -> String {
        var parts: [String] = []
        let days = totalBonusDays(for: plan)
        if days > 0 { parts.append("+\(days)天") }
        let quota = campaignBenefitsForPlan(plan).reduce(0) { $0 + ($1.bonusRecognitionQuota ?? 0) }
        if quota > 0 { parts.append("+\(quota)次识别") }
        let aiQuota = campaignBenefitsForPlan(plan).reduce(0) { $0 + ($1.bonusAiQuota ?? 0) }
        if aiQuota > 0 { parts.append("+\(aiQuota)次AI") }
        return parts.joined(separator: "，")
    }

    // MARK: - Plan Helpers

    private func planBadge(for plan: MembershipPlan) -> String {
        switch plan.tier {
        case "lite":
            return SafeEatL10n.text(L10nKey.Membership.badgeLite)
        case "premium":
            return SafeEatL10n.text(L10nKey.Membership.badgePremium)
        default:
            return SafeEatL10n.text(L10nKey.Membership.badgeDefault)
        }
    }

    private func planBadgeColor(for plan: MembershipPlan) -> Color {
        switch plan.tier {
        case "lite":
            return SafeEatTheme.primary
        case "premium":
            return Color.purple
        default:
            return SafeEatTheme.textSecondary
        }
    }

    // MARK: - Countdown

    private var earliestCampaignCountdown: TimeInterval? {
        let deadlines = store.campaignBenefits.compactMap { $0.endsAt }
        guard let earliest = deadlines.min(), earliest > now else { return nil }
        return earliest.timeIntervalSince(now)
    }

    private func countdownText(from interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Data Loading

    private func loadPlans() async {
        guard store.membershipPlans.isEmpty else {
            selectedPlanID = sortedPaidPlans.first?.id
            return
        }

        loadingPlans = true
        defer { loadingPlans = false }

        await store.loadPlansWithCampaigns()

        if store.membershipPlans.isEmpty {
            plansLoadError = SafeEatL10n.text(L10nKey.Membership.plansLoadError)
        } else {
            selectedPlanID = sortedPaidPlans.first?.id
        }

        await store.loadMembershipProducts()

        if store.session != nil {
            await store.loadMembershipStatus()
        }
    }

    // MARK: - Purchase Logic

    private func purchase() async {
        guard let selectedPlanID else { return }

        // Apple IAP 购买
        guard let plan = store.membershipPlans.first(where: { $0.id == selectedPlanID }),
              let product = storeKitProduct(for: plan) else {
            store.purchaseError = SafeEatL10n.text(L10nKey.Membership.productNotReady)
            return
        }

        await store.purchaseMembership(product: product, planId: plan.id)

        if store.purchaseError == nil && !store.isPurchasingMembership {
            successMessage = SafeEatL10n.text(L10nKey.Membership.purchaseSuccess)
        }
    }
}