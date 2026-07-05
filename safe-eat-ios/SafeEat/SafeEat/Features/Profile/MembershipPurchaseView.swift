import Combine
import SwiftUI
import StoreKit

struct MembershipPurchaseView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedPlanID: String?
    @State private var benefitsPlan: BenefitsPlanWrapper?
    @State private var selectedBillingCycle = "monthly"
    @State private var loadingPlans = false
    @State private var creatingOrder = false
    @State private var successMessage: String?
    @State private var plansLoadError: String?
    @State private var showPriceBreakdownSheet = false
    @State private var showTrialPrompt = false
    @State private var showPurchaseConfirmSheet = false
    @State private var agreedToPurchaseTerms = false
    @State private var activatingTrial = false
    /// T9：是否正在轮询确认购买状态（控制 loading 遮罩）
    @State private var isPollingVerifyStatus = false
    /// T9：用户点"取消等待"时为 true，解除 loading 但不中止 Apple 交易
    @State private var didCancelWaiting = false
    /// T11：当前选中方案相对当前订阅的升级类型（决定文案）
    @State private var pendingUpgradeKind: UpgradeKind? = nil

    /// T11：升级类型
    enum UpgradeKind {
        case crossLevel      // 跨 Level 升级（Lite→Pro / Pro→Premium）
        case sameLevelCycle  // 同 Level 月/年切换（Pro 月↔Pro 年）
    }

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

                // 自动续费协议勾选
                purchaseTermsRow

                // 购买/订阅按钮
                ProfilePrimaryActionButton(
                    title: purchaseButtonText,
                    isLoading: creatingOrder || store.isPurchasingMembership,
                    isDisabled: selectedPlanID == nil || !agreedToPurchaseTerms
                ) {
                    if store.trialAvailable {
                        showTrialPrompt = true
                    } else {
                        showPurchaseConfirmSheet = true
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
        // R1-1: purchaseError 绑 alert，超时/failed 都提示用户（之前 onChange 是空闭包，用户看不到）
        .alert(SafeEatL10n.text(L10nKey.Membership.noticeTitle), isPresented: Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) {
                store.purchaseError = nil
            }
        } message: {
            Text(store.purchaseError ?? "")
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
        .sheet(item: $benefitsPlan) {
            benefitsDetailSheet(for: $0.plan)
        }
        // T9：购买确认期间全屏 loading 遮罩 + 禁交互
        // 注：iOS 17 无标准 API 禁 swipeBack，overlay 全屏覆盖 + disabled 已最大限度阻挡；
        // 即使加载期间用户滑动返回，AppStore 轮询 Task 仍在单例上运行，最终一致
        .overlay {
            if store.isPurchasingMembership || isPollingVerifyStatus {
                PurchaseLoadingOverlay {
                    // 用户点"取消等待"：解除本地 loading，不中止 Apple 交易
                    // R2-1: 不再写 store.isPurchasingMembership（由 AppStore.purchaseMembership 的 defer 复位）
                    isPollingVerifyStatus = false
                    didCancelWaiting = true
                }
            }
        }
        .disabled(store.isPurchasingMembership || isPollingVerifyStatus)
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
                    Button(SafeEatL10n.text(L10nKey.Common.retry)) {
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
        let downgrade = isDowngrade(plan)
        let currentExact = isCurrentExactPlan(plan)
        let isSelected = selectedPlanID == plan.id

        return ProfileSurfaceCard {
            HStack(alignment: .center, spacing: 12) {
                // 选择圆圈
                Button {
                    if isSelected {
                        selectedPlanID = nil
                    } else {
                        selectedPlanID = plan.id
                    }
                } label: {
                    let imageName = (downgrade || currentExact) ? "minus.circle"
                        : isSelected ? "checkmark.circle.fill" : "circle"
                    Image(systemName: imageName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .disabled(downgrade || currentExact)

                // 卡片内容（展开权益详情）
                Button {
                    benefitsPlan = BenefitsPlanWrapper(plan: plan)
                } label: {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            // 名称行：tier 名 + 当前标签
                            HStack(spacing: 8) {
                                Text(PlanTierMapper.title(plan.tier))
                                    .font(SafeEatFont.textStyle(.headline))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                                    .lineLimit(1)

                                if isCurrentPlan(plan) {
                                    Text(SafeEatL10n.text(L10nKey.Membership.currentPlanBadge))
                                        .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(SafeEatTheme.textSecondary.opacity(0.12))
                                        )
                                }
                            }

                            // 动态权益展示
                            planBenefitsView(plan)

                            // 试用标签 + 扣费提示
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

                            // 周期标签
                            Text(plan.billingCycle == "yearly"
                                 ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
                                 : SafeEatL10n.text(L10nKey.Membership.cycleMonthly))
                                .font(SafeEatFont.custom(12, relativeTo: .caption))
                                .foregroundStyle(SafeEatTheme.textSecondary)

                            // 价格
                            Text(displayPrice(for: plan))
                                .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

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
    }

    // MARK: - 动态权益展示

    /// 优先使用后端 benefitsDescription，降级使用本地额度文案
    private func planBenefitsView(_ plan: MembershipPlan) -> some View {
        Group {
            if let desc = plan.benefitsDescription, !desc.isEmpty {
                // 后端动态权益描述
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(desc.split(separator: "\n"), id: \.self) { line in
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(SafeEatFont.custom(9, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.primary)
                                .padding(.top, 3)
                            Text(String(line))
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            } else {
                // 降级：本地额度文案
                VStack(alignment: .leading, spacing: 4) {
                    if let quota = plan.recognitionQuotaMonthly {
                        benefitRow(SafeEatL10n.format(L10nKey.Membership.benefitRecognitionMonthly, quota))
                    }
                    if let aiQuota = plan.aiQuotaMonthly {
                        benefitRow(SafeEatL10n.format(L10nKey.Membership.benefitAiMonthly, aiQuota))
                    }
                    if let daily = plan.dailyQuota, daily > 0 {
                        benefitRow(SafeEatL10n.format(L10nKey.Membership.benefitDailyQuota, daily))
                    }
                    if let level = plan.aiAdviceLevel, !level.isEmpty {
                        benefitRow(SafeEatL10n.format(L10nKey.Membership.benefitAiAdviceLevel, AiAdviceLevelMapper.title(level)))
                    }
                    if let profiles = plan.maxHealthProfiles, profiles > 0 {
                        benefitRow(SafeEatL10n.format(L10nKey.Membership.benefitMaxHealthProfiles, profiles))
                    }
                    if let limit = plan.maxHistoryRecords {
                        benefitRow(limit == -1
                            ? SafeEatL10n.text(L10nKey.Membership.benefitHistoryLimitUnlimited)
                            : SafeEatL10n.format(L10nKey.Membership.benefitHistoryLimit, limit))
                    }
                }
            }
        }
    }

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "star.fill")
                .font(SafeEatFont.custom(9, relativeTo: .caption2))
                .foregroundStyle(SafeEatTheme.primary)
                .padding(.top, 3)
            Text(text)
                .font(SafeEatFont.textStyle(.footnote))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Membership.priceBreakdownTitle),
            subtitle: nil,
            contentHeight: 282,
            secondaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.cancel)) {
                showPriceBreakdownSheet = false
            }
        ) {
            ProfileSurfaceCard {
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
            }
        }
    }

    // MARK: - Trial Prompt Sheet

    private var trialPromptSheet: some View {
        SafeEatSettingsSheetContainer(
            title: "体验 Premium 会员",
            subtitle: "免费体验3天最高等级会员，享受全部功能",
            contentHeight: 160,
            primaryButton: SheetButton(title: "立即体验") {
                showTrialPrompt = false
                Task { await activateTrial() }
            },
            secondaryButton: SheetButton(title: "稍后使用") {
                showTrialPrompt = false
                showPurchaseConfirmSheet = true
            }
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.primary.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.warning)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("3天 Premium 体验")
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text("全部功能解锁，到期自动降级")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }

                    Text("体验结束后可随时购买正式会员")
                        .font(SafeEatFont.textStyle(.caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
        }
    }

    private func activateTrial() async {
        activatingTrial = true
        do {
            _ = try await store.activateTrialMembership()
            successMessage = "体验会员已激活，畅享3天 Premium！"
        } catch {
            // 激活失败，继续正常购买流程
            showPurchaseConfirmSheet = true
        }
        activatingTrial = false
    }

    // MARK: - Purchase Confirm Sheet（付款折扣展示）

    private func purchaseConfirmSheet(for plan: MembershipPlan) -> some View {
        let cycleTitle = plan.billingCycle == "yearly"
            ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
            : SafeEatL10n.text(L10nKey.Membership.cycleMonthly)

        return SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Membership.confirmSheetTitle),
            subtitle: "\(PlanTierMapper.title(plan.tier)) \(cycleTitle)",
            contentHeight: 340,
            primaryButton: SheetButton(
                title: SafeEatL10n.format(L10nKey.Membership.confirmPayButton, displayPrice(for: plan)),
                isLoading: creatingOrder || store.isPurchasingMembership
            ) {
                showPurchaseConfirmSheet = false
                Task { await purchase() }
            },
            secondaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.cancel)) {
                showPurchaseConfirmSheet = false
            }
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    // T11：升级/切换文案（按 Level 是否跨级区分）
                    if let kind = upgradeKind(for: plan) {
                        upgradeKindNoticeView(kind: kind)
                    }

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

                    // 最终价格提示
                    Text(SafeEatL10n.text(L10nKey.Membership.confirmFinalPriceHint))
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    // 合规提示区
                    Divider().overlay(SafeEatTheme.line)

                    VStack(alignment: .leading, spacing: 8) {
                        // 免费试用说明（仅含试用优惠时显示）
                        if let product = storeKitProduct(for: plan),
                           let intro = product.subscription?.introductoryOffer,
                           intro.paymentMode == .freeTrial {
                            HStack(spacing: 6) {
                                Image(systemName: "gift.fill")
                                    .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                    .foregroundStyle(SafeEatTheme.primary)
                                Text(SafeEatL10n.format(L10nKey.Membership.confirmTrialInfo, trialDays(for: intro)))
                                    .font(SafeEatFont.custom(12, relativeTo: .caption2))
                                    .foregroundStyle(SafeEatTheme.primary)
                            }
                        }

                        // 自动续费提示
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Text(SafeEatL10n.text(L10nKey.Membership.confirmAutoRenewal))
                                .font(SafeEatFont.custom(12, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }

                        // 取消路径提示
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Text(SafeEatL10n.text(L10nKey.Membership.confirmCancelPath))
                                .font(SafeEatFont.custom(12, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Benefits Detail Sheet

    private func benefitsDetailSheet(for plan: MembershipPlan) -> some View {
        let cycleTitle = plan.billingCycle == "yearly"
            ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
            : SafeEatL10n.text(L10nKey.Membership.cycleMonthly)
        let canSelect = !isDowngrade(plan) && !isCurrentExactPlan(plan)

        return SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Membership.detailNavTitle),
            subtitle: "\(PlanTierMapper.title(plan.tier)) \(cycleTitle)",
            contentHeight: nil,
            primaryButton: canSelect ? SheetButton(title: SafeEatL10n.text(L10nKey.Membership.selectPlan)) {
                selectedPlanID = plan.id
                benefitsPlan = nil
            } : nil,
            secondaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.cancel)) {
                benefitsPlan = nil
            }
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    // 月识别额度
                    if let quota = plan.recognitionQuotaMonthly {
                        HStack {
                            Label(SafeEatL10n.text(L10nKey.Membership.detailRecognitionMonthlyLabel), systemImage: "camera.viewfinder")
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Spacer()
                            Text(SafeEatL10n.format(L10nKey.Membership.detailCountFormat, quota))
                                .bold()
                        }
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                    }

                    // AI 建议等级
                    if let level = plan.aiAdviceLevel, !level.isEmpty {
                        HStack {
                            Label(SafeEatL10n.text(L10nKey.Membership.detailAiAdviceLevelLabel), systemImage: "brain.head.profile")
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Spacer()
                            Text(AiAdviceLevelMapper.title(level))
                                .bold()
                        }
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                    }

                    // 最大健康档案数
                    if let profiles = plan.maxHealthProfiles, profiles > 0 {
                        HStack {
                            Label(SafeEatL10n.text(L10nKey.Membership.detailHealthProfilesLabel), systemImage: "person.2")
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Spacer()
                            Text(SafeEatL10n.format(L10nKey.Membership.detailHealthProfilesFormat, profiles))
                                .bold()
                        }
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                    }

                    // 历史记录限制
                    if let limit = plan.maxHistoryRecords {
                        HStack {
                            Label(SafeEatL10n.text(L10nKey.Membership.detailHistoryLabel), systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Spacer()
                            Text(limit == -1
                                ? SafeEatL10n.text(L10nKey.Membership.detailHistoryUnlimited)
                                : SafeEatL10n.format(L10nKey.Membership.detailHistoryCountFormat, limit))
                                .bold()
                        }
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                    }

                    // 权益描述
                    if let desc = plan.benefitsDescription, !desc.isEmpty {
                        Divider().overlay(SafeEatTheme.line)

                        Text(SafeEatL10n.text(L10nKey.Membership.detailBenefitsTitle))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(desc.split(separator: "\n"), id: \.self) { line in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                        .foregroundStyle(SafeEatTheme.primary)
                                    Text(String(line))
                                        .font(SafeEatFont.textStyle(.footnote))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Billing Cycle Picker

    private var billingCyclePicker: some View {
        HStack(spacing: 0) {
            ForEach(["monthly", "yearly"], id: \.self) { cycle in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedBillingCycle = cycle
                        selectedPlanID = firstUpgradePlan?.id
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

    /// 按 sortOrder 排序的付费套餐列表，显示所有付费方案，当前等级及以下标记为不可选
    private var sortedPaidPlans: [MembershipPlan] {
        return filteredPlans
            .filter { plan in
                plan.tier != "free"
            }
            .sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) }
    }

    /// 判断某方案是否为降级（当前等级高于该方案）
    /// 同 tier 不同 billingCycle 不算降级（Pro 月卡可选 Pro 年卡）
    private func isDowngrade(_ plan: MembershipPlan) -> Bool {
        let currentTier = store.profile?.currentPlanTier ?? "free"
        return tierOrder(plan.tier) < tierOrder(currentTier)
    }

    // MARK: - T11 升级类型判定 + 文案

    /// 判定当前选中方案相对当前订阅的升级类型
    /// - 跨 Level（tier 不同）：crossLevel
    /// - 同 Level 月/年切换（tier 同 + cycle 不同）：sameLevelCycle
    /// - 同 tier 同 cycle（重新点同一产品）：返回 nil，不显示文案
    /// - R1-6: currentTier == "free"（新用户首购）返回 nil，不显示"原套餐退款"升级专属文案
    private func upgradeKind(for plan: MembershipPlan) -> UpgradeKind? {
        let currentTier = store.profile?.currentPlanTier ?? "free"
        // R1-6: free 用户首购，没有"原套餐"可退，不显示升级专属文案
        if currentTier == "free" {
            return nil
        }
        if plan.tier != currentTier {
            return .crossLevel
        }
        // tier 相同：看 cycle 是否不同
        if let currentCycle = store.membershipStatus?.billingCycle,
           plan.billingCycle != currentCycle {
            return .sameLevelCycle
        }
        return nil
    }

    private func upgradeKindNoticeView(kind: UpgradeKind) -> some View {
        let text: String
        let icon: String
        let color: Color
        switch kind {
        case .crossLevel:
            text = "升级高阶会员将全额扣除套餐费用，原套餐未使用时长按比例原路退款，权益立即生效"
            icon = "arrow.up.circle.fill"
            color = SafeEatTheme.primary
        case .sameLevelCycle:
            text = "同权限时长切换，本期会员时长不变，新套餐将于当前会员到期后生效"
            icon = "arrow.triangle.2.circlepath.circle.fill"
            color = SafeEatTheme.accent
        }

        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .padding(.top, 2)
            Text(text)
                .font(SafeEatFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.10))
        )
    }

    /// 判断某方案是否为当前精确订阅（tier + billingCycle 完全匹配）
    /// 当前精确订阅的圆圈不可点击（已订阅，无需再选）
    private func isCurrentExactPlan(_ plan: MembershipPlan) -> Bool {
        let currentTier = store.profile?.currentPlanTier ?? "free"
        guard plan.tier == currentTier else { return false }
        if let cycle = store.membershipStatus?.billingCycle {
            return plan.billingCycle == cycle
        }
        return true
    }

    /// 判断某方案是否为当前会员等级（区分月卡年卡）
    private func isCurrentPlan(_ plan: MembershipPlan) -> Bool {
        let currentTier = store.profile?.currentPlanTier ?? "free"
        guard plan.tier == currentTier else { return false }
        if let cycle = store.membershipStatus?.billingCycle {
            return plan.billingCycle == cycle
        }
        return true
    }

    /// tier 排序：free=0, lite=1, pro=2, premium=3
    private func tierOrder(_ tier: String) -> Int {
        switch tier {
        case "free", nil: return 0
        case "lite": return 1
        case "pro": return 2
        case "premium": return 3
        default: return 0
        }
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

    private func trialDays(for offer: Product.SubscriptionOffer) -> Int {
        switch offer.period.unit {
        case .day: return offer.period.value
        case .week: return offer.period.value * 7
        case .month: return offer.period.value * 30
        case .year: return offer.period.value * 365
        @unknown default: return offer.period.value
        }
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
        if days > 0 { parts.append(SafeEatL10n.format(L10nKey.Membership.bonusDaysFormat, days)) }
        let quota = campaignBenefitsForPlan(plan).reduce(0) { $0 + ($1.bonusRecognitionQuota ?? 0) }
        if quota > 0 { parts.append(SafeEatL10n.format(L10nKey.Membership.bonusRecognitionFormat, quota)) }
        let aiQuota = campaignBenefitsForPlan(plan).reduce(0) { $0 + ($1.bonusAiQuota ?? 0) }
        if aiQuota > 0 { parts.append(SafeEatL10n.format(L10nKey.Membership.bonusAiFormat, aiQuota)) }
        let sep = SafeEatL10n.text(L10nKey.Membership.bonusSeparator)
        return parts.joined(separator: sep)
    }

    // MARK: - Plan Helpers

    /// 第一个可购买的方案（排除降级和当前精确订阅）
    private var firstUpgradePlan: MembershipPlan? {
        sortedPaidPlans.first { !isDowngrade($0) && !isCurrentExactPlan($0) }
    }

    // MARK: - Data Loading

    private func loadPlans() async {
        guard store.membershipPlans.isEmpty else {
            selectedPlanID = firstUpgradePlan?.id
            return
        }

        loadingPlans = true
        defer { loadingPlans = false }

        await store.loadPlansWithCampaigns()

        if store.membershipPlans.isEmpty {
            plansLoadError = SafeEatL10n.text(L10nKey.Membership.plansLoadError)
        } else {
            selectedPlanID = firstUpgradePlan?.id
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

        didCancelWaiting = false
        let result = await store.purchaseMembership(product: product, planId: plan.id)

        // T8：根据结果决定 UI 反馈（不再只看 purchaseError==nil）
        switch result {
        case .purchased(let transactionId):
            // T9：进入轮询确认阶段
            // R2-1: 不写 store.isPurchasingMembership（defer 已复位为 false）。
            // 这里 isPurchasingMembership 会自动变 false，overlay 由 isPollingVerifyStatus 继续撑住
            isPollingVerifyStatus = true

            let pollResult = await store.pollVerifyStatus(transactionId: transactionId)
            isPollingVerifyStatus = false

            // 用户已取消等待，不弹任何结果
            if didCancelWaiting { return }

            switch pollResult {
            case .activated:
                successMessage = SafeEatL10n.text(L10nKey.Membership.purchaseSuccess)
            case .expired:
                // 会员已生效但已过期（active=false）—— 不弹开通成功
                successMessage = SafeEatL10n.text(L10nKey.Membership.verifyFailed)
            case .timeout:
                store.purchaseError = "购买确认超时，请稍后下拉刷新会员页查看购买状态"
            case .failed(let error):
                store.purchaseError = error.localizedDescription
            }

        case .userCancelled:
            // T8：不弹任何东西（Apple 交易被用户取消）
            break

        case .pending:
            // Apple pending，等 Transaction.updates 异步补激活
            store.purchaseError = SafeEatL10n.text(L10nKey.Membership.purchasePending)

        case .failed:
            // purchaseError 已在 store 内设置
            break
        }
    }

    // 自动续费协议勾选
    @State private var showPurchaseDisclosure: DisclosureLink?

    private var purchaseTermsRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                agreedToPurchaseTerms.toggle()
            } label: {
                Image(systemName: agreedToPurchaseTerms ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(agreedToPurchaseTerms ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
            }
            .buttonStyle(.plain)

            purchaseTermsFlowText
                .font(SafeEatFont.custom(13, relativeTo: .caption))
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(item: $showPurchaseDisclosure) { link in
            NavigationStack {
                DisclosureDetailView(title: link.title, category: link.category)
            }
        }
    }

    private func termsLinkText(_ display: String, url: String) -> AttributedString {
        var attr = AttributedString(display)
        attr.foregroundColor = SafeEatTheme.primary
        attr.underlineStyle = .single
        attr.link = URL(string: url)
        return attr
    }

    private var purchaseTermsFlowText: some View {
        let va = SafeEatL10n.text(L10nKey.Terms.purchaseValueAdded)
        let ar = SafeEatL10n.text(L10nKey.Terms.purchaseAutoRenewal)

        return (
            Text(SafeEatL10n.text(L10nKey.Terms.purchasePrefix))
                .foregroundStyle(SafeEatTheme.textSecondary)
            + Text(termsLinkText(va, url: "safeeat://value_added_service_agreement"))
            + Text(SafeEatL10n.text(L10nKey.Terms.purchaseAnd))
                .foregroundStyle(SafeEatTheme.textSecondary)
            + Text(termsLinkText(ar, url: "safeeat://auto_renewal_notice"))
            + Text(SafeEatL10n.text(L10nKey.Terms.purchaseSuffix))
                .foregroundStyle(SafeEatTheme.textSecondary)
        )
        .environment(\.openURL, OpenURLAction { url in
            guard let host = url.host() else { return .discarded }
            let title = host == "value_added_service_agreement" ? va : ar
            showPurchaseDisclosure = DisclosureLink(category: host, title: title)
            return .handled
        })
    }
}

/// 用于 .sheet(item:) 的 Identifiable wrapper
private struct BenefitsPlanWrapper: Identifiable {
    let plan: MembershipPlan
    var id: String { plan.id }
}