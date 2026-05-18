import Foundation

struct LocalHistoryItem: Codable, Identifiable {
    var id: String
    var recognitionId: String
    var originalImageUri: String
    var previewImageUri: String?
    var rawImageUri: String?
    var recognizedName: String
    var adviceLevel: String
    var adviceText: String?
    var foodScore: Int
    var createdAt: Date
    var cachedRecognition: RecognitionRecord?
    var imageRotationQuarterTurns: Int

    var displayImageUri: String {
        previewImageUri ?? originalImageUri
    }

    init(
        recognitionId: String,
        originalImageUri: String,
        previewImageUri: String?,
        rawImageUri: String? = nil,
        recognizedName: String,
        adviceLevel: String,
        adviceText: String? = nil,
        foodScore: Int,
        createdAt: Date,
        cachedRecognition: RecognitionRecord? = nil,
        imageRotationQuarterTurns: Int = 0
    ) {
        self.id = "\(recognitionId)-\(createdAt.timeIntervalSince1970)"
        self.recognitionId = recognitionId
        self.originalImageUri = originalImageUri
        self.previewImageUri = previewImageUri
        self.rawImageUri = rawImageUri
        self.recognizedName = recognizedName
        self.adviceLevel = adviceLevel
        self.adviceText = adviceText
        self.foodScore = foodScore
        self.createdAt = createdAt
        self.cachedRecognition = cachedRecognition
        self.imageRotationQuarterTurns = imageRotationQuarterTurns
    }
}

extension LocalHistoryItem {
    private enum CodingKeys: String, CodingKey {
        case id
        case recognitionId
        case originalImageUri
        case previewImageUri
        case rawImageUri
        case localImageUri
        case recognizedName
        case adviceLevel
        case adviceText
        case foodScore
        case createdAt
        case cachedRecognition
        case imageRotationQuarterTurns
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let recognitionId = try container.decode(String.self, forKey: .recognitionId)
        let originalImageUri =
            try container.decodeIfPresent(String.self, forKey: .originalImageUri)
            ?? container.decode(String.self, forKey: .localImageUri)
        let previewImageUri = try container.decodeIfPresent(String.self, forKey: .previewImageUri)
        let rawImageUri = try container.decodeIfPresent(String.self, forKey: .rawImageUri)
        let recognizedName = try container.decode(String.self, forKey: .recognizedName)
        let adviceLevel = try container.decode(String.self, forKey: .adviceLevel)
        let adviceText = try container.decodeIfPresent(String.self, forKey: .adviceText)
        let foodScore = try container.decode(Int.self, forKey: .foodScore)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let cachedRecognition = try container.decodeIfPresent(RecognitionRecord.self, forKey: .cachedRecognition)
        let imageRotationQuarterTurns = try container.decodeIfPresent(Int.self, forKey: .imageRotationQuarterTurns) ?? 0

        self.id =
            try container.decodeIfPresent(String.self, forKey: .id)
            ?? "\(recognitionId)-\(createdAt.timeIntervalSince1970)"
        self.recognitionId = recognitionId
        self.originalImageUri = originalImageUri
        self.previewImageUri = previewImageUri
        self.rawImageUri = rawImageUri
        self.recognizedName = recognizedName
        self.adviceLevel = adviceLevel
        self.adviceText = adviceText
        self.foodScore = foodScore
        self.createdAt = createdAt
        self.cachedRecognition = cachedRecognition
        self.imageRotationQuarterTurns = imageRotationQuarterTurns
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recognitionId, forKey: .recognitionId)
        try container.encode(originalImageUri, forKey: .originalImageUri)
        try container.encodeIfPresent(previewImageUri, forKey: .previewImageUri)
        try container.encodeIfPresent(rawImageUri, forKey: .rawImageUri)
        try container.encode(originalImageUri, forKey: .localImageUri)
        try container.encode(recognizedName, forKey: .recognizedName)
        try container.encode(adviceLevel, forKey: .adviceLevel)
        try container.encodeIfPresent(adviceText, forKey: .adviceText)
        try container.encode(foodScore, forKey: .foodScore)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(cachedRecognition, forKey: .cachedRecognition)
        try container.encode(imageRotationQuarterTurns, forKey: .imageRotationQuarterTurns)
    }
}

extension LocalHistoryItem {
    func fallbackRecognitionRecord() -> RecognitionRecord {
        RecognitionRecord(
            id: recognitionId,
            recognizedName: recognizedName,
            normalizedName: nil,
            edibleStatus: nil,
            adviceLevel: adviceLevel,
            adviceText: adviceText,
            reasons: nil,
            foodScore: foodScore,
            healthImpacts: nil,
            nutritionSnapshot: nil,
            sourceType: nil,
            feedbackEvidence: nil,
            createdAt: createdAt,
            overallScore: nil,
            recommendationLevel: nil,
            metricImpacts: nil,
            riskFacts: nil,
            aiExplanation: nil
        )
    }
}
