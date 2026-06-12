import Foundation

// MARK: - NutritionMetrics v3 嵌套结构（对齐后端 nutrition-metrics.interface.ts）

struct NutrientValue: Codable {
    let value: Double
    let unit: String
    let dailyValuePercent: Double?

    // 后端返回 "amount"，iOS 属性名为 "value"
    private enum CodingKeys: String, CodingKey {
        case value = "amount"
        case unit
        case dailyValuePercent = "nrv"
    }
}

struct Vitamins: Codable {
    let a: NutrientValue?
    let b1: NutrientValue?
    let b2: NutrientValue?
    let b3: NutrientValue?
    let b5: NutrientValue?
    let b6: NutrientValue?
    let b12: NutrientValue?
    let c: NutrientValue?
    let d: NutrientValue?
    let e: NutrientValue?
    let k: NutrientValue?
    let folate: NutrientValue?

    private enum CodingKeys: String, CodingKey {
        case a = "vitaminA"
        case b1 = "thiamin"
        case b2 = "riboflavin"
        case b3 = "niacin"
        case b5 = "pantothenicAcid"
        case b6 = "vitaminB6"
        case b12 = "vitaminB12"
        case c = "vitaminC"
        case d = "vitaminD"
        case e = "vitaminE"
        case k = "vitaminK"
        case folate
    }
}

struct Minerals: Codable {
    let calcium: NutrientValue?
    let iron: NutrientValue?
    let magnesium: NutrientValue?
    let phosphorus: NutrientValue?
    let potassium: NutrientValue?
    let zinc: NutrientValue?
    let selenium: NutrientValue?
}

struct Nutrients: Codable {
    let calories: NutrientValue
    let protein: NutrientValue
    let fat: NutrientValue
    let saturatedFat: NutrientValue?
    let transFat: NutrientValue?
    let carbohydrates: NutrientValue
    let dietaryFiber: NutrientValue?
    let sugar: NutrientValue?
    let addedSugars: NutrientValue?
    let cholesterol: NutrientValue?
    let sodium: NutrientValue?
    // 后端 v3 嵌套在此处的 vitamins/minerals，由 NutritionMetrics 自定义解码器提取到顶层
    let vitamins: Vitamins?
    let minerals: Minerals?

    // 后端返回 "sugars"（复数），iOS 属性名为 "sugar"（单数）
    private enum CodingKeys: String, CodingKey {
        case calories
        case protein
        case fat
        case saturatedFat
        case transFat
        case carbohydrates
        case dietaryFiber
        case sugar = "sugars"
        case addedSugars
        case cholesterol
        case sodium
        case vitamins
        case minerals
    }
}

struct GlycemicInfo: Codable {
    let glycemicIndex: Double?
    let glycemicLoad: Double?
    let insulinIndex: Double?
    // sugarContent 是 iOS 本地计算字段，不从后端获取
}

struct Allergens: Codable {
    let contains: [String]
    let mayContain: [String]
}

struct DietaryInfo: Codable {
    let isVegetarian: Bool?
    let isVegan: Bool?
    let isGlutenFree: Bool?
    let isLactoseFree: Bool?
    let isLowFodmap: Bool?
    let isHalal: Bool?
    // isDairyFree/isNutFree 是 iOS 本地扩展字段，后端不返回
    let isDairyFree: Bool?
    let isNutFree: Bool?
}

struct Preparation: Codable {
    let isRaw: Bool?
    let isCooked: Bool?
    let isProcessed: Bool?
    // 后端 cookingMethod 是枚举类型，iOS 保持 String 兼容
    let cookingMethod: String?
    // 以下为旧字段，后端不返回但保留向后兼容
    let oilType: String?
    let oilAmount: String?
    let saltLevel: String?
    let sugarLevel: String?
}

struct IngredientBreakdown: Codable, Identifiable {
    var id: String { name }

    let name: String
    let estimatedWeight: Double?
    // 以下为旧字段，保留向后兼容
    let amount: String?
    let isMainIngredient: Bool?
    let allergens: [String]?
}

