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
        let nutrition = recognition?.nutritionSnapshot
        return [
            (
                SafeEatL10n.text(L10nKey.Result.metricCalories),
                formatMetric(nutrition?.calories),
                SafeEatL10n.text(L10nKey.Result.metricProtein),
                formatMetric(nutrition?.protein, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit))
            ),
            (
                SafeEatL10n.text(L10nKey.Result.metricFat),
                formatMetric(nutrition?.fat, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit)),
                SafeEatL10n.text(L10nKey.Result.metricCarbs),
                formatMetric(nutrition?.carbs, unit: SafeEatL10n.text(L10nKey.Result.metricGramsUnit))
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

    // Phase 8C: AI 建议访问控制
    private var aiAdviceLevel: String {
        store.profile?.currentPlanTier ?? "free"
    }

    private var canShowDetailedAdvice: Bool {
        let tier = aiAdviceLevel
        return tier == "pro" || tier == "premium"
    }

    private var canShowHealthTips: Bool {
        aiAdviceLevel == "premium"
    }

    private var showUpgradeHint: Bool {
        !canShowDetailedAdvice || !canShowHealthTips
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

                Text(displayName)
                    .font(SafeEatFont.custom(18, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }
            heroImageCard(item: item)

            // Phase 8C: 评分圆环 + 推荐等级
            scoreRingSection

            VStack(alignment: .leading, spacing: 10) {
                Text(SafeEatL10n.text(L10nKey.Result.scoreSectionTitle))
                    .font(SafeEatFont.custom(16, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                statusChip(text: statusText, color: statusColor)

                HStack(alignment: .lastTextBaseline, spacing: 10) {
                    Text("\(scoreValue)")
                        .font(SafeEatFont.custom(58, relativeTo: .largeTitle, weight: .bold))
                        .foregroundStyle(scoreColor)

                    Text(scoreTitle)
                        .font(SafeEatFont.custom(22, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(scoreColor.opacity(0.88))
                        .padding(.bottom, 8)
                }
            }

            Text(frontSummaryText)
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.94))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

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

    // Phase 8C: 评分圆环
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
                    Text(SafeEatL10n.text(L10nKey.Result.scoreLabel))
                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
            .frame(width: 100, height: 100)

            // 推荐等级标签
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
        }
        .frame(maxWidth: .infinity)
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

                Text(displayName)
                    .font(SafeEatFont.custom(18, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
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

            VStack(alignment: .leading, spacing: 12) {
                Text(SafeEatL10n.text(L10nKey.Result.nutritionSectionTitle))
                    .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .padding(.bottom, 4)

                VStack(spacing: 14) {
                    ForEach(Array(pairedMetrics.enumerated()), id: \.offset) { _, metric in
                        pairedMetricCard(
                            leftTitle: metric.0,
                            leftValue: metric.1,
                            rightTitle: metric.2,
                            rightValue: metric.3
                        )
                    }
                }
            }

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

                    sectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            if let summary = explanation.summary {
                                Text(summary)
                                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                                    .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.94))
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if canShowDetailedAdvice, let detailed = explanation.detailedAdvice {
                                Text(detailed)
                                    .font(SafeEatFont.custom(14, relativeTo: .body))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if canShowHealthTips, let tips = explanation.healthTips, !tips.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(SafeEatL10n.text(L10nKey.Result.healthTipsTitle))
                                        .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    ForEach(tips, id: \.self) { tip in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("\u{2022}")
                                            Text(tip)
                                        }
                                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                                        .foregroundStyle(SafeEatTheme.textSecondary)
                                    }
                                }
                            }

                            if showUpgradeHint {
                                Button {
                                    // 导航到会员购买页
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
