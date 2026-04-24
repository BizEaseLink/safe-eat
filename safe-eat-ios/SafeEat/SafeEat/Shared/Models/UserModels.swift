import Foundation

struct UserProfile: Codable {
    let id: String
    let appId: String?
    let phone: String?
    let displayName: String?
    let gender: String?
    let heightCm: Double?
    let weightKg: Double?
    let bmi: Double?
    let avatarObjectId: String?
    let avatarUrl: String?
    let huaweiOpenId: String?
    let huaweiUnionId: String?
    let currentPlanTier: String?
    let healthTags: [String]?
    let fitnessGoal: String?
    let avoidIngredients: [String]?
    let dietaryPreferences: [String]?
    let status: String?
    let lastLoginAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

struct MembershipPlan: Codable, Identifiable {
    let id: String
    let tier: String
    let billingCycle: String
    let name: String
    let priceFen: Int
    let dailyQuota: Int?
    let active: Bool?
}

struct MembershipPlanListResponse: Codable {
    let items: [MembershipPlan]
}

struct UserProfileUpdatePayload: Encodable {
    let displayName: String?
    let gender: String?
    let heightCm: Double?
    let weightKg: Double?
    let healthTags: [String]?
    let fitnessGoal: String?
    let avoidIngredients: [String]?
    let dietaryPreferences: [String]?
}

struct UserHealthProfileUpdatePayload: Encodable {
    let healthTags: [String]?
    let fitnessGoal: String?
    let avoidIngredients: [String]?
    let dietaryPreferences: [String]?
}

struct MembershipOrderPayload: Encodable {
    let planId: String
    let channel: String
}

struct MembershipOrderResult: Codable, Identifiable {
    let id: String
    let orderNo: String
    let planId: String
    let planTier: String
    let channel: String
    let amountFen: Int
    let status: String
    let createdAt: Date
}

extension MembershipPlan {
    var localizedDisplayName: String {
        guard tier != "free" else {
            return PlanTierMapper.title(tier)
        }

        let cycleTitle = billingCycle == "yearly"
            ? SafeEatL10n.text(L10nKey.Membership.cycleYearly)
            : SafeEatL10n.text(L10nKey.Membership.cycleMonthly)

        return SafeEatL10n.format(L10nKey.Membership.planNameFormat, PlanTierMapper.title(tier), cycleTitle)
    }
}

extension UserProfile {
    var displayNameOrFallback: String {
        if let displayName, !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return displayName
        }

        return SafeEatL10n.text(L10nKey.User.unnamed)
    }

    var avatarRemoteURL: URL? {
        AppConfig.resolveRemoteURL(path: avatarUrl)
    }
}

enum PlanTierMapper {
    static func title(_ tier: String?) -> String {
        switch tier {
        case "lite":
            return SafeEatL10n.text(L10nKey.User.tierLiteTitle)
        case "pro":
            return SafeEatL10n.text(L10nKey.User.tierProTitle)
        default:
            return SafeEatL10n.text(L10nKey.User.tierFreeTitle)
        }
    }

    static func shortTitle(_ tier: String?) -> String {
        switch tier {
        case "lite":
            return SafeEatL10n.text(L10nKey.User.tierLiteShort)
        case "pro":
            return SafeEatL10n.text(L10nKey.User.tierProShort)
        default:
            return SafeEatL10n.text(L10nKey.User.tierFreeShort)
        }
    }
}

enum UserGenderMapper {
    static func title(_ gender: String?) -> String {
        switch gender {
        case "male":
            return SafeEatL10n.text(L10nKey.User.genderMale)
        case "female":
            return SafeEatL10n.text(L10nKey.User.genderFemale)
        case "other":
            return SafeEatL10n.text(L10nKey.User.genderOther)
        default:
            return SafeEatL10n.text(L10nKey.Common.notSet)
        }
    }
}

enum HealthTagMapper {
    static let allTags = [
        "high_blood_pressure",
        "high_blood_sugar",
        "high_blood_lipids",
        "weight_loss",
        "muscle_gain",
        "general_wellness",
    ]

    static func title(_ tag: String) -> String {
        switch tag {
        case "high_blood_pressure":
            return SafeEatL10n.text(L10nKey.User.healthPressure)
        case "high_blood_sugar":
            return SafeEatL10n.text(L10nKey.User.healthSugar)
        case "high_blood_lipids":
            return SafeEatL10n.text(L10nKey.User.healthLipids)
        case "weight_loss":
            return SafeEatL10n.text(L10nKey.User.healthWeightLoss)
        case "muscle_gain":
            return SafeEatL10n.text(L10nKey.User.healthMuscle)
        default:
            return SafeEatL10n.text(L10nKey.User.healthWellness)
        }
    }
}

enum FitnessGoalMapper {
    static let allGoals = [
        "balanced",
        "fat_loss",
        "muscle_gain",
        "blood_sugar_control",
        "cardiovascular_health",
    ]

    static func title(_ goal: String?) -> String {
        switch goal {
        case "fat_loss":
            return SafeEatL10n.text(L10nKey.User.goalFatLoss)
        case "muscle_gain":
            return SafeEatL10n.text(L10nKey.User.goalMuscle)
        case "blood_sugar_control":
            return SafeEatL10n.text(L10nKey.User.goalSugar)
        case "cardiovascular_health":
            return SafeEatL10n.text(L10nKey.User.goalCardio)
        case "balanced":
            return SafeEatL10n.text(L10nKey.User.goalBalanced)
        default:
            return SafeEatL10n.text(L10nKey.Common.notSet)
        }
    }
}

enum PaymentChannelMapper {
    static let allChannels = ["wechat", "alipay"]

    static func title(_ channel: String) -> String {
        switch channel {
        case "alipay":
            return SafeEatL10n.text(L10nKey.User.paymentAlipay)
        default:
            return SafeEatL10n.text(L10nKey.User.paymentWechat)
        }
    }
}
