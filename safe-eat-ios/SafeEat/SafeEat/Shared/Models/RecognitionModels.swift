import Foundation

struct RecognitionRecord: Codable, Identifiable {
    let id: String
    let recognizedName: String
    let normalizedName: String?
    let edibleStatus: String?
    let adviceLevel: String?
    let adviceText: String?
    let reasons: [String]?
    let foodScore: Int?
    let healthImpacts: [HealthImpact]?
    let nutritionSnapshot: NutritionSnapshot?
    let sourceType: String?
    let feedbackEvidence: FeedbackEvidence?
    let createdAt: Date?

    // Phase 8C: 规则引擎 + AI 建议字段
    let overallScore: Int?
    let recommendationLevel: String?
    let metricImpacts: [MetricImpact]?
    let riskFacts: [RiskFact]?
    let aiExplanation: AIExplanation?
}

struct NutritionSnapshot: Codable {
    let calories: Double?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let riskFlags: [String]?
}

struct HealthImpact: Codable, Identifiable {
    var id: String {
        "\(condition)-\(label)-\(level)"
    }

    let condition: String
    let label: String
    let level: String
    let reason: String
}

struct MetricImpact: Codable, Identifiable {
    var id: String { metric }

    let metric: String
    let score: Int
    let weight: Double?
    let weightedScore: Double?
    let impactDirection: String? // "positive" / "neutral" / "negative"
}

struct RiskFact: Codable, Identifiable {
    var id: String { tag }

    let tag: String
    let severity: String // "warning" / "danger"
    let description: String
    let affectedMetrics: [String]?
}

struct AIExplanation: Codable {
    let summary: String?
    let detailedAdvice: String?
    let healthTips: [String]?
}

struct FeedbackEvidence: Codable {
    let hasEvidence: Bool
    let reviewStatus: String?
    let reviewSource: String?
}

struct PendingFeedbackItem: Codable, Identifiable {
    let id: String
    let recognitionId: String
    let originalName: String
    let proposedName: String
    let status: String
}
