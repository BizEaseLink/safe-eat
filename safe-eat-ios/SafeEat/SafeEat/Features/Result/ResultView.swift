import SwiftUI
import UIKit

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
    @State private var flipDirection: Double = -1
    @State private var scrollOffset: CGFloat = 0

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
            return SafeEatL10n.text(L10nKey.Common.unknownFood)
        }
        return trimmed
    }

    private var scoreValue: Int {
        recognition?.overallScore ?? recognition?.foodScore ?? item?.foodScore ?? 0
    }

    private var scoreTitle: String {
        switch scoreValue {
        case 80...:
            return SafeEatL10n.text(L10nKey.Result.scoreLevelHigh)
        case 60...:
            return SafeEatL10n.text(L10nKey.Result.scoreLevelMedium)
        default:
            return SafeEatL10n.text(L10nKey.Result.scoreLevelLow)
        }
    }

    private var scoreColor: Color {
        switch scoreValue {
        case 80...:
            return SafeEatTheme.success
        case 60...:
            return SafeEatTheme.primary
        default:
            return SafeEatTheme.warning
        }
    }

    private var statusText: String {
        if !hasFullRecognitionDetail {
            return SafeEatL10n.text(L10nKey.Result.statusInsufficient)
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
            return SafeEatL10n.text(L10nKey.Result.incompleteSummary)
        }

        return AdviceLevelMapper.menuSummary(
            level: recognition?.adviceLevel ?? item?.adviceLevel,
            adviceText: item?.adviceText
        )
    }

    private var backHeaderNote: String {
        SafeEatL10n.text(L10nKey.Result.headerNote)
    }

    private var scoreLogicText: String {
        SafeEatL10n.text(L10nKey.Result.scoreLogicBody)
    }

    private var medicalDisclaimerText: String {
        SafeEatL10n.text(L10nKey.Result.medicalDisclaimer)
    }

    private var pairedMetrics: [(String, String, String, String)] {
        let metrics = recognition?.effectiveNutrition
        let nutrients = metrics?.nutrients
        return [
            (
                SafeEatL10n.text(L10nKey.Result.metricCalories),
                formatMetric(nutrients?.calories.value),
                SafeEatL10n.text(L10nKey.Result.metricProtein),
                formatMetric(nutrients?.protein.value, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit))
            ),
            (
                SafeEatL10n.text(L10nKey.Result.metricFat),
                formatMetric(nutrients?.fat.value, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit)),
                SafeEatL10n.text(L10nKey.Result.metricCarbs),
                formatMetric(nutrients?.carbohydrates.value, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit))
            ),
        ]
    }

    private var riskItems: [ResultRiskRow] {
        if let impacts = recognition?.healthImpacts, !impacts.isEmpty {
            return impacts.map {
                ResultRiskRow(
                    title: $0.label,
                    detail: $0.reason,
                    tone: tone(for: $0.level)
                )
            }
        }

        if let riskFlags = recognition?.nutritionSnapshot?.riskFlags, !riskFlags.isEmpty {
            return riskFlags.map {
                ResultRiskRow(
                    title: SafeEatL10n.text(L10nKey.Result.nutritionAlertTitle),
                    detail: $0,
                    tone: .warning
                )
            }
        }

        return [
            ResultRiskRow(
                title: SafeEatL10n.text(L10nKey.Result.completenessTitle),
                detail: SafeEatL10n.text(L10nKey.Result.completenessDetail),
                tone: .warning
            )
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

    // T8: 根据 tier 判断 Section 是否完全可见
    private func isSectionVisible(_ section: PaywallSection) -> Bool {
        membershipTier.isSectionFullyVisible(section)
    }

    // T8: 付费墙包装器 — 如果用户无权查看则显示遮罩
    private func paywallWrapped<Content: View>(
        _ section: PaywallSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Group {
            if isSectionVisible(section) {
                content()
            } else if membershipTier.isSectionPartiallyVisible(section) {
                content()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(sectionTitle(for: section), icon: sectionIcon(for: section))
                    PaywallOverlayView(section: section) {
                        showMembership = true
                    }
                    .frame(height: 120)
                }
            }
        }
    }

    private func sectionTitle(for section: PaywallSection) -> String {
        switch section {
        case .s1BasicNutrients: return SafeEatL10n.text(L10nKey.Result.sectionMacronutrients)
        case .s2DetailedNutrients: return SafeEatL10n.text(L10nKey.Result.sectionDetailedNutrients)
        case .s3Vitamins: return SafeEatL10n.text(L10nKey.Result.sectionVitamins)
        case .s4Minerals: return SafeEatL10n.text(L10nKey.Result.sectionMinerals)
        case .s5DailyValues: return SafeEatL10n.text(L10nKey.Result.sectionDailyValues)
        case .s6Glycemic: return SafeEatL10n.text(L10nKey.Result.sectionGlycemic)
        case .s7Allergens: return SafeEatL10n.text(L10nKey.Result.allergenTitle)
        case .s8Dietary: return SafeEatL10n.text(L10nKey.Result.sectionDietary)
        case .s9Preparation: return SafeEatL10n.text(L10nKey.Result.preparation)
        case .s10Ingredients: return SafeEatL10n.text(L10nKey.Result.sectionIngredients)
        }
    }

    private func sectionIcon(for section: PaywallSection) -> String {
        switch section {
        case .s1BasicNutrients: return "flame.fill"
        case .s2DetailedNutrients: return "chart.bar.fill"
        case .s3Vitamins: return "capsule.fill"
        case .s4Minerals: return "hexagon.fill"
        case .s5DailyValues: return "percent"
        case .s6Glycemic: return "drop.fill"
        case .s7Allergens: return "exclamationmark.shield.fill"
        case .s8Dietary: return "leaf.fill"
        case .s9Preparation: return "frying.pan.fill"
        case .s10Ingredients: return "list.bullet.clipboard.fill"
        }
    }

    // Phase 8C: AI 建议访问控制
    private var aiAdviceLevel: String {
        store.profile?.currentPlanTier ?? "free"
    }

    private var canShowSummary: Bool {
        let tier = aiAdviceLevel
        return tier != "free"
    }

    private var canShowDetailedAdvice: Bool {
        let tier = aiAdviceLevel
        return tier == "pro" || tier == "premium"
    }

    private var canShowHealthTips: Bool {
        aiAdviceLevel == "premium"
    }

    private var showUpgradeHint: Bool {
        !canShowHealthTips
    }

    var body: some View {
        Group {
            if let item, let recognition {
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
                    .onChange(of: item.cachedRecognition?.id) { _, _ in
                        if isLoadingDetail, hasFullRecognitionDetail {
                            isLoadingDetail = false
                        }
                    }
            } else {
                missingState
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func resultPage(item: LocalHistoryItem, recognition: RecognitionRecord) -> some View {
        GeometryReader { proxy in
            let contentHeight = proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom

            ZStack(alignment: .topLeading) {
                pageBackground

                ZStack {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Color.clear
                                .frame(height: proxy.safeAreaInsets.top + 36)

                            frontCard(item: item)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 * flipDirection : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.9
                    )

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            Color.clear
                                .frame(height: proxy.safeAreaInsets.top + 36)

                            backCard(recognition: recognition)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180 * flipDirection),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.9
                    )
                }
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: isFlipped)

                SafeEatTopBackChrome(
                    title: isFlipped
                        ? SafeEatL10n.text(L10nKey.Result.analysisTitle)
                        : SafeEatL10n.text(L10nKey.Result.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top,
                    onBack: { dismiss() }
                )
            }
            .ignoresSafeArea()
        }
        .onAppear {
            scrollOffset = 0
        }
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
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.10 : 0.46),
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
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(SafeEatTheme.success)
                        .padding(.top, 2)

                    Text(backHeaderNote)
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(SafeEatL10n.text(L10nKey.Result.title))
                    .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(displayName)
                        .font(SafeEatFont.custom(18, relativeTo: .title3, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    if item.feedbackPending {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
            heroImageCard(item: item)

            // Phase 8C: 评分圆环 + 推荐等级 + 建议等级
            scoreRingSection

            Text(frontSummaryText)
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.94))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // T6: 过敏原标签
            allergenTagsSection

            // T6: 饱腹感指数
            satietyIndexSection

            if !isPaidMember {
                NativeAdView()
                    .frame(height: 80)
            }

            HStack(spacing: 12) {
                primaryButton(title: SafeEatL10n.text(L10nKey.Result.actionContinue)) {
                    flipCard(direction: -1)
                }

                secondaryButton(title: SafeEatL10n.text(L10nKey.Result.actionRetake)) {
                    dismiss()
                }
            }

            inlineFeedbackAction(title: SafeEatL10n.text(L10nKey.Result.actionFeedback))

            medicalDisclaimerView
        }
        .padding(.top, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(flipGesture)
        .onTapGesture {
            flipCard(direction: -1)
        }
    }

    // Phase 8C: 评分圆环（整合推荐等级 + 建议等级）
    private var scoreRingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: min(CGFloat(scoreValue) / 100.0, 1.0))
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(scoreValue)")
                        .font(SafeEatFont.custom(28, relativeTo: .title2, weight: .bold))
                        .foregroundStyle(scoreColor)
                    Text(scoreTitle)
                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                        .foregroundStyle(scoreColor.opacity(0.88))
                }
            }
            .frame(width: 100, height: 100)

            // 推荐等级 + 建议等级同行
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: recommendation.icon)
                        .font(.system(size: 13))
                    Text(SafeEatL10n.text(recommendation.l10nKey))
                        .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(recommendation.color.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .foregroundStyle(recommendation.color)
                .clipShape(Capsule())

                statusChip(text: statusText, color: statusColor)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // T6: 过敏原标签区
    private var allergenTagsSection: some View {
        Group {
            if let data = allergensData {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SafeEatTheme.danger)
                        Text(SafeEatL10n.text(L10nKey.Result.allergenTitle))
                            .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    }

                    if !data.contains.isEmpty {
                        allergenRow(
                            label: SafeEatL10n.text(L10nKey.Result.allergenContains),
                            items: data.contains,
                            color: SafeEatTheme.danger
                        )
                    }

                    if !data.mayContain.isEmpty {
                        allergenRow(
                            label: SafeEatL10n.text(L10nKey.Result.allergenMayContain),
                            items: data.mayContain,
                            color: .orange
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func allergenRow(label: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(SafeEatFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(items, id: \.self) { item in
                    allergenChip(text: item, color: color, isDark: colorScheme == .dark)
                }
            }
        }
    }

    private func allergenChip(text: String, color: Color, isDark: Bool) -> some View {
        Text(text)
            .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(isDark ? 0.18 : 0.12))
            .clipShape(Capsule())
    }

    // T6: 饱腹感指数
    private var satietyIndexSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients {
                let score = computeSatietyScore(nutrients: nutrients)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14))
                            .foregroundStyle(SafeEatTheme.primary)
                        Text(SafeEatL10n.text(L10nKey.Result.satietyTitle))
                            .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    }

                    HStack(spacing: 8) {
                        satietyBar(score: score)
                        Text(satietyLabel(score: score))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(satietyColor(score: score))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 20))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
        case 0.6...: return SafeEatL10n.text(L10nKey.Result.satietyHigh)
        case 0.3..<0.6: return SafeEatL10n.text(L10nKey.Result.satietyMedium)
        default: return SafeEatL10n.text(L10nKey.Result.satietyLow)
        }
    }

    private func satietyColor(score: Double) -> Color {
        switch score {
        case 0.6...: return SafeEatTheme.success
        case 0.3..<0.6: return SafeEatTheme.primary
        default: return SafeEatTheme.warning
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

    private func backCard(recognition: RecognitionRecord) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(backHeaderNote)
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(SafeEatL10n.text(L10nKey.Result.analysisTitle))
                    .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(displayName)
                        .font(SafeEatFont.custom(18, relativeTo: .title3, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    if item?.feedbackPending == true {
                        Image(systemName: "hourglass")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            if isLoadingDetail && !hasFullRecognitionDetail {
                VStack(spacing: 8) {
                    ProgressView()
                        .tint(SafeEatTheme.primary)
                    Text(SafeEatL10n.text(L10nKey.Result.detailSyncing))
                        .font(SafeEatFont.textStyle(.caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else if !hasFullRecognitionDetail {
                subtleChip(text: SafeEatL10n.text(L10nKey.Result.detailLocalOnly))
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showScoreLogicDetail.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(SafeEatL10n.text(L10nKey.Result.scoreLogicTitle))
                                .font(SafeEatFont.custom(16, relativeTo: .subheadline))
                                .foregroundStyle(SafeEatTheme.textSecondary)

                            Text(SafeEatL10n.format(L10nKey.Result.scoreLogicFormat, scoreValue))
                                .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                .foregroundStyle(scoreColor)
                        }

                        Spacer(minLength: 10)

                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.84))
                    }

                    Text(SafeEatL10n.text(L10nKey.Result.scoreLogicHint))
                        .font(SafeEatFont.custom(13, relativeTo: .footnote))
                        .foregroundStyle(SafeEatTheme.textSecondary)

                    if showScoreLogicDetail {
                        Text(scoreLogicText)
                            .font(SafeEatFont.custom(13, relativeTo: .footnote))
                            .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.90))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(scoreLogicFill)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionCardFill)
                .overlay(sectionCardStroke(cornerRadius: 26))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            // Phase 8C: 营养指标列表（规则引擎）
            if let impacts = recognition.metricImpacts, !impacts.isEmpty {
                metricImpactsSection(impacts)
            }

            // T7/T8: S1 基础营养素（FREE 可见）
            paywallWrapped(.s1BasicNutrients) { basicNutrientsSection }

            // T7/T8: S2 详细营养素（LITE+ 可见）
            paywallWrapped(.s2DetailedNutrients) { detailedNutrientsSection }

            // T7/T8: S3 维生素（LITE+ 可见）
            paywallWrapped(.s3Vitamins) { vitaminsSection }

            // T7/T8: S4 矿物质（LITE+ 可见）
            paywallWrapped(.s4Minerals) { mineralsSection }

            // T7/T8: S5 每日值百分比（LITE+ 可见）
            paywallWrapped(.s5DailyValues) { dailyValueSection }

            // T7/T8: S6 血糖信息（LITE+ 可见）
            paywallWrapped(.s6Glycemic) { glycemicSection }

            // T7/T8: S7 过敏原（FREE 可见 contains，PRO+ 完整）
            paywallWrapped(.s7Allergens) { backAllergenSection }

            // T7/T8: S8 饮食信息（PRO+ 可见）
            paywallWrapped(.s8Dietary) { dietaryInfoSection }

            // T7/T8: S9 制备方式（PRO+ 可见）
            paywallWrapped(.s9Preparation) { preparationSection }

            // T7/T8: S10 成分分解（PREMIUM+ 可见）
            paywallWrapped(.s10Ingredients) { ingredientBreakdownSection }

            // Phase 8C: 风险标签（规则引擎）
            if let risks = recognition.riskFacts, !risks.isEmpty {
                riskFactsSection(risks)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(SafeEatL10n.text(L10nKey.Result.adviceSectionTitle))
                    .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                sectionCard {
                    Text(backAdviceText(recognition: recognition))
                        .font(SafeEatFont.custom(16, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.94))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Phase 8C: AI 建议区域
            aiAdviceSection

            VStack(alignment: .leading, spacing: 12) {
                Text(SafeEatL10n.text(L10nKey.Result.riskSectionTitle))
                    .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                sectionCard {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(riskItems) { risk in
                            riskRow(risk)
                        }
                    }
                }
            }

            if !isPaidMember {
                NativeAdView()
                    .frame(height: 80)
            }

            primaryButton(title: SafeEatL10n.text(L10nKey.Result.actionBackToFront)) {
                flipCard(direction: 1)
            }

            inlineFeedbackAction(title: SafeEatL10n.text(L10nKey.Result.actionFeedback))

            medicalDisclaimerView
        }
        .padding(.top, 6)
        .contentShape(Rectangle())
        .simultaneousGesture(flipGesture)
        .onTapGesture {
            flipCard(direction: 1)
        }
    }

    // Phase 8C: 营养指标 section
    private func metricImpactsSection(_ impacts: [MetricImpact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Result.metricTitle))
                .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(impacts) { impact in
                        HStack(spacing: 10) {
                            impactDirectionIcon(impact.impactDirection)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(impact.metric)
                                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                                if let weighted = impact.weightedScore {
                                    Text(SafeEatL10n.format(L10nKey.Result.metricScoreFormat, Int(weighted)))
                                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                }
                            }
                            Spacer()
                            Text("\(impact.score)")
                                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                .foregroundStyle(impactScoreColor(impact.score))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func impactDirectionIcon(_ direction: String?) -> some View {
        Group {
            switch direction {
            case "positive":
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(SafeEatTheme.success)
            case "negative":
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(SafeEatTheme.danger)
            default:
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
        .font(.system(size: 18))
    }

    private func impactScoreColor(_ score: Int) -> Color {
        if score >= 70 { return SafeEatTheme.success }
        if score >= 40 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

    // Phase 8C: 风险标签 section
    private func riskFactsSection(_ risks: [RiskFact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Result.riskTitle))
                .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            sectionCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(risks) { risk in
                        HStack(spacing: 10) {
                            Image(systemName: risk.severity == "danger" ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                                .foregroundStyle(risk.severity == "danger" ? SafeEatTheme.danger : SafeEatTheme.warning)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(risk.tag)
                                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                                Text(risk.description)
                                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // Phase 8C: AI 建议区域
    private var aiAdviceSection: some View {
        Group {
            if let explanation = recognition?.aiExplanation {
                VStack(alignment: .leading, spacing: 12) {
                    Text(SafeEatL10n.text(L10nKey.Result.aiAdviceTitle))
                        .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    // 摘要区
                    if canShowSummary, let summary = explanation.summary {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(SafeEatL10n.text(L10nKey.Result.aiAdviceSummaryLabel), systemImage: "text.quote")
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.primary)
                                Text(summary)
                                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.94))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // 详细建议区
                    if canShowDetailedAdvice, let detailed = explanation.detailedAdvice {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label(SafeEatL10n.text(L10nKey.Result.aiAdviceDetailedLabel), systemImage: "doc.text.fill")
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(SafeEatTheme.primary)
                                Text(detailed)
                                    .font(SafeEatFont.custom(14, relativeTo: .body))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    // 健康提示区
                    if canShowHealthTips, let tips = explanation.healthTips, !tips.isEmpty {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Label(SafeEatL10n.text(L10nKey.Result.healthTipsTitle), systemImage: "heart.text.square.fill")
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                    .foregroundStyle(.green)
                                ForEach(tips, id: \.self) { tip in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.green)
                                        Text(tip)
                                    }
                                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                }
                            }
                        }
                    }

                    // 升级提示（非 Premium 用户）
                    if showUpgradeHint {
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(SafeEatL10n.format(L10nKey.Result.upgradeTierHintFormat, upgradeTierName))
                                    .font(SafeEatFont.custom(13, relativeTo: .footnote))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                Button {
                                    showMembership = true
                                } label: {
                                    Label(SafeEatL10n.text(L10nKey.Result.upgradeForMoreAdvice), systemImage: "lock.fill")
                                        .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                }
            } else if showUpgradeHint {
                // Free 用户无 AI 建议数据时显示升级占位
                VStack(alignment: .leading, spacing: 12) {
                    Text(SafeEatL10n.text(L10nKey.Result.aiAdviceTitle))
                        .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(SafeEatL10n.format(L10nKey.Result.upgradeTierHintFormat, upgradeTierName))
                                .font(SafeEatFont.custom(13, relativeTo: .footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Button {
                                showMembership = true
                            } label: {
                                Label(SafeEatL10n.text(L10nKey.Result.upgradeForMoreAdvice), systemImage: "lock.fill")
                                    .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                    }
                }
            }
        }
    }

    /// 升级目标 tier 名称
    private var upgradeTierName: String {
        let tier = aiAdviceLevel
        switch tier {
        case "free": return "Lite"
        case "lite": return "Pro"
        default: return "Premium"
        }
    }

    // MARK: - T7: 背面 10 Section

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(SafeEatTheme.primary)
            Text(title)
                .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
        }
    }

    private func nutrientRow(_ nv: NutrientValue, label: String) -> some View {
        HStack {
            Text(label)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textPrimary)
            Spacer()
            Text(String(format: "%.1f", nv.value))
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
            + Text(" \(nv.unit)")
                .font(SafeEatFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }

    // S1: 基础营养素
    private var basicNutrientsSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionMacronutrients), icon: "flame.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            nutrientRow(nutrients.calories, label: SafeEatL10n.text(L10nKey.Result.metricCalories))
                            nutrientRow(nutrients.protein, label: SafeEatL10n.text(L10nKey.Result.metricProtein))
                            nutrientRow(nutrients.fat, label: SafeEatL10n.text(L10nKey.Result.metricFat))
                            nutrientRow(nutrients.carbohydrates, label: SafeEatL10n.text(L10nKey.Result.metricCarbs))
                            if let chol = nutrients.cholesterol { nutrientRow(chol, label: SafeEatL10n.text(L10nKey.Result.cholesterol)) }
                            if let na = recognition?.effectiveNutrition?.nutrients?.sodium { nutrientRow(na, label: SafeEatL10n.text(L10nKey.Result.sodium)) }
                        }
                    }
                }
            }
        }
    }

    // S2: 详细营养素
    private var detailedNutrientsSection: some View {
        Group {
            if let nutrients = recognition?.effectiveNutrition?.nutrients,
               nutrients.saturatedFat != nil || nutrients.transFat != nil || nutrients.dietaryFiber != nil || nutrients.sugar != nil || nutrients.cholesterol != nil {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionDetailedNutrients), icon: "chart.bar.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            if let sf = nutrients.saturatedFat { nutrientRow(sf, label: SafeEatL10n.text(L10nKey.Result.saturatedFat)) }
                            if let tf = nutrients.transFat { nutrientRow(tf, label: SafeEatL10n.text(L10nKey.Result.transFat)) }
                            if let df = nutrients.dietaryFiber { nutrientRow(df, label: SafeEatL10n.text(L10nKey.Result.dietaryFiber)) }
                            if let s = nutrients.sugar { nutrientRow(s, label: SafeEatL10n.text(L10nKey.Result.sugarNutrient)) }
                            if let c = nutrients.cholesterol { nutrientRow(c, label: SafeEatL10n.text(L10nKey.Result.cholesterol)) }
                        }
                    }
                }
            }
        }
    }

    // S3: 维生素
    private var vitaminsSection: some View {
        Group {
            if let vitamins = recognition?.effectiveNutrition?.vitamins {
                let items: [(String, NutrientValue)] = vitaminItems(vitamins)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionVitamins), icon: "capsule.fill")
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                    nutrientRow(item.1, label: item.0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func vitaminItems(_ v: Vitamins) -> [(String, NutrientValue)] {
        var result: [(String, NutrientValue)] = []
        if let a = v.a { result.append((SafeEatL10n.text(L10nKey.Result.vitA), a)) }
        if let b1 = v.b1 { result.append((SafeEatL10n.text(L10nKey.Result.vitB1), b1)) }
        if let b2 = v.b2 { result.append((SafeEatL10n.text(L10nKey.Result.vitB2), b2)) }
        if let b3 = v.b3 { result.append((SafeEatL10n.text(L10nKey.Result.vitB3), b3)) }
        if let b5 = v.b5 { result.append((SafeEatL10n.text(L10nKey.Result.vitB5), b5)) }
        if let b6 = v.b6 { result.append((SafeEatL10n.text(L10nKey.Result.vitB6), b6)) }
        if let b12 = v.b12 { result.append((SafeEatL10n.text(L10nKey.Result.vitB12), b12)) }
        if let c = v.c { result.append((SafeEatL10n.text(L10nKey.Result.vitC), c)) }
        if let d = v.d { result.append((SafeEatL10n.text(L10nKey.Result.vitD), d)) }
        if let e = v.e { result.append((SafeEatL10n.text(L10nKey.Result.vitE), e)) }
        if let k = v.k { result.append((SafeEatL10n.text(L10nKey.Result.vitK), k)) }
        if let folate = v.folate { result.append((SafeEatL10n.text(L10nKey.Result.vitFolate), folate)) }
        return result
    }

    // S4: 矿物质
    private var mineralsSection: some View {
        Group {
            if let minerals = recognition?.effectiveNutrition?.minerals {
                let items: [(String, NutrientValue)] = mineralItems(minerals)
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionMinerals), icon: "hexagon.fill")
                        sectionCard {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                    nutrientRow(item.1, label: item.0)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func mineralItems(_ m: Minerals) -> [(String, NutrientValue)] {
        var result: [(String, NutrientValue)] = []
        if let ca = m.calcium { result.append((SafeEatL10n.text(L10nKey.Result.mineralCalcium), ca)) }
        if let fe = m.iron { result.append((SafeEatL10n.text(L10nKey.Result.mineralIron), fe)) }
        if let mg = m.magnesium { result.append((SafeEatL10n.text(L10nKey.Result.mineralMagnesium), mg)) }
        if let p = m.phosphorus { result.append((SafeEatL10n.text(L10nKey.Result.mineralPhosphorus), p)) }
        if let k = m.potassium { result.append((SafeEatL10n.text(L10nKey.Result.mineralPotassium), k)) }
        if let zn = m.zinc { result.append((SafeEatL10n.text(L10nKey.Result.mineralZinc), zn)) }
        if let se = m.selenium { result.append((SafeEatL10n.text(L10nKey.Result.mineralSelenium), se)) }
        return result
    }

    // S5: 每日值百分比
    private var dailyValueSection: some View {
        Group {
            if let dv = recognition?.effectiveNutrition?.dailyValuePercentages, !dv.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionDailyValues), icon: "percent")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(dv.sorted(by: { $0.key < $1.key }).enumerated()), id: \.offset) { _, entry in
                                HStack {
                                    Text(entry.key)
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    Spacer()
                                    dailyValueBar(value: entry.value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func dailyValueBar(value: Double) -> some View {
        HStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(SafeEatTheme.primary)
                        .frame(width: geo.size.width * min(CGFloat(value) / 100.0, 1.0))
                }
            }
            .frame(height: 6)
            .frame(maxWidth: 60)
            Text(String(format: "%.0f%%", value))
                .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
        }
    }

    // S6: 血糖信息
    private var glycemicSection: some View {
        Group {
            if let gi = recognition?.effectiveNutrition?.glycemicInfo {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionGlycemic), icon: "drop.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            if let idx = gi.glycemicIndex {
                                HStack {
                                    Text(SafeEatL10n.text(L10nKey.Result.glycemicIndex))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.0f", idx))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(glycemicColor(idx))
                                }
                            }
                            if let load = gi.glycemicLoad {
                                HStack {
                                    Text(SafeEatL10n.text(L10nKey.Result.glycemicLoad))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.1f", load))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                }
                            }
                            if let insulin = gi.insulinIndex {
                                HStack {
                                    Text(SafeEatL10n.text(L10nKey.Result.insulinIndex))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    Spacer()
                                    Text(String(format: "%.0f", insulin))
                                        .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func glycemicColor(_ gi: Double) -> Color {
        if gi <= 55 { return SafeEatTheme.success }
        if gi <= 70 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

    // S7: 过敏原（背面版）— T8: FREE 只看 contains，PRO+ 看 mayContain
    private var backAllergenSection: some View {
        Group {
            if let data = allergensData {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.allergenTitle), icon: "exclamationmark.shield.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            if !data.contains.isEmpty {
                                allergenRow(
                                    label: SafeEatL10n.text(L10nKey.Result.allergenContains),
                                    items: data.contains,
                                    color: SafeEatTheme.danger
                                )
                            }
                            if !data.mayContain.isEmpty {
                                if membershipTier >= .pro {
                                    allergenRow(
                                        label: SafeEatL10n.text(L10nKey.Result.allergenMayContain),
                                        items: data.mayContain,
                                        color: .orange
                                    )
                                } else {
                                    // T8: mayContain 遮罩（FREE/LITE 用户不可见）
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 12))
                                            .foregroundStyle(SafeEatTheme.primary)
                                        Text(SafeEatL10n.text(L10nKey.Result.paywallUpgradeHint))
                                            .font(SafeEatFont.custom(13, relativeTo: .footnote))
                                            .foregroundStyle(SafeEatTheme.textSecondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // S8: 饮食信息
    private var dietaryInfoSection: some View {
        Group {
            if let diet = recognition?.effectiveNutrition?.dietaryInfo {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionDietary), icon: "leaf.fill")
                    sectionCard {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietVegetarian), isOn: diet.isVegetarian ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietVegan), isOn: diet.isVegan ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietGlutenFree), isOn: diet.isGlutenFree ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietLactoseFree), isOn: diet.isLactoseFree ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietHalal), isOn: diet.isHalal ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietLowFodmap), isOn: diet.isLowFodmap ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietDairyFree), isOn: diet.isDairyFree ?? false)
                            dietaryTag(SafeEatL10n.text(L10nKey.Result.dietNutFree), isOn: diet.isNutFree ?? false)
                        }
                    }
                }
            }
        }
    }

    private func dietaryTag(_ label: String, isOn: Bool) -> some View {
        Text(label)
            .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .semibold))
            .foregroundStyle(isOn ? .white : SafeEatTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isOn ? SafeEatTheme.success : (colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5)))
            .clipShape(Capsule())
    }

    // S9: 制备方式
    private var preparationSection: some View {
        Group {
            if let prep = recognition?.effectiveNutrition?.preparation,
               prep.cookingMethod != nil || prep.oilType != nil || prep.oilAmount != nil || prep.saltLevel != nil || prep.sugarLevel != nil {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.preparation), icon: "frying.pan.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            if let method = prep.cookingMethod {
                                prepRow(SafeEatL10n.text(L10nKey.Result.prepMethod), value: method)
                            }
                            if let oil = prep.oilType {
                                prepRow(SafeEatL10n.text(L10nKey.Result.prepOilType), value: oil)
                            }
                            if let amount = prep.oilAmount {
                                prepRow(SafeEatL10n.text(L10nKey.Result.prepOilAmount), value: amount)
                            }
                            if let salt = prep.saltLevel {
                                prepRow(SafeEatL10n.text(L10nKey.Result.prepSaltLevel), value: salt)
                            }
                            if let sugar = prep.sugarLevel {
                                prepRow(SafeEatL10n.text(L10nKey.Result.prepSugarLevel), value: sugar)
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
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
            Spacer()
            Text(value)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
        }
    }

    // S10: 成分分解
    private var ingredientBreakdownSection: some View {
        Group {
            if let ingredients = recognition?.effectiveNutrition?.ingredientBreakdown, !ingredients.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    sectionHeader(SafeEatL10n.text(L10nKey.Result.sectionIngredients), icon: "list.bullet.clipboard.fill")
                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(ingredients) { ing in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(ing.isMainIngredient == true ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                        .padding(.top, 6)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 4) {
                                            Text(ing.name)
                                                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                                .foregroundStyle(SafeEatTheme.textPrimary)
                                            if let amount = ing.amount {
                                                Text(amount)
                                                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                            }
                                        }
                                        if let algs = ing.allergens, !algs.isEmpty {
                                            HStack(spacing: 4) {
                                                ForEach(algs, id: \.self) { a in
                                                    Text(a)
                                                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                                        .foregroundStyle(SafeEatTheme.danger)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(SafeEatTheme.danger.opacity(0.12))
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
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                        Text(SafeEatL10n.text(L10nKey.Result.imageMissing))
                            .font(SafeEatFont.textStyle(.subheadline))
                    }
                    .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
        }
        .frame(height: 350)
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
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
                .fill(SafeEatTheme.line)
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
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(value)
                .font(SafeEatFont.custom(30, relativeTo: .title, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
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
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(risk.detail)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                .foregroundStyle(risk.color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(riskRowFill)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : SafeEatTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeEatFont.custom(19, relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
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
                .font(SafeEatFont.custom(19, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(buttonSecondaryFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func inlineFeedbackAction(title: String) -> some View {
        Button {
            showFeedback = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(SafeEatFont.custom(18, relativeTo: .footnote))
            }
            .foregroundStyle(SafeEatTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
    }

    private var medicalDisclaimerView: some View {
        Text(medicalDisclaimerText)
            .font(SafeEatFont.custom(11, relativeTo: .caption))
            .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.86))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func statusChip(text: String, color: Color) -> some View {
        Text(text)
            .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .bold))
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
            .font(SafeEatFont.custom(13, relativeTo: .footnote))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.62))
            )
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
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
        guard let item, item.cachedRecognition == nil else { return }
        isLoadingDetail = true
        _ = await store.fetchRecognitionDetailIfNeeded(for: item.id)
        isLoadingDetail = false
    }

    private func backAdviceText(recognition: RecognitionRecord) -> String {
        if let reasons = recognition.reasons, !reasons.isEmpty {
            return reasons.joined(separator: SafeEatL10n.text(L10nKey.Result.reasonSeparator))
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
            : Color.white.opacity(0.12)
    }

    private func sectionCardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.07) : SafeEatTheme.line, lineWidth: 1)
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

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(SafeEatTheme.warning)
                        .symbolRenderingMode(.hierarchical)

                    Text(SafeEatL10n.text(L10nKey.Result.missingTitle))
                        .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Text(SafeEatL10n.text(L10nKey.Result.missingMessage))
                        .font(SafeEatFont.textStyle(.body))
                        .foregroundStyle(SafeEatTheme.textSecondary)

                    primaryButton(title: SafeEatL10n.text(L10nKey.Result.missingRetry)) {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20)

                SafeEatTopBackChrome(
                    title: SafeEatL10n.text(L10nKey.Result.title),
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
            return SafeEatTheme.success
        case .warning:
            return SafeEatTheme.warning
        case .danger:
            return SafeEatTheme.danger
        }
    }
}

// Phase 8C: 推荐等级枚举
enum RecommendationLevel: String, CaseIterable {
    case highlyRecommended = "highly_recommended"
    case recommended = "recommended"
    case neutral = "moderate"
    case cautious = "cautious"
    case notRecommended = "not_recommended"

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
        case .highlyRecommended: return SafeEatTheme.success
        case .recommended: return .mint
        case .neutral: return SafeEatTheme.warning
        case .cautious: return .orange
        case .notRecommended: return SafeEatTheme.danger
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
