import Combine
import SwiftUI
import StoreKit

struct MembershipPurchaseView: View {
    @EnvironmentObject private var store: AppStore

    @State private var plans: [MembershipPlan] = []
    @State private var selectedPlanID: String?
    @State private var selectedChannel = "apple_iap"
    @State private var selectedBillingCycle = "monthly"
    @State private var loadingPlans = false
    @State private var creatingOrder = false
    @State private var successMessage: String?
    @State private var plansLoadError: String?
    @State private var now = Date()
    @State private var discountCodeInput = ""
    @State private var isRedeemingCode = false
    @State private var redeemCodeMessage: String?
    @State private var showDiscountDetailSheet = false
    @State private var showTrialPrompt = false

    private var memberStatus: MemberStatus {
        guard let tier = store.profile?.currentPlanTier, tier != "free" else {
            return .new
        }
        return .active
    }

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
            VStack(spacing: 12) {
                // 折扣明细展示区（淘宝式价格展示）
                if let plan = selectedPlan {
                    priceBreakdownSection(for: plan)
                }

                // 折扣码输入
                discountCodeSection

                // 购买/订阅按钮
                ProfilePrimaryActionButton(
                    title: purchaseButtonText,
                    isLoading: creatingOrder || store.isPurchasingMembership,
                    isDisabled: selectedPlanID == nil
                ) {
                    Task {
                        await purchase()
                    }
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
        .onChange(of: store.purchaseError) { newValue in
            // 购买失败或取消时，弹出试用提示
            if newValue != nil && memberStatus == .new {
                showTrialPrompt = true
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(SafeEatL10n.text(L10nKey.Membership.promo))
                    .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SafeEatTheme.primarySoft)
                    )

                // 限时优惠倒计时（参照原型 membership-countdown）
                if let countdown = earliestDiscountCountdown, countdown > 0 {
                    Text(SafeEatL10n.format(L10nKey.Membership.countdownFormat, countdownText(from: countdown)))
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(Color(red: 0.42, green: 0.25, blue: 0.08).opacity(0.72))
                }
            }

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
                        value: "\(highlightedPlan.localizedDisplayName) · \(SafeEatTheme.priceText(highlightedPlan.priceFen))"
                    )
                }
            }
        }
    }

    private var planListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SafeEatSectionHeader(title: SafeEatL10n.text(L10nKey.Membership.sectionPlans))
                Spacer()
                billingCyclePicker
            }

            // 加载错误提示
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
                        plans = []
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

            ForEach(filteredPlans) { plan in
                if plan.tier == "free" {
                    // Free 方案：信息卡片，不可选中
                    ProfileSurfaceCard {
                        HStack(alignment: .top, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 10) {
                                    Text(plan.localizedDisplayName)
                                        .font(SafeEatFont.textStyle(.headline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)

                                    Text(SafeEatL10n.text(L10nKey.Membership.badgeDefault))
                                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(SafeEatTheme.textSecondary.opacity(0.14))
                                        )
                                }

                                Text(SafeEatL10n.text(L10nKey.Membership.freePlanDescription))
                                    .font(SafeEatFont.textStyle(.caption))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            }

                            Spacer()

                            Text(SafeEatTheme.priceText(plan.priceFen))
                                .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)
                        }
                    }
                } else {
                    // 付费方案：可选中
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
                                // 折扣标签
                                if let discount = plan.appliedDiscount {
                                    Text(discount.name)
                                        .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.warning)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule()
                                                .fill(SafeEatTheme.warning.opacity(0.14))
                                        )
                                }

                                // 折扣价格
                                if let discountedPrice = plan.discountedPriceFen, discountedPrice < plan.priceFen {
                                    // 划线原价
                                    Text(displayPrice(for: plan, useOriginal: true))
                                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .regular))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                        .strikethrough()

                                    // 折扣后价格
                                    Text(displayPrice(for: plan, useOriginal: false))
                                        .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.warning)
                                } else {
                                    Text(displayPrice(for: plan, useOriginal: true))
                                        .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                }

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
    }

    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SafeEatSectionHeader(title: SafeEatL10n.text(L10nKey.Membership.sectionChannel))

            // 新会员首购优惠提示
            if memberStatus == .new {
                HStack(spacing: 6) {
                    Image(systemName: "gift")
                        .foregroundStyle(SafeEatTheme.warning)
                    Text(SafeEatL10n.text(L10nKey.Membership.newMemberOffer))
                        .font(SafeEatFont.textStyle(.caption))
                        .foregroundStyle(SafeEatTheme.warning)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SafeEatTheme.warning.opacity(0.08))
                )
            }

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
        filteredPlans
            .filter { $0.tier != "free" }
            .min(by: { $0.priceFen < $1.priceFen })
    }

    private var filteredPlans: [MembershipPlan] {
        plans.filter { $0.billingCycle == selectedBillingCycle }
    }

    private var billingCyclePicker: some View {
        HStack(spacing: 0) {
            ForEach(["monthly", "yearly"], id: \.self) { cycle in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedBillingCycle = cycle
                        selectedPlanID = filteredPlans.first?.id
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

    // MARK: - 购买按钮文案

    private var purchaseButtonText: String {
        if store.isPurchasingMembership || creatingOrder {
            return SafeEatL10n.text(L10nKey.Membership.purchasing)
        }

        if selectedChannel == "apple_iap",
           let plan = plans.first(where: { $0.id == selectedPlanID }),
           let product = storeKitProduct(for: plan) {
            return SafeEatL10n.format(L10nKey.Membership.subscribeWithPrice, product.displayPrice)
        }

        return SafeEatL10n.text(L10nKey.Membership.createOrder)
    }

    // MARK: - 价格展示（优先 StoreKit 真实价格）

    private func displayPrice(for plan: MembershipPlan, useOriginal: Bool) -> String {
        if let product = storeKitProduct(for: plan) {
            // Apple IAP 渠道：使用 StoreKit 真实价格
            if let discount = plan.appliedDiscount, !useOriginal,
               let discountedPrice = plan.discountedPriceFen, discountedPrice < plan.priceFen {
                return SafeEatTheme.priceText(discountedPrice)
            }
            return product.displayPrice
        }
        // 非 IAP 或 StoreKit 商品未加载：使用后端价格
        if !useOriginal, let discountedPrice = plan.discountedPriceFen, discountedPrice < plan.priceFen {
            return SafeEatTheme.priceText(discountedPrice)
        }
        return SafeEatTheme.priceText(plan.priceFen)
    }

    private func storeKitProduct(for plan: MembershipPlan) -> Product? {
        // 商品 ID 格式: com.bizeasylink.safeeat.membership.<billingCycle>.<planTier>
        // 匹配对应 billingCycle + planTier 的商品
        store.membershipProducts.first { product in
            MembershipProductID.planTier(from: product.id) == plan.tier
            && MembershipProductID.billingCycle(from: product.id) == plan.billingCycle
        }
    }

    // MARK: - 数据加载

    private func loadPlans() async {
        guard plans.isEmpty else { return }

        loadingPlans = true
        defer { loadingPlans = false }

        do {
            plans = try await store.api.getPlans()
            selectedPlanID = plans.first(where: { $0.tier != "free" })?.id ?? plans.first?.id
        } catch {
            #if DEBUG
            print("[MembershipPurchaseView] loadPlans failed: \(error)")
            #endif
            plansLoadError = error.localizedDescription
        }

        // 同时加载 StoreKit 商品
        await store.loadMembershipProducts()
    }

    // MARK: - 购买逻辑

    private func purchase() async {
        guard let selectedPlanID else { return }

        if selectedChannel == "apple_iap" {
            // Apple IAP 渠道：使用 StoreKit 2 购买
            guard let plan = plans.first(where: { $0.id == selectedPlanID }),
                  let product = storeKitProduct(for: plan) else {
                store.purchaseError = SafeEatL10n.text(L10nKey.Membership.productNotReady)
                return
            }

            await store.purchaseMembership(product: product, planId: plan.id, discountId: plan.appliedDiscount?.id)

            if store.purchaseError == nil && !store.isPurchasingMembership {
                successMessage = SafeEatL10n.text(L10nKey.Membership.purchaseSuccess)
            }
        } else {
            // 非 IAP 渠道：保留原有订单创建逻辑
            creatingOrder = true
            defer { creatingOrder = false }

            do {
                let order = try await store.createMembershipOrder(
                    planId: selectedPlanID,
                    channel: selectedChannel,
                    discountId: plans.first(where: { $0.id == selectedPlanID })?.appliedDiscount?.id
                )
                successMessage = SafeEatL10n.format(L10nKey.Membership.orderCreated, order.orderNo)
            } catch {
                store.errorMessage = error.localizedDescription
            }
        }
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

    // MARK: - 倒计时

    private var earliestDiscountCountdown: TimeInterval? {
        let deadlines = plans.compactMap { $0.appliedDiscount?.expiresAt }
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

    // MARK: - 选中方案

    private var selectedPlan: MembershipPlan? {
        plans.first(where: { $0.id == selectedPlanID })
    }

    // MARK: - 折扣明细展示区（淘宝式价格展示）

    private func priceBreakdownSection(for plan: MembershipPlan) -> some View {
        let hasDiscount = plan.discountedPriceFen != nil && plan.discountedPriceFen! < plan.priceFen

        return ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                // 原价
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.originalPrice))
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)

                    Spacer()

                    if hasDiscount {
                        Text(SafeEatTheme.priceText(plan.priceFen))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .strikethrough()
                    } else {
                        Text(SafeEatTheme.priceText(plan.priceFen))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    }
                }

                // 折扣项
                if hasDiscount {
                    // 自动折扣
                    if let discount = plan.appliedDiscount {
                        let discountAmount = plan.priceFen - (plan.discountedPriceFen ?? plan.priceFen)
                        HStack {
                            Text(discount.name)
                                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                                .foregroundStyle(SafeEatTheme.warning)

                            Spacer()

                            Text("-\(SafeEatTheme.priceText(discountAmount))")
                                .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.warning)
                        }
                    }

                    // 折扣码折扣
                    if let discounts = plan.availableDiscounts {
                        ForEach(discounts) { detail in
                            HStack {
                                Text(detail.name)
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                                    .foregroundStyle(SafeEatTheme.warning)

                                Spacer()

                                Text("-\(SafeEatTheme.priceText(detail.discountAmountFen))")
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.warning)
                            }
                        }
                    }

                    Divider().overlay(SafeEatTheme.line)

                    // 最终价格
                    HStack {
                        Text(SafeEatL10n.text(L10nKey.Membership.finalPrice))
                            .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Spacer()

                        Text(SafeEatTheme.priceText(plan.discountedPriceFen ?? plan.priceFen))
                            .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                }

                // 查看折扣明细按钮
                if hasDiscount {
                    Button {
                        showDiscountDetailSheet = true
                    } label: {
                        Text(SafeEatL10n.text(L10nKey.Membership.discountDetailTitle))
                            .font(SafeEatFont.custom(13, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showDiscountDetailSheet) {
            discountDetailSheet(for: plan)
        }
    }

    // MARK: - 折扣明细 Sheet

    private func discountDetailSheet(for plan: MembershipPlan) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 原价
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.originalPrice))
                    Spacer()
                    Text(SafeEatTheme.priceText(plan.priceFen))
                        .strikethrough()
                }
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

                Divider().overlay(SafeEatTheme.line)

                // 自动折扣
                if let discount = plan.appliedDiscount {
                    let discountAmount = plan.priceFen - (plan.discountedPriceFen ?? plan.priceFen)
                    HStack {
                        Text(discount.name)
                        Spacer()
                        Text("-\(SafeEatTheme.priceText(discountAmount))")
                    }
                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.warning)
                }

                // 折扣码折扣
                if let discounts = plan.availableDiscounts {
                    ForEach(discounts) { detail in
                        HStack {
                            Text(detail.name)
                            Spacer()
                            Text("-\(SafeEatTheme.priceText(detail.discountAmountFen))")
                        }
                        .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                        .foregroundStyle(SafeEatTheme.warning)
                    }
                }

                Divider().overlay(SafeEatTheme.line)

                // 最终价格
                HStack {
                    Text(SafeEatL10n.text(L10nKey.Membership.finalPrice))
                    Spacer()
                    Text(SafeEatTheme.priceText(plan.discountedPriceFen ?? plan.priceFen))
                }
                .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
            }
            .padding(20)
            .navigationTitle(SafeEatL10n.text(L10nKey.Membership.discountDetailTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SafeEatL10n.text(L10nKey.Common.cancel)) {
                        showDiscountDetailSheet = false
                    }
                }
            }
        }
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 折扣码输入

    private var discountCodeSection: some View {
        Group {
            HStack(spacing: 10) {
                TextField(SafeEatL10n.text(L10nKey.Membership.discountCodePlaceholder), text: $discountCodeInput)
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(SafeEatTheme.primarySoft)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(SafeEatTheme.line.opacity(0.12), lineWidth: 1)
                    )

                Button {
                    Task { await redeemDiscountCode() }
                } label: {
                    if isRedeemingCode {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 44, height: 44)
                    } else {
                        Text(SafeEatL10n.text(L10nKey.Membership.discountCodeConfirm))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(SafeEatTheme.primary)
                )
                .buttonStyle(.plain)
                .disabled(discountCodeInput.isEmpty || isRedeemingCode)
            }

            if let message = redeemCodeMessage {
                Text(message)
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(message.contains(SafeEatL10n.text(L10nKey.Membership.discountCodeSuccess)) ? SafeEatTheme.success : SafeEatTheme.danger)
                    .padding(.top, 4)
            }
        }
    }

    private func redeemDiscountCode() async {
        guard !discountCodeInput.isEmpty else { return }

        isRedeemingCode = true
        defer { isRedeemingCode = false }

        do {
            let result = try await store.authorizedRequest { token in
                try await store.api.redeemDiscountCode(accessToken: token, code: discountCodeInput)
            }
            if result.redeemed {
                redeemCodeMessage = SafeEatL10n.text(L10nKey.Membership.discountCodeSuccess)
                // 重新加载套餐以反映折扣码效果
                plans = []
                await loadPlans()
            }
        } catch {
            redeemCodeMessage = SafeEatL10n.text(L10nKey.Membership.discountCodeInvalid)
        }
    }

    // MARK: - 试用提示 Sheet

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
                // TODO: 调用试用码兑换 API
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
}
