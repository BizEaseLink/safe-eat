import SwiftUI

struct ResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: AppStore

    let itemId: LocalHistoryItem.ID

    @State private var isFlipped = false
    @State private var isLoadingDetail = false
    @State private var showFeedback = false
    @State private var showScoreLogicDetail = false
    @State private var showMembership = false
    @State private var showAiDisclaimer = false
    @State private var flipDirection: Double = -1
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedTab: ResultTab = .overview

    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    private var item: LocalHistoryItem? {
        store.historyItem(id: itemId)
    }

    private var recognition: RecognitionRecord? {
        item?.cachedRecognition ?? item?.fallbackRecognitionRecord()
    }

    private var hasFullRecognitionDetail: Bool {
        guard let recognition else { return false }
        return recognition.nutritionSnapshot != nil
            || recognition.nutritionMetrics != nil
            || !(recognition.healthImpacts?.isEmpty ?? true)
            || !(recognition.reasons?.isEmpty ?? true)
    }

    private var displayName: String {
        let rawName = recognition?.recognizedName ?? item?.recognizedName ?? ""
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "未知食物" {
            return SafeMealL10n.text(L10nKey.Common.unknownFood)
        }
        return trimmed
    }

    private var scoreValue: Int {
        recognition?.overallScore ?? recognition?.foodScore ?? item?.foodScore ?? 0
    }

    private var scoreTitle: String {
        switch scoreValue {
        case 80...:
            return SafeMealL10n.text(L10nKey.Result.scoreLevelHigh)
        case 60...:
            return SafeMealL10n.text(L10nKey.Result.scoreLevelMedium)
        default:
            return SafeMealL10n.text(L10nKey.Result.scoreLevelLow)
        }
    }

    private var scoreColor: Color {
        switch scoreValue {
        case 80...:
            return SafeMealTheme.primary
        case 60...:
            return SafeMealTheme.primary.opacity(0.8)
        default:
            return SafeMealTheme.warning
        }
    }

    private var statusText: String {
        if !hasFullRecognitionDetail {
            return SafeMealL10n.text(L10nKey.Result.statusInsufficient)
        }
        return AdviceLevelMapper.title(recognition?.adviceLevel ?? item?.adviceLevel)
    }

    private var statusColor: Color {
        if !hasFullRecognitionDetail {
            return colorScheme == .dark
                ? Color(red: 0.88, green: 0.76, blue: 0.53)
                : Color(red: 0.70, green: 0.55, blue: 0.22)
        }
        return AdviceLevelMapper.color(recognition?.adviceLevel ?? item?.adviceLevel)
    }

    private var frontSummaryText: String {
        if let advice = recognition?.adviceText,
           !advice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return advice
        }

        if !hasFullRecognitionDetail {
            return SafeMealL10n.text(L10nKey.Result.incompleteSummary)
        }

        return AdviceLevelMapper.menuSummary(
            level: recognition?.adviceLevel ?? item?.adviceLevel,
            adviceText: item?.adviceText
        )
    }

    private var backHeaderNote: String {
        SafeMealL10n.text(L10nKey.Result.headerNote)
    }

    private var scoreLogicText: String {
        SafeMealL10n.text(L10nKey.Result.scoreLogicBody)
    }

    private var pairedMetrics: [(String, String, String, String)] {
        let metrics = recognition?.effectiveNutrition
        let nutrients = metrics?.nutrients
        return [
            (
                SafeMealL10n.text(L10nKey.Result.metricCalories),
                formatMetric(nutrients?.calories.value),
                SafeMealL10n.text(L10nKey.Result.metricProtein),
                formatMetric(nutrients?.protein.value, unit: SafeMealL10n.text(L10nKey.Result.metricGramsUnit))
            ),
            (
                SafeMealL10n.text(L10nKey.Result.metricFat),
                formatMetric(nutrients?.fat.value, unit: SafeMealL10n.text(L10nKey.Result.metricGramsUnit)),
                SafeMealL10n.text(L10nKey.Result.metricCarbs),
                formatMetric(nutrients?.carbohydrates.value, unit: SafeMealL10n.text(L10nKey.Result.metricGramsUnit))
            ),
        ]
    }

    // Phase 8C: 推荐等级
    private var recommendation: RecommendationLevel {
        RecommendationLevel(rawValue: recognition?.recommendationLevel ?? "") ?? .neutral
    }

    // T6: 过敏原数据
    private var allergensData: (contains: [String], mayContain: [String])? {
        guard let allergens = recognition?.effectiveNutrition?.allergens else { return nil }
        let contains = allergens.contains
        let mayContain = allergens.mayContain
        if contains.isEmpty && mayContain.isEmpty { return nil }
        return (contains, mayContain)
    }

    // T8: 当前用户的 membership tier
    private var membershipTier: MembershipTier {
        MembershipTier(tierString: store.profile?.currentPlanTier)
    }

    // 付费墙包装器 — 支持三种状态：完全可见、部分露出、完全遮罩
    private func paywallWrapped<Content: View>(
        _ section: PaywallSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        // header 由 paywallWrapped 统一渲染：无论哪个 tier、有无数据，标题都稳定显示
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(sectionTitle(for: section), icon: sectionIcon(for: section))

            if section.isFullyVisible(for: membershipTier) {
                content()
            } else if section.isPartiallyRevealed(for: membershipTier) {
                // 部分露出：渲染内容 + 叠加渐变模糊遮罩
                ZStack(alignment: .bottom) {
                    content()
                    PaywallPartialRevealOverlay(onUpgrade: { showMembership = true })
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            } else {
                // 完全遮罩
                PaywallOverlayView(section: section) {
                    showMembership = true
                }
                .frame(height: 120)
            }
        }
    }

    private func sectionTitle(for section: PaywallSection) -> String {
        switch section {
        case .s1BasicNutrients: return SafeMealL10n.text(L10nKey.Result.sectionMacronutrients)
        case .s2DetailedNutrients: return SafeMealL10n.text(L10nKey.Result.sectionDetailedNutrients)
        case .s3Vitamins: return SafeMealL10n.text(L10nKey.Result.sectionVitamins)
        case .s4Minerals: return SafeMealL10n.text(L10nKey.Result.sectionMinerals)
        case .s5RiskFacts: return SafeMealL10n.text(L10nKey.Result.riskTitle)
        case .s6Glycemic: return SafeMealL10n.text(L10nKey.Result.sectionGlycemic)
        case .s7Allergens: return SafeMealL10n.text(L10nKey.Result.allergenTitle)
        case .s8Dietary: return SafeMealL10n.text(L10nKey.Result.sectionDietary)
        case .s9Preparation: return SafeMealL10n.text(L10nKey.Result.preparation)
        case .s10Ingredients: return SafeMealL10n.text(L10nKey.Result.sectionIngredients)
        case .s11AiAdvice: return SafeMealL10n.text(L10nKey.Result.aiAdviceTitle)
        }
    }

    private func sectionIcon(for section: PaywallSection) -> String {
        switch section {
        case .s1BasicNutrients: return "flame.fill"
        case .s2DetailedNutrients: return "chart.bar.fill"
        case .s3Vitamins: return "pill.fill"
        case .s4Minerals: return "hexagon.fill"
        case .s5RiskFacts: return "exclamationmark.triangle.fill"
        case .s6Glycemic: return "drop.fill"
        case .s7Allergens: return "exclamationmark.shield.fill"
        case .s8Dietary: return "leaf.fill"
        case .s9Preparation: return "frying.pan.fill"
        case .s10Ingredients: return "list.bullet.clipboard.fill"
        case .s11AiAdvice: return "sparkles"
        }
    }

    // Phase 8C: AI 建议（header 由 paywallWrapped 统一渲染；内部三档子块仍按 membershipTier 分级：
    // Summary Lite+、Detailed Pro+、HealthTips Premium。Free 完全遮罩）
    private var aiAdviceSectionContent: some View {
        Group {
            if let explanation = recognition?.aiExplanation {
                VStack(alignment: .leading, spacing: 12) {
                    // 摘要区（Lite+ 可见）
                    if let summary = aiSummaryText(for: explanation) {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label { Text(SafeMealL10n.text(L10nKey.Result.aiAdviceSummaryLabel)) } icon: { HugeIcon(sf: "text.quote", size: 14) }
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeMealTheme.primary)
                                Text(summary)
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // 详细建议区（Pro+ 可见）
                    if membershipTier >= .pro {
                        if let detailed = aiDetailedText(for: explanation) {
                            sectionCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label { Text(SafeMealL10n.text(L10nKey.Result.aiAdviceDetailedLabel)) } icon: { HugeIcon(sf: "doc.text.fill", size: 14) }
                                        .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(SafeMealTheme.primary)
                                    Text(detailed)
                                        .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                        .foregroundStyle(SafeMealTheme.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // 健康提示区（Premium 可见）
                    if membershipTier >= .premium {
                        if let tips = aiHealthTips(for: explanation), !tips.isEmpty {
                            sectionCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label { Text(SafeMealL10n.text(L10nKey.Result.healthTipsTitle)) } icon: { HugeIcon(sf: "heart.text.square.fill", size: 14) }
                                        .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(SafeMealTheme.success)
                                    ForEach(tips, id: \.self) { tip in
                                        HStack(alignment: .top, spacing: 8) {
                                            HugeIcon(glyph: .checkmarkCircle01, size: 16)
                                                .foregroundStyle(SafeMealTheme.success)
                                            Text(tip)
                                                .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                                .foregroundStyle(SafeMealTheme.textPrimary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                emptyDataCard
            }
        }
    }

    // Phase 8C: AI 建议区域（统一走 paywallWrapped：Free 完全遮罩，Lite+ 全可见）
    private var aiAdviceSection: some View {
        paywallWrapped(.s11AiAdvice) { aiAdviceSectionContent }
    }

    @State private var loadingTimeoutReached = false
    private let loadingTimeoutSeconds: Double = 10

    var body: some View {
        Group {
            if let item, let recognition {
                if isLoadingDetail && !hasFullRecognitionDetail && !loadingTimeoutReached {
                    fullScreenLoadingView
                        .task {
                            try? await Task.sleep(for: .seconds(loadingTimeoutSeconds))
                            loadingTimeoutReached = true
                        }
                } else {
                    resultPage(item: item, recognition: recognition)
                    .sheet(isPresented: $showFeedback) {
                        NavigationStack {
                            FeedbackView(recognition: recognition, historyItem: item)
                        }
                        .environmentObject(store)
                    }
                    .sheet(isPresented: $showMembership) {
                        MembershipPurchaseView()
                    }
                    .task(id: item.id) {
                        await loadDetailIfNeeded()
                    }
                    .onChange(of: hasFullRecognitionDetail) { _, newValue in
                        if isLoadingDetail, newValue {
                            isLoadingDetail = false
                        }
                    }
                }
            } else {
                missingState
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private var fullScreenLoadingView: some View {
        ZStack {
            pageBackground
            VStack(spacing: 24) {
                LottieLoadingContent(size: 160, text: SafeMealL10n.text(L10nKey.Result.detailSyncing))
            }
        }
    }

    private func resultPage(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            ZStack(alignment: .topLeading) {
                pageBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroSection(item: item)
                        detailSheet(item: item, recognition: recognition)
                        resultTabBar
                        resultTabContent(item: item, recognition: recognition)
                        bottomActionsSection(item: item, recognition: recognition)
                    }
                    .padding(.bottom, 40)
                    .background(DisableScrollBounce())
                }
                .ignoresSafeArea(edges: .top)

                // hero 左上返回浮钮（避开状态栏；收藏/分享隐藏）
                Button {
                    dismiss()
                } label: {
                    HugeIcon(glyph: .arrowLeft01, size: 20)
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
                .padding(.top, topInset + 8)
                .padding(.leading, 20)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            scrollOffset = 0
        }
    }

    // MARK: - P1 hero（原图满宽 + 黑渐变，底部圆角）
    private func heroSection(item: LocalHistoryItem) -> some View {
        ZStack {
            if let image = LocalImageLoader.loadOriginalImage(for: item) ?? LocalImageLoader.loadDisplayImage(for: item) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(SafeMealTheme.primarySoft.opacity(0.4))
                    .overlay(
                        HugeIcon(glyph: .image01, size: 28)
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    )
            }
            // 顶部轻渐变遮罩：仅从头部向下淡出，图片主体干净（保证状态栏/返回键可读）
            LinearGradient(
                stops: [
                    .init(color: Color.black.opacity(0.42), location: 0),
                    .init(color: Color.black.opacity(0.14), location: 0.3),
                    .init(color: .clear, location: 0.62),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        }
        .frame(height: 318)
        .frame(maxWidth: .infinity)
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 34,
                bottomTrailingRadius: 34,
                topTrailingRadius: 0
            )
        )
    }

    // MARK: - P1 上浮 sheet：食物名 + AI 摘要 + statbox
    private func detailSheet(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 食物名（3 行内自适应缩字号，超长省略；英文字号更小）+ 右上角建议徽章
            HStack(alignment: .center, spacing: 10) {
                Text(displayName)
                    .font(SafeMealFont.custom(SafeMealL10n.isZh ? 26 : 21, relativeTo: .title, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)
                    .lineLimit(3)
                    .minimumScaleFactor(SafeMealL10n.isZh ? 0.72 : 0.62)
                    .multilineTextAlignment(.leading)
                    .frame(minHeight: 68, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 6)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .advice }
                } label: {
                    recommendationBadge
                }
                .buttonStyle(.plain)
            }

            // AI 摘要（描述性，避免与建议徽章重复）
            Text(sheetSummaryText)
                .font(SafeMealFont.textStyle(.subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // statbox 三列（评分列可点击展开评分逻辑）
            HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showScoreLogicDetail.toggle()
                    }
                } label: {
                    statboxCell(
                        value: "\(scoreValue)",
                        label: SafeMealL10n.text(L10nKey.Result.scoreSectionTitle),
                        icon: "star.fill",
                        color: SafeMealTheme.warning
                    )
                }
                .buttonStyle(.plain)
                statboxDivider
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .nutrition }
                } label: {
                    statboxCell(
                        value: calorieText,
                        label: SafeMealL10n.text(L10nKey.Result.metricCalories),
                        icon: "flame.fill",
                        color: SafeMealTheme.warning,
                        unit: "kcal"
                    )
                }
                .buttonStyle(.plain)
                statboxDivider
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = .nutrition }
                } label: {
                    statboxCell(
                        value: proteinText,
                        label: SafeMealL10n.text(L10nKey.Result.metricProtein),
                        icon: "fork.knife",
                        color: SafeMealTheme.primary,
                        unit: "g"
                    )
                }
                .buttonStyle(.plain)
            }

            // 评分逻辑（默认隐藏，点评分展开；内容在 sheet 最下方）
            if showScoreLogicDetail {
                VStack(alignment: .leading, spacing: 12) {
                    Text(scoreLogicText)
                        .font(SafeMealFont.custom(13, relativeTo: .footnote))
                        .foregroundStyle(SafeMealTheme.textPrimary.opacity(0.90))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(scoreLogicFill)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    // 指标评分列表：Pro+ 可见
                    if membershipTier >= .pro {
                        if let impacts = recognition.metricImpacts, !impacts.isEmpty {
                            metricImpactsList(impacts)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(colorScheme == .dark ? Color(red: 0.16, green: 0.17, blue: 0.19) : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(SafeMealTheme.line.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.07), radius: 14, y: -5)
        .padding(.horizontal, 14)
        .padding(.top, -52) // 布局真上移：后续 tab 自动贴 sheet 底部
        .zIndex(2)
    }

    private var statboxDivider: some View {
        Rectangle()
            .fill(SafeMealTheme.line.opacity(0.5))
            .frame(width: 1, height: 40)
    }

    // sheet 右上角建议等级（大表情 + 下方文字，同色，无胶囊）
    private var recommendationBadge: some View {
        VStack(spacing: 2) {
            HugeIcon(glyph: .forAdviceLevel(recognition?.adviceLevel ?? item?.adviceLevel), size: 35)
            Text(statusText)
                .font(SafeMealFont.custom(12, relativeTo: .caption, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(recommendation.color)
    }

    private func statboxCell(value: String, label: String, icon: String, color: Color, unit: String = "") -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                HugeIcon(sf: icon, size: 15)
                    .foregroundStyle(color)
                Text(value)
                    .font(SafeMealFont.custom(16, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !unit.isEmpty {
                    Text(unit)
                        .font(SafeMealFont.textStyle(.caption))
                        .foregroundStyle(SafeMealTheme.textSecondary)
                }
            }
            Text(label)
                .font(SafeMealFont.textStyle(.caption))
                .foregroundStyle(SafeMealTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // sheet 摘要：优先 AI 描述性摘要（aiSummary），避免与「建议使用」徽章重复
    private var proteinText: String {
        let p = recognition?.effectiveNutrition?.nutrients?.protein.value
        if let p { return String(format: "%.1f", p) }
        return "--"
    }

    // sheet 摘要 = 一句话食用建议（adviceText / 档位句）——不用 AI 摘要，避免与「AI建议」tab 重复
    private var sheetSummaryText: String {
        // ① 后端针对性建议句（中文环境）
        if SafeMealL10n.isZh, let advice = recognition?.adviceText ?? item?.adviceText,
           !advice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return advice
        }
        // ② 本地化档位建议句（中英均有；英文环境 adviceText 无译，落这里）
        if !hasFullRecognitionDetail {
            return SafeMealL10n.text(L10nKey.Result.incompleteSummary)
        }
        return AdviceLevelMapper.menuSummary(level: recognition?.adviceLevel ?? item?.adviceLevel, adviceText: nil)
    }

    private var calorieText: String {
        let cal = recognition?.effectiveNutrition?.nutrients?.calories.value
        if let cal { return String(format: "%.0f", cal) }
        return "--"
    }

    // MARK: - P1 分段 tab
    private var resultTabBar: some View {
        HStack(spacing: 4) {
            tabButton(.overview, title: SafeMealL10n.text(L10nKey.Result.tabOverview))
            tabButton(.nutrition, title: SafeMealL10n.text(L10nKey.Result.tabNutrition))
            tabButton(.advice, title: SafeMealL10n.text(L10nKey.Result.tabAdvice))
        }
        .padding(4)
        .background(
            Capsule().fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color(red: 0.94, green: 0.95, blue: 0.955))
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func tabButton(_ tab: ResultTab, title: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            Text(title)
                .font(SafeMealFont.custom(12.5, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(selectedTab == tab ? SafeMealTheme.textPrimary : SafeMealTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Capsule().fill(selectedTab == tab
                        ? (colorScheme == .dark ? Color.white.opacity(0.10) : Color.white)
                        : Color.clear)
                )
                .shadow(color: selectedTab == tab ? Color.black.opacity(0.08) : Color.clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - P1 tab 内容
    @ViewBuilder
    private func resultTabContent(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        switch selectedTab {
        case .overview:
            overviewTab(item: item, recognition: recognition)
        case .nutrition:
            nutritionTab(recognition: recognition)
        case .advice:
            adviceTab(recognition: recognition)
        }
    }


    // MARK: - P1 评分/指标折叠卡（恢复之前 backCard 做法：展开折叠，Pro+ 见指标列表）
    private func scoreLogicCard(recognition: RecognitionRecord) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showScoreLogicDetail.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(SafeMealL10n.text(L10nKey.Result.scoreLogicTitle))
                            .font(SafeMealFont.custom(14, relativeTo: .subheadline))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                        Text(SafeMealL10n.format(L10nKey.Result.scoreLogicFormat, scoreValue))
                            .font(SafeMealFont.custom(26, relativeTo: .title2, weight: .bold))
                            .foregroundStyle(scoreColor)
                    }
                    Spacer(minLength: 10)
                    HugeIcon(sf: showScoreLogicDetail ? "chevron.up.circle.fill" : "chevron.down.circle.fill", size: 18)
                        .foregroundStyle(SafeMealTheme.textSecondary.opacity(0.84))
                }
                Text(SafeMealL10n.text(L10nKey.Result.scoreLogicHint))
                    .font(SafeMealFont.custom(13, relativeTo: .footnote))
                    .foregroundStyle(SafeMealTheme.textSecondary)
                if showScoreLogicDetail {
                    Text(scoreLogicText)
                        .font(SafeMealFont.custom(13, relativeTo: .footnote))
                        .foregroundStyle(SafeMealTheme.textPrimary.opacity(0.90))
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(scoreLogicFill)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    // 指标评分列表：Pro+ 可见，Free/Lite 不显示
                    if membershipTier >= .pro {
                        if let impacts = recognition.metricImpacts, !impacts.isEmpty {
                            metricImpactsList(impacts)
                        } else {
                            Text(SafeMealL10n.text(L10nKey.Result.emptyDataHint))
                                .font(SafeMealFont.textStyle(.subheadline))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                                .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionCardFill)
            .overlay(sectionCardStroke(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func overviewTab(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // 配料（外部标题，有数据显示）
            if hasIngredients(recognition) {
                sectionHeader(SafeMealL10n.text(L10nKey.Result.sectionIngredients), icon: "list.bullet")
                ingredientsSection(recognition: recognition)
            }

            // 做法（外部标题，有数据显示）
            if hasInstructions(recognition) {
                sectionHeader(SafeMealL10n.text(L10nKey.Result.sectionInstructions), icon: "list.number")
                instructionsSection(recognition: recognition)
            }

            // 过敏原（外部标题，含有/可能含有）
            if allergensData != nil {
                sectionHeader(SafeMealL10n.text(L10nKey.Result.allergenTitle), icon: "exclamationmark.shield.fill")
                allergenTagsSection
            }

            // 饮食标签（S8，paywallWrapped 自带外部标题）
            paywallWrapped(.s8Dietary) { dietaryInfoSection }

            // 饱腹感（外部标题，形象化占比）
            if recognition.effectiveNutrition?.nutrients != nil {
                sectionHeader(SafeMealL10n.text(L10nKey.Result.satietyTitle), icon: "fork.knife")
                satietyIndexSection
            }

            // 风险分析（无风险数据时连同标题一起消失，与配料/做法「有则显示」逻辑一致）
            if let risks = recognition.riskFacts, !risks.isEmpty {
                sectionHeader(SafeMealL10n.text(L10nKey.Result.riskSectionTitle), icon: "exclamationmark.triangle.fill")
                riskFactsSection(risks)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - P1 Ingredients 配料（有数据显示，无则隐藏）
    // 是否有配料数据（外部标题条件显示）
    private func hasIngredients(_ recognition: RecognitionRecord) -> Bool {
        let breakdown = recognition.nutritionMetrics?.ingredientBreakdown
        let plain = recognition.nutritionMetrics?.ingredients ?? []
        return !((breakdown?.compactMap { $0.name } ?? plain).isEmpty)
    }

    // 是否有做法数据
    private func hasInstructions(_ recognition: RecognitionRecord) -> Bool {
        let prep = recognition.nutritionMetrics?.preparation
        let stepsText = prep?.cookingSteps ?? prep?.cookingMethod
        return !(stepsText ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func ingredientsSection(recognition: RecognitionRecord) -> some View {
        let breakdown = recognition.nutritionMetrics?.ingredientBreakdown
        let plain = recognition.nutritionMetrics?.ingredients ?? []
        let names = breakdown?.compactMap { $0.name } ?? plain
        guard !names.isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                ForEach(names.prefix(12), id: \.self) { name in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SafeMealTheme.primary.opacity(0.14))
                            .frame(width: 6, height: 6)
                        Text(name)
                            .font(SafeMealFont.textStyle(.subheadline))
                            .foregroundStyle(SafeMealTheme.textPrimary)
                        Spacer()
                        if let amt = breakdown?.first(where: { $0.name == name })?.amount {
                            Text(amt)
                                .font(SafeMealFont.textStyle(.caption))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionCardFill)
            .overlay(sectionCardStroke(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    // MARK: - P1 Instructions / 做法步骤（有数据显示，无则隐藏）
    private func instructionsSection(recognition: RecognitionRecord) -> some View {
        let prep = recognition.nutritionMetrics?.preparation
        // 优先 cookingSteps（HTML Instructions 步骤式），回退 cookingMethod
        let stepsText = prep?.cookingSteps ?? prep?.cookingMethod
        let steps: [String] = (stepsText ?? "")
            .split(whereSeparator: { "\n；;。".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !steps.isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(steps.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(pair.offset + 1)")
                            .font(SafeMealFont.custom(12, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(SafeMealTheme.primary)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle().fill(SafeMealTheme.primary.opacity(0.12))
                            )
                        Text(pair.element)
                            .font(SafeMealFont.textStyle(.subheadline))
                            .foregroundStyle(SafeMealTheme.textPrimary.opacity(0.9))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionCardFill)
            .overlay(sectionCardStroke(cornerRadius: 24))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    private func nutritionTab(recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            paywallWrapped(.s1BasicNutrients) { basicNutrientsSection }
            paywallWrapped(.s3Vitamins) { vitaminsSection }
            paywallWrapped(.s4Minerals) { mineralsSection }
            paywallWrapped(.s6Glycemic) { glycemicSection }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private func adviceTab(recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            aiAdviceSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - P1 底部操作
    private func bottomActionsSection(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        VStack(spacing: 12) {
            HStack {
                inlineActionWithIcon(icon: "camera.rotate", title: SafeMealL10n.text(L10nKey.Result.actionRetake)) {
                    dismiss()
                }
                Spacer()
                inlineActionWithIcon(icon: "info.circle", title: SafeMealL10n.text(L10nKey.Result.actionFeedback)) {
                    showFeedback = true
                }
            }
            MembershipBannerView(tier: membershipTier, isFront: true, onUpgrade: { showMembership = true })
            medicalDisclaimerView
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var pageBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.12, green: 0.13, blue: 0.15),
                        Color(red: 0.09, green: 0.10, blue: 0.12),
                    ]
                    : [
                        Color(red: 0.99, green: 0.995, blue: 0.99),
                        Color(red: 0.965, green: 0.978, blue: 0.968),
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    SafeMealTheme.primarySoft.opacity(colorScheme == .dark ? 0.10 : 0.46),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 24,
                endRadius: 340
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.91, blue: 0.78).opacity(colorScheme == .dark ? 0.08 : 0.36),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 280
            )
        }
    }

    private func frontCard(item: LocalHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 8) {
                Text(SafeMealL10n.text(L10nKey.Result.title))
                    .font(SafeMealFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(displayName)
                        .font(SafeMealFont.custom(18, relativeTo: .title3, weight: .bold))
                        .foregroundStyle(SafeMealTheme.textPrimary)
                    if item.feedbackPending {
                        HugeIcon(glyph: .hourglass, size: 16)
                            .font(.caption2)
                            .foregroundStyle(SafeMealTheme.warning)
                    }
                }
            }
            heroImageCard(item: item)

            // C1: 大数字评分卡 + 快捷指标
            scoreCardSection

            // 宏量营养素标题行
            HStack {
                Spacer()
                Text(SafeMealL10n.text(L10nKey.Result.perServing))
                    .font(SafeMealFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeMealTheme.textSecondary)
            }

            quickMetricsGrid

            Text(frontSummaryText)
                .font(SafeMealFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeMealTheme.textPrimary.opacity(0.94))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // T6: 过敏原标签
            allergenTagsSection

            // T6: 饱腹感指数
            satietyIndexSection

            VStack(spacing: 12) {
                primaryButton(title: SafeMealL10n.text(L10nKey.Result.actionAnalysisDetail)) {
                    flipCard(direction: -1)
                }

                HStack {
                    inlineActionWithIcon(icon: "camera.rotate", title: SafeMealL10n.text(L10nKey.Result.actionRetake)) {
                        dismiss()
                    }

                    Spacer()

                    inlineActionWithIcon(icon: "info.circle", title: SafeMealL10n.text(L10nKey.Result.actionFeedback)) {
                        showFeedback = true
                    }
                }
            }

            medicalDisclaimerView
        }
        .padding(.top, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(flipGesture)
        .onTapGesture {
            flipCard(direction: -1)
        }
    }

    // C1: 大数字评分卡（替代圆环）
    private var scoreCardSection: some View {
        VStack(spacing: 12) {
            // 顶部 label
            Text(SafeMealL10n.text(L10nKey.Result.scoreSectionTitle))
                .font(SafeMealFont.custom(13, relativeTo: .footnote))
                .foregroundStyle(SafeMealTheme.textSecondary)

            // 大数字 + /100
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(scoreValue)")
                    .font(SafeMealFont.custom(64, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(scoreColor)
                Text("/100")
                    .font(SafeMealFont.custom(20, relativeTo: .headline))
                    .foregroundStyle(scoreColor.opacity(0.6))
            }

            // 建议等级标签
            statusChip(text: statusText, color: statusColor)
        }
        .frame(maxWidth: .infinity)
    }

    // C1: 快捷指标卡（3格 grid）
    private var quickMetricsGrid: some View {
        let metrics = recognition?.effectiveNutrition
        let nutrients = metrics?.nutrients
        let calValue: String = if let n = nutrients { String(format: "%.0f", n.calories.value) } else { "--" }
        let proValue: String = if let n = nutrients { String(format: "%.0f", n.protein.value) } else { "--" }
        let fatValue: String = if let n = nutrients { String(format: "%.1f", n.fat.value) } else { "--" }

        return HStack(spacing: 12) {
            // 脂肪
            quickMetricCard(
                title: SafeMealL10n.text(L10nKey.Result.metricFat),
                value: fatValue,
                unit: SafeMealL10n.text(L10nKey.Result.quickMetricFatUnit),
                color: fatColor(nutrients?.fat.value)
            )

            // 热量
            quickMetricCard(
                title: SafeMealL10n.text(L10nKey.Result.metricCalories),
                value: calValue,
                unit: SafeMealL10n.text(L10nKey.Result.quickMetricCaloriesUnit),
                color: calorieColor(nutrients?.calories.value)
            )

            // 蛋白质
            quickMetricCard(
                title: SafeMealL10n.text(L10nKey.Result.metricProtein),
                value: proValue,
                unit: SafeMealL10n.text(L10nKey.Result.quickMetricProteinUnit),
                color: proteinColor(nutrients?.protein.value)
            )
        }
    }

    private func quickMetricCard(title: String, value: String, unit: String? = nil, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(SafeMealFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeMealTheme.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(SafeMealFont.custom(20, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(color)
                if let unit = unit {
                    Text(unit)
                        .font(SafeMealFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(color.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.80))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line, lineWidth: 1)
                )
        )
    }

    private func bloodSugarLevelText(_ level: String?) -> String {
        guard let level = level?.lowercased() else { return "--" }
        switch level {
        case "low": return SafeMealL10n.text(L10nKey.Result.quickMetricGlycemicLow)
        case "medium": return SafeMealL10n.text(L10nKey.Result.quickMetricGlycemicMedium)
        case "high": return SafeMealL10n.text(L10nKey.Result.quickMetricGlycemicHigh)
        default: return "--"
        }
    }

    private func bloodSugarLevelColor(_ level: String?) -> Color {
        guard let level = level?.lowercased() else { return SafeMealTheme.textSecondary }
        switch level {
        case "low": return SafeMealTheme.success
        case "medium": return SafeMealTheme.warning
        case "high": return SafeMealTheme.danger
        default: return SafeMealTheme.textSecondary
        }
    }

    private func calorieColor(_ value: Double?) -> Color {
        guard let value = value else { return SafeMealTheme.textSecondary }
        if value < 200 { return SafeMealTheme.success }
        if value <= 500 { return SafeMealTheme.primary }
        return SafeMealTheme.warning
    }

    private func proteinColor(_ value: Double?) -> Color {
        guard let value = value else { return SafeMealTheme.textSecondary }
        if value < 10 { return SafeMealTheme.danger }
        if value <= 30 { return SafeMealTheme.success }
        return SafeMealTheme.primary
    }

    private func fatColor(_ value: Double?) -> Color {
        guard let value = value else { return SafeMealTheme.textSecondary }
        if value < 5 { return SafeMealTheme.success }
        if value <= 20 { return SafeMealTheme.primary }
        return SafeMealTheme.warning
    }

    // T6: 过敏原标签区
    private var allergenTagsSection: some View {
        Group {
            if let data = allergensData {
                VStack(alignment: .leading, spacing: 10) {
                    if !data.contains.isEmpty {
                        allergenRow(
                            label: SafeMealL10n.text(L10nKey.Result.allergenContains),
                            items: data.contains,
                            color: SafeMealTheme.danger
                        )
                    }

                    if !data.mayContain.isEmpty {
                        allergenRow(
                            label: SafeMealL10n.text(L10nKey.Result.allergenMayContain),
                            items: data.mayContain,
                            color: SafeMealTheme.warning
                        )
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 26))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
    }

    private func allergenRow(label: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SafeMealFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeMealTheme.textSecondary)
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(items, id: \.self) { item in
                    allergenChip(text: item, color: color, isDark: colorScheme == .dark)
                }
            }
        }
    }

    private func allergenChip(text: String, color: Color, isDark: Bool) -> some View {
        Text(localizedAllergenName(text))
            .font(SafeMealFont.custom(13, relativeTo: .footnote, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isDark ? Color.white.opacity(0.08) : Color(.systemGray5))
            .clipShape(Capsule())
    }

    // T6: 饱腹感指数
    private var satietyIndexSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients {
                let score = computeSatietyScore(nutrients: nutrients)
                VStack(alignment: .leading, spacing: 12) {
                    // 百分比大数字 + 标签
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f%%", score * 100))
                            .font(SafeMealFont.custom(28, relativeTo: .title2, weight: .bold))
                            .foregroundStyle(satietyColor(score: score))
                        Text(satietyLabel(score: score))
                            .font(SafeMealFont.custom(14, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(satietyColor(score: score))
                        Spacer()
                    }
                    // 形象化进度条（占比）
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(SafeMealTheme.line.opacity(0.3))
                            Capsule()
                                .fill(satietyColor(score: score))
                                .frame(width: max(8, geo.size.width * CGFloat(min(max(score, 0), 1))))
                        }
                    }
                    .frame(height: 8)
                    // 说明
                    Text(SafeMealL10n.text(L10nKey.Result.satietyTitle))
                        .font(SafeMealFont.textStyle(.caption))
                        .foregroundStyle(SafeMealTheme.textSecondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 26))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
        }
    }

    private func computeSatietyScore(nutrients: Nutrients) -> Double {
        // 基于 protein + dietaryFiber + fat 计算简易饱腹感评分 (0~1)
        let protein = nutrients.protein.value
        let fiber = nutrients.dietaryFiber?.value ?? 0
        let fat = nutrients.fat.value
        // 归一化：protein 0~30g, fiber 0~10g, fat 0~20g
        let proteinScore = min(protein / 30.0, 1.0) * 0.45
        let fiberScore = min(fiber / 10.0, 1.0) * 0.35
        let fatScore = min(fat / 20.0, 1.0) * 0.20
        return min(proteinScore + fiberScore + fatScore, 1.0)
    }

    private func satietyLabel(score: Double) -> String {
        switch score {
        case 0.6...: return SafeMealL10n.text(L10nKey.Result.satietyHigh)
        case 0.3..<0.6: return SafeMealL10n.text(L10nKey.Result.satietyMedium)
        default: return SafeMealL10n.text(L10nKey.Result.satietyLow)
        }
    }

    private func satietyColor(score: Double) -> Color {
        switch score {
        case 0.6...: return SafeMealTheme.success
        case 0.3..<0.6: return SafeMealTheme.primary
        default: return SafeMealTheme.warning
        }
    }

    private func satietyBar(score: Double) -> some View {
        let isDark = colorScheme == .dark
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isDark ? Color.white.opacity(0.08) : Color(.systemGray5))
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(satietyColor(score: score))
                    .frame(width: geo.size.width * CGFloat(score))
            }
        }
        .frame(height: 8)
        .frame(maxWidth: 120)
    }

    private func relativeTimeString(for date: Date?) -> String {
        guard let date else {
            return SafeMealL10n.text(L10nKey.Result.scannedNow)
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let result = formatter.localizedString(for: date, relativeTo: Date())
        return SafeMealL10n.format(L10nKey.Result.scannedRelativeFormat, result)
    }

    private func backCard(recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(backHeaderNote)
                    .font(SafeMealFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeMealTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    MiniScoreRingView(score: scoreValue, size: 64)
                        .frame(width: 64, height: 64)
                        .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(SafeMealFont.custom(16, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeMealTheme.textPrimary)
                        if item?.feedbackPending == true {
                            HStack(spacing: 2) {
                                HugeIcon(glyph: .hourglass, size: 16)
                                    .font(.caption2)
                                    .foregroundStyle(SafeMealTheme.warning)
                                Text(SafeMealL10n.text(L10nKey.Result.feedbackPending))
                                    .font(.caption2)
                                    .foregroundStyle(SafeMealTheme.warning)
                            }
                        }

                        Text(relativeTimeString(for: recognition.createdAt ?? item?.createdAt))
                            .font(SafeMealFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }

                Text(SafeMealL10n.text(L10nKey.Result.analysisTitle))
                    .font(SafeMealFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeMealTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isLoadingDetail && !hasFullRecognitionDetail {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(SafeMealTheme.primary)
                    Text(SafeMealL10n.text(L10nKey.Result.detailSyncing))
                        .font(SafeMealFont.textStyle(.caption))
                        .foregroundStyle(SafeMealTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if !hasFullRecognitionDetail {
                subtleChip(text: SafeMealL10n.text(L10nKey.Result.detailLocalOnly))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showScoreLogicDetail.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(SafeMealL10n.text(L10nKey.Result.scoreLogicTitle))
                                .font(SafeMealFont.custom(16, relativeTo: .subheadline))
                                .foregroundStyle(SafeMealTheme.textSecondary)

                            Text(SafeMealL10n.format(L10nKey.Result.scoreLogicFormat, scoreValue))
                                .font(SafeMealFont.custom(26, relativeTo: .title2, weight: .bold))
                                .foregroundStyle(scoreColor)
                        }

                        Spacer(minLength: 10)

                        HugeIcon(glyph: .helpCircle, size: 18)
                            .foregroundStyle(SafeMealTheme.textSecondary.opacity(0.84))
                    }

                    Text(SafeMealL10n.text(L10nKey.Result.scoreLogicHint))
                        .font(SafeMealFont.custom(13, relativeTo: .footnote))
                        .foregroundStyle(SafeMealTheme.textSecondary)

                    if showScoreLogicDetail {
                        Text(scoreLogicText)
                            .font(SafeMealFont.custom(13, relativeTo: .footnote))
                            .foregroundStyle(SafeMealTheme.textPrimary.opacity(0.90))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(scoreLogicFill)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        // 营养指标评分列表：Pro+ 可见，Free/Lite 不显示列表
                        if membershipTier >= .pro {
                            if let impacts = recognition.metricImpacts, !impacts.isEmpty {
                                metricImpactsList(impacts)
                            } else {
                                Text(SafeMealL10n.text(L10nKey.Result.emptyDataHint))
                                    .font(SafeMealFont.textStyle(.subheadline))
                                    .foregroundStyle(SafeMealTheme.textSecondary)
                                    .padding(.top, 8)
                            }
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 26))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            // ===== Free 档全可见 =====
            // S1 基础营养素（含膳食纤维：有值才显示）
            paywallWrapped(.s1BasicNutrients) { basicNutrientsSection }

            // S7 过敏原（安全信息，全档放开）
            paywallWrapped(.s7Allergens) { backAllergenSection }

            // S5 风险提示（静态规则不花钱，全档放开）
            paywallWrapped(.s5RiskFacts) {
                if let risks = recognition.riskFacts, !risks.isEmpty {
                    riskFactsSection(risks)
                } else {
                    emptyDataCard
                }
            }

            // ===== Lite 档起解锁 =====
            // S3 维生素
            paywallWrapped(.s3Vitamins) { vitaminsSection }

            // S4 矿物质
            paywallWrapped(.s4Minerals) { mineralsSection }

            // S6 血糖指数
            paywallWrapped(.s6Glycemic) { glycemicSection }

            // S11 AI 建议（Free 完全遮罩，Lite+ 全可见）
            aiAdviceSection

            // ===== Pro 档起解锁 =====
            // S8 饮食标签
            paywallWrapped(.s8Dietary) { dietaryInfoSection }

            // ===== 后台数据不完整，暂隐藏（枚举保留待恢复）=====
            // paywallWrapped(.s2DetailedNutrients) { detailedNutrientsSection }
            // paywallWrapped(.s9Preparation) { preparationSection }
            // paywallWrapped(.s10Ingredients) { ingredientBreakdownSection }

            // 会员引导横幅（背面底部）
            MembershipBannerView(tier: membershipTier, isFront: false, onUpgrade: { showMembership = true })

            VStack(spacing: 12) {
                primaryButton(title: SafeMealL10n.text(L10nKey.Result.actionBackToFront)) {
                    flipCard(direction: 1)
                }

                HStack {
                    inlineActionWithIcon(icon: "camera.rotate", title: SafeMealL10n.text(L10nKey.Result.actionRetake)) {
                        dismiss()
                    }

                    Spacer()

                    inlineActionWithIcon(icon: "info.circle", title: SafeMealL10n.text(L10nKey.Result.actionFeedback)) {
                        showFeedback = true
                    }
                }
            }

            medicalDisclaimerView
        }
        .padding(.top, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(flipGesture)
        .onTapGesture {
            flipCard(direction: 1)
        }
    }

    // Phase 8C: 营养指标列表（嵌入评分折叠卡）
    private func metricImpactsList(_ impacts: [MetricImpact]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SafeMealL10n.text(L10nKey.Result.metricTitle))
                .font(SafeMealFont.custom(14, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
                .padding(.top, 8)

            ForEach(impacts) { impact in
                HStack(spacing: 10) {
                    impactDirectionIcon(impact.impactDirection)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(SafeMealL10n.isZh ? (impact.label ?? impact.metric) : (impact.labelEn ?? impact.metric))
                            .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                            .foregroundStyle(SafeMealTheme.textPrimary)
                        if let weighted = impact.weightedScore {
                            Text(SafeMealL10n.format(L10nKey.Result.metricScoreFormat, Int(weighted)))
                                .font(SafeMealFont.custom(12, relativeTo: .caption))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    }
                    Spacer()
                    Text("\(impact.score)")
                        .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(impactScoreColor(impact.score))
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func impactDirectionIcon(_ direction: String?) -> some View {
        Group {
            switch direction {
            case "positive":
                HugeIcon(glyph: .circleArrowUp01, size: 16)
                    .foregroundStyle(SafeMealTheme.success)
            case "negative":
                HugeIcon(glyph: .circleArrowDown01, size: 16)
                    .foregroundStyle(SafeMealTheme.danger)
            default:
                HugeIcon(glyph: .minusSignCircle, size: 16)
                    .foregroundStyle(SafeMealTheme.textSecondary)
            }
        }
        .font(.system(size: 18))
    }

    private func impactScoreColor(_ score: Int) -> Color {
        if score >= 70 { return SafeMealTheme.success }
        if score >= 40 { return SafeMealTheme.warning }
        return SafeMealTheme.danger
    }

    // Phase 8C: 风险标签 section（header 由 paywallWrapped 统一渲染）
    private func riskFactsSection(_ risks: [RiskFact]) -> some View {
        let isZh = SafeMealL10n.isZh
        return sectionCard {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(risks) { risk in
                    HStack(spacing: 10) {
                        HugeIcon(sf: risk.severity == "danger" ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill", size: 16)
                            .foregroundStyle(risk.severity == "danger" ? SafeMealTheme.danger : SafeMealTheme.warning)
                            .font(.system(size: 18))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isZh ? (risk.label ?? risk.tag) : (risk.labelEn ?? risk.tag))
                                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                .foregroundStyle(SafeMealTheme.textPrimary)
                            let descText: String? = isZh ? risk.description : risk.descriptionEn
                            if let descText, !descText.isEmpty {
                                Text(descText)
                                    .font(SafeMealFont.custom(13, relativeTo: .caption))
                                    .foregroundStyle(SafeMealTheme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - T7: 背面 10 Section

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            HugeIcon(sf: icon, size: 18)
                .foregroundStyle(SafeMealTheme.primary)
            Text(title)
                .font(SafeMealFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
        }
    }

    /// 无 header 的空态卡（header 由 paywallWrapped 统一渲染）
    private var emptyDataCard: some View {
        sectionCard {
            Text(SafeMealL10n.text(L10nKey.Result.emptyDataHint))
                .font(SafeMealFont.textStyle(.subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)
        }
    }

    // S1: 基础营养素（header 由 paywallWrapped 统一渲染）
    private var basicNutrientsSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients {
                let hasData = nutrients.calories.value > 0 || nutrients.protein.value > 0 || nutrients.fat.value > 0 || nutrients.carbohydrates.value > 0 || nutrients.sodium != nil
                if hasData {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Text(SafeMealL10n.text(L10nKey.Result.per100gServing))
                                .font(SafeMealFont.custom(12, relativeTo: .caption))
                                .foregroundStyle(SafeMealTheme.textSecondary)                        }
                        // v4 NRV 计算依据标注
                        if let std = recognition?.nrvStandard {
                            Text(String(format: SafeMealL10n.text(L10nKey.Result.nrvBasisFormat), std.version))
                                .font(SafeMealFont.custom(10, relativeTo: .caption2))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.metricCalories), value: nutrients.calories.value, unit: nutrients.calories.unit, nrvPercent: nutrients.calories.dailyValuePercent, badge: nutrients.calories.source == "estimated" ? "估" : (nutrients.calories.source == "predicted" ? "推" : nil))
                                NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.metricProtein), value: nutrients.protein.value, unit: nutrients.protein.unit, nrvPercent: nutrients.protein.dailyValuePercent, badge: nutrients.protein.source == "estimated" ? "估" : (nutrients.protein.source == "predicted" ? "推" : nil))
                                NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.metricFat), value: nutrients.fat.value, unit: nutrients.fat.unit, nrvPercent: nutrients.fat.dailyValuePercent, badge: nutrients.fat.source == "estimated" ? "估" : (nutrients.fat.source == "predicted" ? "推" : nil))
                                NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.metricCarbs), value: nutrients.carbohydrates.value, unit: nutrients.carbohydrates.unit, nrvPercent: nutrients.carbohydrates.dailyValuePercent, badge: nutrients.carbohydrates.source == "estimated" ? "估" : (nutrients.carbohydrates.source == "predicted" ? "推" : nil))
                                NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.sodium), value: nutrients.sodium?.value, unit: nutrients.sodium?.unit, nrvPercent: nutrients.sodium?.dailyValuePercent, badge: nutrients.sodium?.source == "estimated" ? "估" : (nutrients.sodium?.source == "predicted" ? "推" : nil))
                                // 膳食纤维：由 S2 迁入，有值才显示，无值整行不渲染
                                if let fiber = nutrients.dietaryFiber, fiber.value > 0 {
                                    NutritionFactRowView(name: SafeMealL10n.text(L10nKey.Result.dietaryFiber), value: fiber.value, unit: fiber.unit, nrvPercent: fiber.dailyValuePercent, badge: fiber.source == "estimated" ? "估" : (fiber.source == "predicted" ? "推" : nil))
                                }
                            }
                        }
                    }
                } else {
                    emptyDataCard
                }
            } else {
                emptyDataCard
            }
        }
    }

    // S2: 详细营养素（header 由 paywallWrapped 统一渲染；当前 S2 隐藏，枚举保留待恢复）
    private var detailedNutrientsSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients {
                let allItems = detailedNutrientItems(nutrients)
                if !allItems.isEmpty {
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(allItems, id: \.0) { item in
                                NutritionFactRowView(name: item.0, value: item.1.value, unit: item.1.unit, nrvPercent: item.1.dailyValuePercent, badge: item.1.source == "estimated" ? "估" : (item.1.source == "predicted" ? "推" : nil))
                            }
                        }
                    }
                }
            }
        }
    }

    private func detailedNutrientItems(_ nutrients: Nutrients) -> [(String, NutrientValue)] {
        var items: [(String, NutrientValue)] = []
        if let sf = nutrients.saturatedFat { items.append((SafeMealL10n.text(L10nKey.Result.saturatedFat), sf)) }
        if let tf = nutrients.transFat { items.append((SafeMealL10n.text(L10nKey.Result.transFat), tf)) }
        if let df = nutrients.dietaryFiber { items.append((SafeMealL10n.text(L10nKey.Result.dietaryFiber), df)) }
        if let s = nutrients.sugar { items.append((SafeMealL10n.text(L10nKey.Result.sugarNutrient), s)) }
        return items
    }

    // S3: 维生素（header 由 paywallWrapped 统一渲染）
    @ViewBuilder
    private var vitaminsSection: some View {
        let dvItems = vitaminItems

        if !dvItems.isEmpty {
            sectionCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dvItems, id: \.0) { item in
                        NutritionFactRowView(name: item.0, value: item.1, unit: item.2, nrvPercent: item.3, badge: item.4)
                    }
                }
            }
        } else {
            emptyDataCard
        }
    }

    private var vitaminItems: [(String, Double?, String?, Double?, String?)] {
        guard let v = recognition?.effectiveNutrition?.vitamins else { return [] }
        return vitaminItems(v)
    }

    private func vitaminItems(_ v: Vitamins) -> [(String, Double?, String?, Double?, String?)] {
        var result: [(String, Double?, String?, Double?, String?)] = []
        if let a = v.a { result.append((SafeMealL10n.text(L10nKey.Result.vitA), a.value, a.unit, a.dailyValuePercent, a.source == "estimated" ? "估" : (a.source == "predicted" ? "推" : nil))) }
        if let b1 = v.b1 { result.append((SafeMealL10n.text(L10nKey.Result.vitB1), b1.value, b1.unit, b1.dailyValuePercent, b1.source == "estimated" ? "估" : (b1.source == "predicted" ? "推" : nil))) }
        if let b2 = v.b2 { result.append((SafeMealL10n.text(L10nKey.Result.vitB2), b2.value, b2.unit, b2.dailyValuePercent, b2.source == "estimated" ? "估" : (b2.source == "predicted" ? "推" : nil))) }
        if let b3 = v.b3 { result.append((SafeMealL10n.text(L10nKey.Result.vitB3), b3.value, b3.unit, b3.dailyValuePercent, b3.source == "estimated" ? "估" : (b3.source == "predicted" ? "推" : nil))) }
        if let b5 = v.b5 { result.append((SafeMealL10n.text(L10nKey.Result.vitB5), b5.value, b5.unit, b5.dailyValuePercent, b5.source == "estimated" ? "估" : (b5.source == "predicted" ? "推" : nil))) }
        if let b6 = v.b6 { result.append((SafeMealL10n.text(L10nKey.Result.vitB6), b6.value, b6.unit, b6.dailyValuePercent, b6.source == "estimated" ? "估" : (b6.source == "predicted" ? "推" : nil))) }
        if let b12 = v.b12 { result.append((SafeMealL10n.text(L10nKey.Result.vitB12), b12.value, b12.unit, b12.dailyValuePercent, b12.source == "estimated" ? "估" : (b12.source == "predicted" ? "推" : nil))) }
        if let c = v.c { result.append((SafeMealL10n.text(L10nKey.Result.vitC), c.value, c.unit, c.dailyValuePercent, c.source == "estimated" ? "估" : (c.source == "predicted" ? "推" : nil))) }
        if let d = v.d { result.append((SafeMealL10n.text(L10nKey.Result.vitD), d.value, d.unit, d.dailyValuePercent, d.source == "estimated" ? "估" : (d.source == "predicted" ? "推" : nil))) }
        if let e = v.e { result.append((SafeMealL10n.text(L10nKey.Result.vitE), e.value, e.unit, e.dailyValuePercent, e.source == "estimated" ? "估" : (e.source == "predicted" ? "推" : nil))) }
        if let k = v.k { result.append((SafeMealL10n.text(L10nKey.Result.vitK), k.value, k.unit, k.dailyValuePercent, k.source == "estimated" ? "估" : (k.source == "predicted" ? "推" : nil))) }
        if let folate = v.folate { result.append((SafeMealL10n.text(L10nKey.Result.vitFolate), folate.value, folate.unit, folate.dailyValuePercent, folate.source == "estimated" ? "估" : (folate.source == "predicted" ? "推" : nil))) }
        return result
    }

    // S4: 矿物质（从 minerals 对象各属性读取分量 + NRV%）
    @ViewBuilder
    private var mineralsSection: some View {
        let dvItems = mineralItems

        if !dvItems.isEmpty {
            sectionCard {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dvItems, id: \.0) { item in
                        NutritionFactRowView(name: item.0, value: item.1, unit: item.2, nrvPercent: item.3, badge: item.4)
                    }
                }
            }
        } else {
            emptyDataCard
        }
    }

    private var mineralItems: [(String, Double?, String?, Double?, String?)] {
        guard let m = recognition?.effectiveNutrition?.minerals else { return [] }
        return mineralItems(m)
    }

    private func mineralItems(_ m: Minerals) -> [(String, Double?, String?, Double?, String?)] {
        var result: [(String, Double?, String?, Double?, String?)] = []
        if let ca = m.calcium { result.append((SafeMealL10n.text(L10nKey.Result.mineralCalcium), ca.value, ca.unit, ca.dailyValuePercent, ca.source == "estimated" ? "估" : (ca.source == "predicted" ? "推" : nil))) }
        if let fe = m.iron { result.append((SafeMealL10n.text(L10nKey.Result.mineralIron), fe.value, fe.unit, fe.dailyValuePercent, fe.source == "estimated" ? "估" : (fe.source == "predicted" ? "推" : nil))) }
        if let mg = m.magnesium { result.append((SafeMealL10n.text(L10nKey.Result.mineralMagnesium), mg.value, mg.unit, mg.dailyValuePercent, mg.source == "estimated" ? "估" : (mg.source == "predicted" ? "推" : nil))) }
        if let p = m.phosphorus { result.append((SafeMealL10n.text(L10nKey.Result.mineralPhosphorus), p.value, p.unit, p.dailyValuePercent, p.source == "estimated" ? "估" : (p.source == "predicted" ? "推" : nil))) }
        if let k = m.potassium { result.append((SafeMealL10n.text(L10nKey.Result.mineralPotassium), k.value, k.unit, k.dailyValuePercent, k.source == "estimated" ? "估" : (k.source == "predicted" ? "推" : nil))) }
        if let zn = m.zinc { result.append((SafeMealL10n.text(L10nKey.Result.mineralZinc), zn.value, zn.unit, zn.dailyValuePercent, zn.source == "estimated" ? "估" : (zn.source == "predicted" ? "推" : nil))) }
        if let se = m.selenium { result.append((SafeMealL10n.text(L10nKey.Result.mineralSelenium), se.value, se.unit, se.dailyValuePercent, se.source == "estimated" ? "估" : (se.source == "predicted" ? "推" : nil))) }
        return result
    }

    // S6: 血糖信息（header 由 paywallWrapped 统一渲染）
    private var glycemicSection: some View {
        Group {
            if let gi = recognition?.effectiveNutrition?.glycemicInfo,
               gi.glycemicIndex != nil || gi.glycemicLoad != nil {
                sectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        if let idx = gi.glycemicIndex {
                            HStack {
                                Text(SafeMealL10n.text(L10nKey.Result.glycemicIndex))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f", idx))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(glycemicColor(idx))
                            }
                        }
                        if let load = gi.glycemicLoad {
                            HStack {
                                Text(SafeMealL10n.text(L10nKey.Result.glycemicLoad))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                                Spacer()
                                Text(String(format: "%.1f", load))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                            }
                        }
                        if let insulin = gi.insulinIndex {
                            HStack {
                                Text(SafeMealL10n.text(L10nKey.Result.insulinIndex))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                                Spacer()
                                Text(String(format: "%.0f", insulin))
                                    .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeMealTheme.textPrimary)
                            }
                        }
                    }
                }
            } else {
                emptyDataCard
            }
        }
    }

    private func glycemicColor(_ gi: Double) -> Color {
        if gi <= 55 { return SafeMealTheme.success }
        if gi <= 70 { return SafeMealTheme.warning }
        return SafeMealTheme.danger
    }

    // S7: 过敏原 — 全档全可见（header 由 paywallWrapped 统一渲染）
    private var backAllergenSection: some View {
        Group {
            if let data = allergensData, !data.contains.isEmpty || !data.mayContain.isEmpty {
                sectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        if !data.contains.isEmpty {
                            allergenRow(
                                label: SafeMealL10n.text(L10nKey.Result.allergenContains),
                                items: data.contains,
                                color: SafeMealTheme.danger
                            )
                        }
                        if !data.mayContain.isEmpty {
                            allergenRow(
                                label: SafeMealL10n.text(L10nKey.Result.allergenMayContain),
                                items: data.mayContain,
                                color: SafeMealTheme.warning
                            )
                        }
                    }
                }
            } else {
                emptyDataCard
            }
        }
    }

    // S8: 饮食信息（Pro 起解锁；header 由 paywallWrapped 统一渲染）
    private var dietaryInfoSection: some View {
        Group {
            if let diet = recognition?.effectiveNutrition?.dietaryInfo {
                let allTags = dietaryTagItems(diet).filter { $0.1 }
                if !allTags.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionCard {
                            FlowLayout(spacing: 8, lineSpacing: 8) {
                                ForEach(allTags, id: \.0) { tag in
                                    dietaryTag(tag.0, isOn: tag.1)
                                }
                            }
                        }
                    }
                } else {
                    emptyDataCard
                }
            } else {
                emptyDataCard
            }
        }
    }

    private func dietaryTagItems(_ diet: DietaryInfo) -> [(String, Bool)] {
        [
            (SafeMealL10n.text(L10nKey.Result.dietVegetarian), diet.isVegetarian ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietVegan), diet.isVegan ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietBuddhistStrict), diet.isBuddhistStrict ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietGlutenFree), diet.isGlutenFree ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietLactoseFree), diet.isLactoseFree ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietHalal), diet.isHalal ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietLowFodmap), diet.isLowFodmap ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietDairyFree), diet.isDairyFree ?? false),
            (SafeMealL10n.text(L10nKey.Result.dietNutFree), diet.isNutFree ?? false),
        ]
    }

    private func dietaryTag(_ label: String, isOn: Bool) -> some View {
        Text(label)
            .font(SafeMealFont.custom(13, relativeTo: .footnote, weight: .semibold))
            .foregroundStyle(isOn ? .white : SafeMealTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOn ? SafeMealTheme.success : (colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5)))
            .clipShape(Capsule())
    }

    // S9: 制备方式
    private var preparationSection: some View {
        Group {
            if let prep = recognition?.effectiveNutrition?.preparation,
               prep.cookingMethod != nil || prep.oilType != nil || prep.oilAmount != nil || prep.saltLevel != nil || prep.sugarLevel != nil {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeMealL10n.text(L10nKey.Result.preparation), icon: "frying.pan.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            if let method = prep.cookingMethod {
                                prepRow(SafeMealL10n.text(L10nKey.Result.prepMethod), value: method)
                            }
                            if let oil = prep.oilType {
                                prepRow(SafeMealL10n.text(L10nKey.Result.prepOilType), value: oil)
                            }
                            if let amount = prep.oilAmount {
                                prepRow(SafeMealL10n.text(L10nKey.Result.prepOilAmount), value: amount)
                            }
                            if let salt = prep.saltLevel {
                                prepRow(SafeMealL10n.text(L10nKey.Result.prepSaltLevel), value: salt)
                            }
                            if let sugar = prep.sugarLevel {
                                prepRow(SafeMealL10n.text(L10nKey.Result.prepSugarLevel), value: sugar)
                            }
                        }
                    }
                }
            }
        }
    }

    private func prepRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)
            Spacer()
            Text(value)
                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
        }
    }

    // S10: 成分分解
    private var ingredientBreakdownSection: some View {
        Group {
            if let ingredients = recognition?.effectiveNutrition?.ingredientBreakdown, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeMealL10n.text(L10nKey.Result.sectionIngredients), icon: "list.bullet.clipboard.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredients) { ing in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(ing.isMainIngredient == true ? SafeMealTheme.primary : SafeMealTheme.textSecondary.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(ing.name)
                                                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                                .foregroundStyle(SafeMealTheme.textPrimary)
                                            if let amount = ing.amount {
                                                Text(amount)
                                                    .font(SafeMealFont.custom(12, relativeTo: .caption))
                                                    .foregroundStyle(SafeMealTheme.textSecondary)
                                            }
                                        }
                                        if let algs = ing.allergens, !algs.isEmpty {
                                            HStack(spacing: 4) {
                                                ForEach(algs, id: \.self) { a in
                                                    Text(localizedAllergenName(a))
                                                        .font(SafeMealFont.custom(11, relativeTo: .caption2))
                                                        .foregroundStyle(SafeMealTheme.danger)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(SafeMealTheme.danger.opacity(0.12))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func heroImageCard(item: LocalHistoryItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(heroPanelFill)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(heroBackdropFill)
                .padding(16)

            Group {
                if let image = LocalImageLoader.loadStickerImage(for: item) ?? LocalImageLoader.loadDisplayImage(for: item) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                } else {
                    VStack(spacing: 10) {
                        HugeIcon(glyph: .image01, size: 28)
                        Text(SafeMealL10n.text(L10nKey.Result.imageMissing))
                            .font(SafeMealFont.textStyle(.subheadline))
                    }
                    .foregroundStyle(SafeMealTheme.textSecondary)
                }
            }
        }
        .frame(height: 350)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line, lineWidth: 1)
        )
    }

    private func pairedMetricCard(
        leftTitle: String,
        leftValue: String,
        rightTitle: String,
        rightValue: String
    ) -> some View {
        HStack(spacing: 16) {
            metricColumn(title: leftTitle, value: leftValue)
            Rectangle()
                .fill(SafeMealTheme.line)
                .frame(width: 1)
                .padding(.vertical, 10)
            metricColumn(title: rightTitle, value: rightValue)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 22)
        .background(sectionCardFill)
        .overlay(sectionCardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func metricColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)

            Text(value)
                .font(SafeMealFont.custom(30, relativeTo: .title, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sectionCardFill)
            .overlay(sectionCardStroke(cornerRadius: 26))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func riskRow(_ risk: ResultRiskRow) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(risk.color)
                .frame(width: 10, height: 10)
                .padding(.top, 3)

            Text(risk.title)
                .font(SafeMealFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)

            Text(risk.detail)
                .font(SafeMealFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(risk.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(riskRowFill)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : SafeMealTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeMealFont.custom(19, relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [SafeMealTheme.primaryDeep, SafeMealTheme.primary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeMealFont.custom(19, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeMealTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(buttonSecondaryFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func inlineFeedbackAction(title: String) -> some View {
        inlineActionWithIcon(icon: "info.circle", title: title) {
            showFeedback = true
        }
    }

    private func inlineActionWithIcon(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                HugeIcon(sf: icon, size: 16)
                Text(title)
                    .font(SafeMealFont.custom(15, relativeTo: .footnote))
            }
            .foregroundStyle(SafeMealTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private var medicalDisclaimerView: some View {
        (Text(Self.medicalDisclaimerBodyAttributed)
            + Text(Self.aiDisclaimerLinkAttributed))
        .font(SafeMealFont.custom(13, relativeTo: .caption))
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
        .environment(\.openURL, OpenURLAction { url in
            guard url.absoluteString == "safemeal://ai_disclaimer" else { return .discarded }
            showAiDisclaimer = true
            return .handled
        })
        .sheet(isPresented: $showAiDisclaimer) {
            NavigationStack {
                DisclosureDetailView(
                    title: SafeMealL10n.text(L10nKey.Profile.About.aiDisclaimer),
                    category: "ai_disclaimer"
                )
            }
            .environmentObject(store)
        }
    }

    private static var medicalDisclaimerBodyAttributed: AttributedString {
        var attr = AttributedString(SafeMealL10n.text(L10nKey.Result.medicalDisclaimer))
        attr.foregroundColor = SafeMealTheme.textSecondary.opacity(0.86)
        return attr
    }

    private static var aiDisclaimerLinkAttributed: AttributedString {
        var attr = AttributedString(SafeMealL10n.text(L10nKey.Result.aiDisclaimerLink))
        attr.foregroundColor = SafeMealTheme.primary
        attr.underlineStyle = .single
        attr.link = URL(string: "safemeal://ai_disclaimer")
        return attr
    }

    private func statusChip(text: String, color: Color) -> some View {
        Text(text)
            .font(SafeMealFont.custom(13, relativeTo: .footnote, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(colorScheme == .dark ? 0.14 : 0.12))
            .overlay(
                Capsule()
                    .stroke(color.opacity(colorScheme == .dark ? 0.18 : 0.14), lineWidth: 1)
            )
            .clipShape(Capsule())
    }

    private func subtleChip(text: String) -> some View {
        Text(text)
            .font(SafeMealFont.custom(13, relativeTo: .footnote))
            .foregroundStyle(SafeMealTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.primarySoft.opacity(0.62))
            )
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeMealTheme.line, lineWidth: 1)
            )
    }

    private var flipGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) + 18 else { return }
                guard abs(value.translation.width) > 48 else { return }
                flipCard(direction: value.translation.width > 0 ? 1 : -1)
            }
    }

    private func flipCard(direction: Double) {
        flipDirection = isFlipped ? 1 : -1
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            isFlipped.toggle()
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    private func loadDetailIfNeeded() async {
        guard let item else { return }
        // 如果没有缓存数据，或者数据不完整，都尝试加载一次
        if item.cachedRecognition == nil || !hasFullRecognitionDetail {
            isLoadingDetail = true
            _ = await store.fetchRecognitionDetailIfNeeded(for: item.id)
            isLoadingDetail = false
        }
    }

    private func backAdviceText(recognition: RecognitionRecord) -> String {
        if let reasons = recognition.reasons, !reasons.isEmpty {
            return reasons.joined(separator: SafeMealL10n.text(L10nKey.Result.reasonSeparator))
        }
        if let advice = recognition.adviceText,
           !advice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return advice
        }
        return AdviceLevelMapper.menuSummary(level: recognition.adviceLevel ?? item?.adviceLevel, adviceText: item?.adviceText)
    }

    private func formatMetric(_ value: Double?, unit: String = "") -> String {
        guard let value else { return "--" }
        if unit.isEmpty {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f%@", value, unit)
    }

    private func tone(for level: String) -> ResultRiskTone {
        switch level {
        case "positive":
            return .success
        case "risk":
            return .danger
        case "caution":
            return .warning
        default:
            return .warning
        }
    }

    private func aiSummaryText(for explanation: AIExplanation) -> String? {
        SafeMealL10n.isZh
            ? (explanation.summary ?? explanation.summaryEn)
            : (explanation.summaryEn ?? explanation.summary)
    }

    private func aiDetailedText(for explanation: AIExplanation) -> String? {
        SafeMealL10n.isZh
            ? (explanation.detailedAdvice ?? explanation.detailedAdviceEn)
            : (explanation.detailedAdviceEn ?? explanation.detailedAdvice)
    }

    private func aiHealthTips(for explanation: AIExplanation) -> [String]? {
        SafeMealL10n.isZh
            ? (explanation.healthTips ?? explanation.healthTipsEn)
            : (explanation.healthTipsEn ?? explanation.healthTips)
    }

    private var buttonSecondaryFill: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.90))
    }

    private var heroPanelFill: Color {
        colorScheme == .dark
            ? Color(red: 0.21, green: 0.22, blue: 0.25)
            : Color.white.opacity(0.32)
    }

    private var heroBackdropFill: Color {
        colorScheme == .dark
            ? Color(red: 0.23, green: 0.24, blue: 0.27)
            : Color(red: 0.95, green: 0.97, blue: 0.96)
    }

    private var sectionCardFill: Color {
        colorScheme == .dark
            ? Color(red: 0.23, green: 0.24, blue: 0.28)
            : Color.white.opacity(0.82)
    }

    private func sectionCardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.07) : SafeMealTheme.line, lineWidth: 1)
    }

    private var scoreLogicFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color.white.opacity(0.70)
    }

    private var riskRowFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color.white.opacity(0.08)
    }

    private var missingState: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                pageBackground

                VStack(alignment: .leading, spacing: 18) {
                    Color.clear
                        .frame(height: proxy.safeAreaInsets.top + 74)

                    HugeIcon(glyph: .alert02, size: 40)
                        .foregroundStyle(SafeMealTheme.warning)

                    Text(SafeMealL10n.text(L10nKey.Result.missingTitle))
                        .font(SafeMealFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                        .foregroundStyle(SafeMealTheme.textPrimary)

                    Text(SafeMealL10n.text(L10nKey.Result.missingMessage))
                        .font(SafeMealFont.textStyle(.body))
                        .foregroundStyle(SafeMealTheme.textSecondary)

                    primaryButton(title: SafeMealL10n.text(L10nKey.Result.missingRetry)) {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)

                SafeMealTopBackChrome(
                    title: SafeMealL10n.text(L10nKey.Result.title),
                    scrollOffset: 0,
                    topInset: proxy.safeAreaInsets.top,
                    onBack: { dismiss() }
                )
            }
            .ignoresSafeArea()
        }
    }
}

