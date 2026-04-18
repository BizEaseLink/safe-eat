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

struct FeedbackEvidence: Codable {
    let hasEvidence: Bool
    let reviewStatus: String?
    let reviewSource: String?
}

struct FeedbackPayload {
    let proposedName: String
    let comment: String
    let evidenceImageData: Data
}