struct NutritionMetrics: Codable {
    let servingSize: ServingSize?
    let nutrients: Nutrients?
    let vitamins: Vitamins?
    let minerals: Minerals?
    let glycemicInfo: GlycemicInfo?
    let allergens: Allergens?
    let dietaryInfo: DietaryInfo?
    let preparation: Preparation?
    let ingredients: [String]?
    let ingredientBreakdown: [IngredientBreakdown]?

    init(
        servingSize: ServingSize? = nil,
        nutrients: Nutrients? = nil,
        vitamins: Vitamins? = nil,
        minerals: Minerals? = nil,
        glycemicInfo: GlycemicInfo? = nil,
        allergens: Allergens? = nil,
        dietaryInfo: DietaryInfo? = nil,
        preparation: Preparation? = nil,
        ingredients: [String]? = nil,
        ingredientBreakdown: [IngredientBreakdown]? = nil
    ) {
        self.servingSize = servingSize
        self.nutrients = nutrients
        self.vitamins = vitamins
        self.minerals = minerals
        self.glycemicInfo = glycemicInfo
        self.allergens = allergens
        self.dietaryInfo = dietaryInfo
        self.preparation = preparation
        self.ingredients = ingredients
        self.ingredientBreakdown = ingredientBreakdown
    }

    // 后端 v3 的 vitamins/minerals 嵌套在 nutrients 内部，
    // iOS 将它们提升到 NutritionMetrics 顶层以方便 UI 访问
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        servingSize = try container.decodeIfPresent(ServingSize.self, forKey: .servingSize)
        nutrients = try container.decodeIfPresent(Nutrients.self, forKey: .nutrients)
        glycemicInfo = try container.decodeIfPresent(GlycemicInfo.self, forKey: .glycemicInfo)
        allergens = try container.decodeIfPresent(Allergens.self, forKey: .allergens)
        dietaryInfo = try container.decodeIfPresent(DietaryInfo.self, forKey: .dietaryInfo)
        preparation = try container.decodeIfPresent(Preparation.self, forKey: .preparation)
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients)
        ingredientBreakdown = try container.decodeIfPresent([IngredientBreakdown].self, forKey: .ingredientBreakdown)

        // 优先从顶层读取 vitamins/minerals，若不存在则从 nutrients 内部提取
        if let topVitamins = try? container.decodeIfPresent(Vitamins.self, forKey: .vitamins) {
            vitamins = topVitamins
        } else {
            vitamins = nutrients?.vitamins
        }
        if let topMinerals = try? container.decodeIfPresent(Minerals.self, forKey: .minerals) {
            minerals = topMinerals
        } else {
            minerals = nutrients?.minerals
        }
    }
}

struct ServingSize: Codable {
    let amount: Double
    let unit: String
}

// MARK: - 5候选识别

struct IdentifyCandidate: Codable, Identifiable {
    var id: String { name }
    let name: String
    let confidence: Double
    let type: String?
    let source: String?

    // 后端可能返回字符串类型的 confidence，兼容处理
    private enum CodingKeys: String, CodingKey {
        case name, confidence, type, source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        source = try container.decodeIfPresent(String.self, forKey: .source)

        // confidence: 兼容 number 和 string 两种类型
        if let doubleVal = try? container.decode(Double.self, forKey: .confidence) {
            confidence = doubleVal
        } else if let strVal = try? container.decode(String.self, forKey: .confidence),
                  let parsed = Double(strVal) {
            confidence = parsed
        } else {
            confidence = 0
        }
    }

    // 用于 Preview 等手动构造的场景
    init(name: String, confidence: Double, type: String? = nil, source: String? = nil) {
        self.name = name
        self.confidence = confidence
        self.type = type
        self.source = source
    }
}

struct IdentifyResponse: Codable {
    let candidates: [IdentifyCandidate]
    let sessionId: String
}

struct FoodSearchItem: Codable, Identifiable {
    let id: String
    let name: String
    let categoryKey: String?
}