private struct ResultRiskRow: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let tone: ResultRiskTone

    var color: Color {
        tone.color
    }
}

private enum ResultRiskTone {
    case success
    case warning
    case danger

    var color: Color {
        switch self {
        case .success:
            return SafeMealTheme.success
        case .warning:
            return SafeMealTheme.warning
        case .danger:
            return SafeMealTheme.danger
        }
    }
}

// Phase 8C: 推荐等级枚举
enum RecommendationLevel: String, CaseIterable {
    case highlyRecommended = "excellent"
    case recommended = "good"
    case neutral = "moderate"
    case cautious = "caution"
    case notRecommended = "avoid"

    var icon: String {
        switch self {
        case .highlyRecommended: return "checkmark.seal.fill"
        case .recommended: return "thumbsup.fill"
        case .neutral: return "hand.raised.fill"
        case .cautious: return "exclamationmark.triangle.fill"
        case .notRecommended: return "xmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .highlyRecommended: return SafeMealTheme.success
        case .recommended: return SafeMealTheme.primary
        case .neutral: return SafeMealTheme.warning
        case .cautious: return SafeMealTheme.warning
        case .notRecommended: return SafeMealTheme.danger
        }
    }

    var l10nKey: String {
        switch self {
        case .highlyRecommended: return L10nKey.Result.recommendHighly
        case .recommended: return L10nKey.Result.recommendYes
        case .neutral: return L10nKey.Result.recommendModerate
        case .cautious: return L10nKey.Result.recommendCautious
        case .notRecommended: return L10nKey.Result.recommendNo
        }
    }
}

private struct MiniScoreRingView: View {
    let score: Int
    var size: CGFloat = 48

    @Environment(\.colorScheme) private var colorScheme

    private var ringColor: Color {
        switch score {
        case 80...: return SafeMealTheme.primary
        case 60...: return SafeMealTheme.primary.opacity(0.8)
        default: return SafeMealTheme.warning
        }
    }

    private var trackColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : SafeMealTheme.primarySoft.opacity(0.62)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100.0)
                .stroke(ringColor, lineWidth: 4)
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(ringColor)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - P1 结果页 tab
enum ResultTab: CaseIterable {
    case overview
    case nutrition
    case advice
}
