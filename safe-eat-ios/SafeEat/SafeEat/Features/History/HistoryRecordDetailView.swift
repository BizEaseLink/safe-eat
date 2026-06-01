import SwiftUI

/// 服务器历史记录详情页（MOB-2）
/// 展示单条 RecognitionRecord 的完整识别结果：评分、指标影响、风险因子、AI 建议
struct HistoryRecordDetailView: View {
    let record: RecognitionRecord
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    private var aiLevel: String { store.profile?.currentPlanTier ?? "free" }

    private var canShowSummary: Bool { aiLevel != "free" }
    private var canShowDetailed: Bool { aiLevel == "pro" || aiLevel == "premium" }
    private var canShowHealthTips: Bool { aiLevel == "premium" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 顶部评分卡
                scoreCard

                // 识别信息
                recognitionInfoCard

                // 指标影响
                if let impacts = record.metricImpacts, !impacts.isEmpty {
                    metricImpactsCard(impacts)
                }

                // 风险因子
                if let risks = record.riskFacts, !risks.isEmpty {
                    riskFactsCard(risks)
                }

                // AI 建议
                aiAdviceSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
        .navigationTitle(record.recognizedName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 评分卡

    private var scoreCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.2), lineWidth: 6)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: scoreFraction)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                Text(scoreLabel)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(record.recognizedName)
                    .font(SafeEatFont.textStyle(.title3))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                if let level = recommendationLabel {
                    Text(level)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(scoreColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
                        .foregroundStyle(scoreColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(20)
        .background(sectionCardBackground)
        .overlay(sectionCardStroke)
    }

    // MARK: - 识别信息

    private var recognitionInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(SafeEatL10n.text(L10nKey.Result.recognitionInfoLabel), systemImage: "info.circle")
                .font(SafeEatFont.textStyle(.subheadline).bold())
                .foregroundStyle(SafeEatTheme.primary)

            if let createdAt = record.createdAt {
                HStack {
                    Text(SafeEatL10n.text(L10nKey.History.dateLabel))
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Spacer()
                    Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                }
            }
        }
        .padding(18)
        .background(sectionCardBackground)
        .overlay(sectionCardStroke)
    }

    // MARK: - 指标影响

    private func metricImpactsCard(_ impacts: [MetricImpact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(SafeEatL10n.text(L10nKey.Result.metricImpactsLabel), systemImage: "chart.bar")
                .font(SafeEatFont.textStyle(.subheadline).bold())
                .foregroundStyle(SafeEatTheme.primary)

            ForEach(impacts) { impact in
                HStack(spacing: 10) {
                    Circle()
                        .fill(impactDirectionColor(impact.impactDirection))
                        .frame(width: 8, height: 8)
                    Text(impact.metric)
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    Spacer()
                    if let score = impact.weightedScore {
                        Text(String(format: "%.0f", score))
                            .font(SafeEatFont.textStyle(.caption).bold())
                            .foregroundStyle(impactDirectionColor(impact.impactDirection))
                    }
                }
            }
        }
        .padding(18)
        .background(sectionCardBackground)
        .overlay(sectionCardStroke)
    }

    // MARK: - 风险因子

    private func riskFactsCard(_ risks: [RiskFact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(SafeEatL10n.text(L10nKey.Result.riskFactsLabel), systemImage: "exclamationmark.triangle")
                .font(SafeEatFont.textStyle(.subheadline).bold())
                .foregroundStyle(.orange)

            ForEach(risks) { risk in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 14))
                        .foregroundStyle(riskSeverityColor(risk.severity))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(risk.tag)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                        if !risk.description.isEmpty {
                            Text(risk.description)
                                .font(SafeEatFont.textStyle(.caption))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(sectionCardBackground)
        .overlay(sectionCardStroke)
    }

    // MARK: - AI 建议

    private var aiAdviceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary
            if let summary = record.aiExplanation?.summary, !summary.isEmpty {
                if canShowSummary {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(SafeEatL10n.text(L10nKey.Result.aiAdviceSummaryLabel), systemImage: "text.quote")
                            .font(SafeEatFont.textStyle(.subheadline).bold())
                            .foregroundStyle(SafeEatTheme.primary)
                        Text(summary)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    }
                    .padding(18)
                    .background(sectionCardBackground)
                    .overlay(sectionCardStroke)
                } else {
                    tierGatedCard(
                        title: SafeEatL10n.text(L10nKey.Result.aiAdviceSummaryLabel),
                        icon: "text.quote",
                        targetTier: "Lite"
                    )
                }
            }

            // Detailed Advice
            if let detailed = record.aiExplanation?.detailedAdvice, !detailed.isEmpty {
                if canShowDetailed {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(SafeEatL10n.text(L10nKey.Result.aiAdviceDetailedLabel), systemImage: "doc.text.fill")
                            .font(SafeEatFont.textStyle(.subheadline).bold())
                            .foregroundStyle(SafeEatTheme.primary)
                        Text(detailed)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    }
                    .padding(18)
                    .background(sectionCardBackground)
                    .overlay(sectionCardStroke)
                } else {
                    tierGatedCard(
                        title: SafeEatL10n.text(L10nKey.Result.aiAdviceDetailedLabel),
                        icon: "doc.text.fill",
                        targetTier: aiLevel == "free" ? "Lite" : "Pro"
                    )
                }
            }

            // Health Tips
            if let tips = record.aiExplanation?.healthTips, !tips.isEmpty {
                if canShowHealthTips {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(SafeEatL10n.text(L10nKey.Result.aiAdviceHealthTipsLabel), systemImage: "heart.text.square.fill")
                            .font(SafeEatFont.textStyle(.subheadline).bold())
                            .foregroundStyle(SafeEatTheme.primary)
                        ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                                Text(tip)
                                    .font(SafeEatFont.textStyle(.subheadline))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                            }
                        }
                    }
                    .padding(18)
                    .background(sectionCardBackground)
                    .overlay(sectionCardStroke)
                } else {
                    tierGatedCard(
                        title: SafeEatL10n.text(L10nKey.Result.aiAdviceHealthTipsLabel),
                        icon: "heart.text.square.fill",
                        targetTier: "Premium"
                    )
                }
            }
        }
    }

    // MARK: - Tier 门控占位卡

    private func tierGatedCard(title: String, icon: String, targetTier: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(SafeEatFont.textStyle(.subheadline).bold())
                .foregroundStyle(SafeEatTheme.textSecondary)
            Text(SafeEatL10n.format(L10nKey.Result.upgradeTierHintFormat, targetTier))
                .font(SafeEatFont.textStyle(.caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SafeEatTheme.line, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
    }

    // MARK: - 辅助

    private var scoreColor: Color {
        guard let score = record.overallScore else { return .gray }
        if score >= 70 { return .green }
        if score >= 40 { return .orange }
        return .red
    }

    private var scoreLabel: String {
        guard let score = record.overallScore else { return "--" }
        return String(score)
    }

    private var scoreFraction: CGFloat {
        guard let score = record.overallScore else { return 0 }
        return CGFloat(score) / 100.0
    }

    private var recommendationLabel: String? {
        switch record.recommendationLevel {
        case "recommended": return SafeEatL10n.text(L10nKey.Result.recommendYes)
        case "moderate": return SafeEatL10n.text(L10nKey.Result.recommendModerate)
        case "cautious": return SafeEatL10n.text(L10nKey.Result.recommendCautious)
        default: return nil
        }
    }

    private func impactDirectionColor(_ direction: String?) -> Color {
        guard let dir = direction?.lowercased() else { return .gray }
        switch dir {
        case "positive", "beneficial": return .green
        case "neutral": return .gray
        case "negative", "harmful": return .red
        default: return .orange
        }
    }

    private func riskSeverityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .yellow
        default: return .gray
        }
    }

    private var sectionCardBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.secondarySystemBackground))
    }

    private var sectionCardStroke: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(SafeEatTheme.line, lineWidth: 1)
    }
}

#Preview {
    NavigationStack {
        HistoryRecordDetailView(record: RecognitionRecord(
            id: "1",
            recognizedName: "Pizza",
            normalizedName: nil,
            edibleStatus: nil,
            adviceLevel: nil,
            adviceText: nil,
            reasons: nil,
            foodScore: nil,
            healthImpacts: nil,
            nutritionSnapshot: nil,
            nutritionMetrics: nil,
            sourceType: nil,
            feedbackEvidence: nil,
            createdAt: Date(),
            overallScore: 72,
            recommendationLevel: "moderate",
            metricImpacts: [
                MetricImpact(metric: "Sugar", score: 8, weight: nil, weightedScore: nil, impactDirection: "positive"),
            ],
            riskFacts: [
                RiskFact(tag: "High Sodium", severity: "medium", description: "Contains 800mg sodium per serving", affectedMetrics: nil),
            ],
            aiExplanation: AIExplanation(
                summary: "A moderately healthy choice.",
                detailedAdvice: "Consider reducing cheese portion.",
                healthTips: ["Pair with salad", "Limit to one slice"]
            )
        ))
        .environmentObject(AppStore())
    }
}