struct FoodSearchResponse: Codable {
    let items: [FoodSearchItem]
}

// MARK: - 血糖影响

struct BloodSugarImpact: Codable {
    let glycemicLoad: Double
    let level: String // "low" / "medium" / "high"
}

// MARK: - 识别记录

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
    let nutritionMetrics: NutritionMetrics?
    let sourceType: String?
    let feedbackEvidence: FeedbackEvidence?
    let createdAt: Date?

    // Phase 8C: 规则引擎 + AI 建议字段
    let overallScore: Int?
    let recommendationLevel: String?
    let metricImpacts: [MetricImpact]?
    let riskFacts: [RiskFact]?
    let aiExplanation: AIExplanation?
    let enhancedInsights: EnhancedInsights?

    // 后端新增字段
    let categoryKey: String?
    let categoryLabelEn: String?
    let ruleVersion: String?
    let nutritionVersion: String?
    let satietyScore: Double?
    let bloodSugarImpact: BloodSugarImpact?
    let drvPercentages: [String: Double]?

    private enum CodingKeys: String, CodingKey {
        case id
        case recognizedName
        case normalizedName
        case edibleStatus
        case adviceLevel
        case adviceText
        case reasons
        case foodScore
        case healthImpacts
        case nutritionSnapshot
        case nutritionMetrics
        case sourceType
        case feedbackEvidence
        case createdAt
        case overallScore
        case recommendationLevel
        case metricImpacts
        case riskFacts
        case aiExplanation
        case enhancedInsights
        case categoryKey
        case categoryLabelEn
        case ruleVersion
        case nutritionVersion
        case satietyScore
        case bloodSugarImpact
        case drvPercentages
    }

    init(
        id: String,
        recognizedName: String,
        normalizedName: String? = nil,
        edibleStatus: String? = nil,
        adviceLevel: String? = nil,
        adviceText: String? = nil,
        reasons: [String]? = nil,
        foodScore: Int? = nil,
        healthImpacts: [HealthImpact]? = nil,
        nutritionSnapshot: NutritionSnapshot? = nil,
        nutritionMetrics: NutritionMetrics? = nil,
        sourceType: String? = nil,
        feedbackEvidence: FeedbackEvidence? = nil,
        createdAt: Date? = nil,
        overallScore: Int? = nil,
        recommendationLevel: String? = nil,
        metricImpacts: [MetricImpact]? = nil,
        riskFacts: [RiskFact]? = nil,
        aiExplanation: AIExplanation? = nil,
        enhancedInsights: EnhancedInsights? = nil,
        categoryKey: String? = nil,
        categoryLabelEn: String? = nil,
        ruleVersion: String? = nil,
        nutritionVersion: String? = nil,
        satietyScore: Double? = nil,
        bloodSugarImpact: BloodSugarImpact? = nil,
        drvPercentages: [String: Double]? = nil
    ) {
        self.id = id
        self.recognizedName = recognizedName
        self.normalizedName = normalizedName
        self.edibleStatus = edibleStatus
        self.adviceLevel = adviceLevel
        self.adviceText = adviceText
        self.reasons = reasons
        self.foodScore = foodScore
        self.healthImpacts = healthImpacts
        self.nutritionSnapshot = nutritionSnapshot
        self.nutritionMetrics = nutritionMetrics
        self.sourceType = sourceType
        self.feedbackEvidence = feedbackEvidence
        self.createdAt = createdAt
        self.overallScore = overallScore
        self.recommendationLevel = recommendationLevel
        self.metricImpacts = metricImpacts
        self.riskFacts = riskFacts
        self.aiExplanation = aiExplanation
        self.enhancedInsights = enhancedInsights
        self.categoryKey = categoryKey
        self.categoryLabelEn = categoryLabelEn
        self.ruleVersion = ruleVersion
        self.nutritionVersion = nutritionVersion
        self.satietyScore = satietyScore
        self.bloodSugarImpact = bloodSugarImpact
        self.drvPercentages = drvPercentages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        recognizedName = try container.decode(String.self, forKey: .recognizedName)
        normalizedName = try container.decodeIfPresent(String.self, forKey: .normalizedName)
        edibleStatus = try container.decodeIfPresent(String.self, forKey: .edibleStatus)
        adviceLevel = try container.decodeIfPresent(String.self, forKey: .adviceLevel)
        adviceText = try container.decodeIfPresent(String.self, forKey: .adviceText)
        reasons = try container.decodeIfPresent([String].self, forKey: .reasons)
        foodScore = try container.decodeIfPresent(Int.self, forKey: .foodScore)
        healthImpacts = try container.decodeIfPresent([HealthImpact].self, forKey: .healthImpacts)
        nutritionSnapshot = try container.decodeIfPresent(NutritionSnapshot.self, forKey: .nutritionSnapshot)
        nutritionMetrics = try container.decodeIfPresent(NutritionMetrics.self, forKey: .nutritionMetrics)
        sourceType = try container.decodeIfPresent(String.self, forKey: .sourceType)
        feedbackEvidence = try container.decodeIfPresent(FeedbackEvidence.self, forKey: .feedbackEvidence)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        overallScore = try container.decodeIfPresent(Int.self, forKey: .overallScore)
        recommendationLevel = try container.decodeIfPresent(String.self, forKey: .recommendationLevel)
        metricImpacts = try container.decodeIfPresent([MetricImpact].self, forKey: .metricImpacts)
        riskFacts = try container.decodeIfPresent([RiskFact].self, forKey: .riskFacts)
        aiExplanation = try container.decodeIfPresent(AIExplanation.self, forKey: .aiExplanation)
        enhancedInsights = try container.decodeIfPresent(EnhancedInsights.self, forKey: .enhancedInsights)
        categoryKey = try container.decodeIfPresent(String.self, forKey: .categoryKey)
        categoryLabelEn = try container.decodeIfPresent(String.self, forKey: .categoryLabelEn)
        ruleVersion = try container.decodeIfPresent(String.self, forKey: .ruleVersion)
        nutritionVersion = try container.decodeIfPresent(String.self, forKey: .nutritionVersion)
        satietyScore = try container.decodeIfPresent(Double.self, forKey: .satietyScore)
        bloodSugarImpact = try container.decodeIfPresent(BloodSugarImpact.self, forKey: .bloodSugarImpact)
        drvPercentages = try container.decodeIfPresent([String: Double].self, forKey: .drvPercentages)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(recognizedName, forKey: .recognizedName)
        try container.encodeIfPresent(normalizedName, forKey: .normalizedName)
        try container.encodeIfPresent(edibleStatus, forKey: .edibleStatus)
        try container.encodeIfPresent(adviceLevel, forKey: .adviceLevel)
        try container.encodeIfPresent(adviceText, forKey: .adviceText)
        try container.encodeIfPresent(reasons, forKey: .reasons)
        try container.encodeIfPresent(foodScore, forKey: .foodScore)
        try container.encodeIfPresent(healthImpacts, forKey: .healthImpacts)
        try container.encodeIfPresent(nutritionSnapshot, forKey: .nutritionSnapshot)
        try container.encodeIfPresent(nutritionMetrics, forKey: .nutritionMetrics)
        try container.encodeIfPresent(sourceType, forKey: .sourceType)
        try container.encodeIfPresent(feedbackEvidence, forKey: .feedbackEvidence)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(overallScore, forKey: .overallScore)
        try container.encodeIfPresent(recommendationLevel, forKey: .recommendationLevel)
        try container.encodeIfPresent(metricImpacts, forKey: .metricImpacts)
        try container.encodeIfPresent(riskFacts, forKey: .riskFacts)
        try container.encodeIfPresent(aiExplanation, forKey: .aiExplanation)
        try container.encodeIfPresent(enhancedInsights, forKey: .enhancedInsights)
        try container.encodeIfPresent(categoryKey, forKey: .categoryKey)
        try container.encodeIfPresent(categoryLabelEn, forKey: .categoryLabelEn)
        try container.encodeIfPresent(ruleVersion, forKey: .ruleVersion)
        try container.encodeIfPresent(nutritionVersion, forKey: .nutritionVersion)
        try container.encodeIfPresent(satietyScore, forKey: .satietyScore)
        try container.encodeIfPresent(bloodSugarImpact, forKey: .bloodSugarImpact)
        try container.encodeIfPresent(drvPercentages, forKey: .drvPercentages)
    }

    // 便利属性：优先使用 v3 嵌套结构，降级到扁平 snapshot
    var effectiveNutrition: NutritionMetrics? {
        if let metrics = nutritionMetrics { return metrics }
        guard let snapshot = nutritionSnapshot else { return nil }
        return NutritionMetrics(
            servingSize: nil,
            nutrients: Nutrients(
                calories: NutrientValue(value: snapshot.calories ?? 0, unit: "kcal", dailyValuePercent: nil),
                protein: NutrientValue(value: snapshot.protein ?? 0, unit: "g", dailyValuePercent: nil),
                fat: NutrientValue(value: snapshot.fat ?? 0, unit: "g", dailyValuePercent: nil),
                saturatedFat: nil,
                transFat: nil,
                carbohydrates: NutrientValue(value: snapshot.carbs ?? 0, unit: "g", dailyValuePercent: nil),
                dietaryFiber: nil,
                sugar: nil,
                addedSugars: nil,
                cholesterol: nil,
                sodium: nil,
                vitamins: nil,
                minerals: nil
            ),
            vitamins: nil,
            minerals: nil,
            glycemicInfo: nil,
            allergens: nil,
            dietaryInfo: nil,
            preparation: nil,
            ingredients: nil,
            ingredientBreakdown: nil
        )
    }
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
    let labelEn: String?
    let level: String
    let reason: String
}

struct MetricImpact: Codable, Identifiable {
    var id: String { metric }

    let metric: String
    let label: String?
    let labelEn: String?
    let score: Int
    let weight: Double?
    let weightedScore: Double?
    let impactDirection: String? // "positive" / "neutral" / "negative"
}

struct RiskFact: Codable, Identifiable {
    var id: String { tag }

    let tag: String
    let label: String?
    let labelEn: String?
    let severity: String // "warning" / "danger"
    let description: String
    let descriptionEn: String?
    let affectedMetrics: [String]?
}

struct AIExplanation: Codable {
    let summary: String?
    let summaryEn: String?
    let detailedAdvice: String?
    let detailedAdviceEn: String?
    let healthTips: [String]?
    let healthTipsEn: [String]?
}

struct EnhancedInsights: Codable {
    let summary: String?
    let riskAnalysis: [String]?
    let healthWarnings: [String]?
    let substitutionSuggestions: [String]?
    let cookingTips: [String]?
    let detailedExplanation: String?
    let satietyScore: Double?
    let bloodSugarImpact: String?
    let nutrientDensityScore: Double?
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

enum FeedbackType: String, CaseIterable, Identifiable {
    case wrongFood = "wrong_food"
    case wrongName = "wrong_name"
    case wrongNutrition = "wrong_nutrition"
    case wrongCategory = "wrong_category"
    case addAlias = "add_alias"
    case newFood = "new_food"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wrongFood: return SafeEatL10n.text(L10nKey.Feedback.typeWrongFood)
        case .wrongName: return SafeEatL10n.text(L10nKey.Feedback.typeWrongName)
        case .wrongNutrition: return SafeEatL10n.text(L10nKey.Feedback.typeWrongNutrition)
        case .wrongCategory: return SafeEatL10n.text(L10nKey.Feedback.typeWrongCategory)
        case .addAlias: return SafeEatL10n.text(L10nKey.Feedback.typeAddAlias)
        case .newFood: return SafeEatL10n.text(L10nKey.Feedback.typeNewFood)
        case .other: return SafeEatL10n.text(L10nKey.Feedback.typeOther)
        }
    }
}
