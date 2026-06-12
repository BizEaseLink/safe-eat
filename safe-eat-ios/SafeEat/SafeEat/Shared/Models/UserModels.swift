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

struct MembershipPlan: Decodable, Identifiable {
    let id: String
    let tier: String
    let billingCycle: String
    let name: String
    let priceFen: Int
    let dailyQuota: Int?
    let recognitionQuota: Int?
    let aiQuota: Int?
    let active: Bool?
    // C2 扩展字段
    let appleProductId: String?
    let recognitionQuotaMonthly: Int?
    let aiQuotaMonthly: Int?
    let priceDisplay: String?
    let sortOrder: Int?
    let yearlyPriceFen: Int?
    // v3 新增：权益描述（后端动态配置，优先展示）
    let benefitsDescription: String?
    // v3 新增：套餐差异化权益
    let aiAdviceLevel: String?
    let maxHealthProfiles: Int?
    let maxHistoryRecords: Int?
    // 每个套餐适用的活动（已过滤叠加）
    let applicableCampaigns: [CampaignBenefit]?
}

// MARK: - 活动权益

struct CampaignBenefit: Decodable, Identifiable {
    let id: String
    let name: String
    let type: String
    let bonusDays: Int?
    let bonusRecognitionQuota: Int?
    let bonusAiQuota: Int?
    let targetPlanIds: [String]?
    let targetUserType: String?
    let endAt: Date?
    let planBonus: [CampaignPlanBonus]?

    /// 兼容旧字段名
    var endsAt: Date? { endAt }
}

// MARK: - 按套餐差异化赠送

struct CampaignPlanBonus: Codable, Identifiable {
    var id: String { planId }
    let planId: String
    let bonusDays: Int?
    let bonusRecognitionQuota: Int?
    let bonusAiQuota: Int?
}

// MARK: - 首购赠送
// 后端在 Apple Server Notification 处理中自动发放首购赠送（CampaignBenefitService.applyFirstPurchaseBonus）
// iOS 端通过 /membership/plans 的 campaigns 中 type=first_purchase 获取活动信息
// 购买成功后刷新会员状态，通过 firstPurchaseBonusClaimed 字段判断是否获得赠送

// MARK: - 会员状态

struct MembershipStatus: Codable {
    let planLevel: String
    let source: String?
    let entitlementExpiresAt: Date?
    let bonusRecognitionQuota: Int?
    let bonusAiQuota: Int?
    let status: String?
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

// MARK: - IAP 交易验证（C5: verify-transaction）

struct IAPVerifyTransactionPayload: Encodable {
    let transactionId: String
    let orderId: String?
    let productId: String?

    init(transactionId: String, orderId: String? = nil, productId: String? = nil) {
        self.transactionId = transactionId
        self.orderId = orderId
        self.productId = productId
    }
}

struct IAPVerifyTransactionResult: Decodable {
    let success: Bool
    let idempotent: Bool
    let transactionId: String
}

// MARK: - 兑换码使用（新 Redeem API）

struct RedeemCodePayload: Encodable {
    let code: String
}

struct RedeemCodeResult: Decodable {
    let success: Bool
    let campaignName: String?
    let granted: RedeemGranted?
    let membershipEndsAt: Date?
}

struct RedeemGranted: Decodable {
    let days: Int
    let recognitionQuota: Int
    let aiQuota: Int
}

// MARK: - 会员权益查询（/membership/me）

struct MembershipMeResult: Decodable {
    let active: Bool?
    let planId: String?
    let tier: String?
    let billingCycle: String?
    let planName: String?
    let startsAt: Date?
    let endsAt: Date?
    let dailyQuota: Int?
    let recognitionQuotaMonthly: Int?
    let aiQuotaMonthly: Int?
    let bonusDays: Int?
    let bonusRecognitionQuota: Int?
    let bonusAiQuota: Int?
    let autoRenew: Bool?
    let trialUsed: Bool?
    let isTrial: Bool?
    let trialEndDate: Date?
    let firstPurchaseBonusClaimed: Bool?

    /// 旧字段兼容：planLevel 映射到 tier
    var planLevel: String? { tier }
    /// 旧字段兼容：source 映射到 billingCycle
    var source: String? { billingCycle }
    /// 旧字段兼容：entitlementExpiresAt 映射到 endsAt
    var entitlementExpiresAt: Date? { endsAt }
    /// 旧字段兼容：status 基于 active 推导
    var status: String? {
        guard let active else { return nil }
        return active ? "active" : "expired"
    }
}

// MARK: - 可用活动查询（/campaigns/available）

struct AvailableCampaign: Codable, Identifiable {
    let id: String
    let name: String
    let type: String
    let description: String?
    let benefitPreview: CampaignBenefitPreview?
    let endAt: Date?

    var endsAt: Date? { endAt }
}

struct CampaignBenefitPreview: Codable {
    let grantedDays: Int
    let grantedRecognitionQuota: Int
    let grantedAiQuota: Int
}

// MARK: - 领取活动权益（/campaigns/:id/claim）

struct ClaimCampaignPayload: Encodable {
    let discountCode: String?
}

// MARK: - 广告奖励领取

struct ClaimAdRewardPayload: Encodable {
    let placementCode: String
    let proofToken: String
}

struct ClaimAdRewardResult: Decodable {
    let rewardLog: AdRewardLog
    let quota: AdRewardQuota
}

struct AdRewardLog: Decodable {
    let id: String
    let placementId: String
    let proofToken: String
    let rewardQuota: Int
    let claimedOn: String
}

struct AdRewardQuota: Decodable {
    let id: String
    let totalQuota: Int
    let usedCount: Int
    let adClaimsCount: Int
}

// MARK: - 每日配额快照

struct DailyQuotaSnapshot: Decodable {
    let planTier: String
    let totalQuota: Int
    let usedCount: Int
    let remainingQuota: Int
    let adClaimsCount: Int
    let adRewardPerWatch: Int?
    let adWatchLimit: Int?
    let remainingAdWatchCount: Int?
    let quotaDate: String
    let monthlyTotalQuota: Int?
    let monthlyUsedCount: Int?
    let monthlyRemaining: Int?
    let periodStart: String?
    let periodEnd: String?
}

// MARK: - 订单记录

struct OrderRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let planId: String
    let orderNo: String
    let planTier: String
    let channel: String
    let amountFen: Int
    let status: String
    let paidAt: Date?
    let createdAt: Date
}

enum OrderStatusMapper {
    static func title(_ status: String) -> String {
        switch status {
        case "pending":
            return SafeEatL10n.text(L10nKey.Order.statusPending)
        case "paid":
            return SafeEatL10n.text(L10nKey.Order.statusPaid)
        case "failed":
            return SafeEatL10n.text(L10nKey.Order.statusFailed)
        case "cancelled":
            return SafeEatL10n.text(L10nKey.Order.statusCancelled)
        default:
            return status
        }
    }
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
    enum Tier {
        case free, lite, pro, premium
    }

    static func map(_ tier: String?) -> Tier {
        switch tier {
        case "lite": return .lite
        case "pro": return .pro
        case "premium": return .premium
        default: return .free
        }
    }

    static func title(_ tier: String?) -> String {
        switch tier {
        case "lite":
            return SafeEatL10n.text(L10nKey.User.tierLiteTitle)
        case "pro":
            return SafeEatL10n.text(L10nKey.User.tierProTitle)
        case "premium":
            return SafeEatL10n.text(L10nKey.User.tierPremiumTitle)
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
        case "premium":
            return SafeEatL10n.text(L10nKey.User.tierPremiumShort)
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
        case "general_wellness":
            return SafeEatL10n.text(L10nKey.User.healthWellness)
        default:
            return tag
        }
    }
}

enum FitnessGoalMapper {
    static let allGoals = [
        "balanced",
        "fat_loss",
        "muscle_gain",
        "blood_sugar_control",
    ]

    static func title(_ goal: String?) -> String {
        switch goal {
        case "fat_loss":
            return SafeEatL10n.text(L10nKey.User.goalFatLoss)
        case "muscle_gain":
            return SafeEatL10n.text(L10nKey.User.goalMuscle)
        case "blood_sugar_control":
            return SafeEatL10n.text(L10nKey.User.goalSugar)
        case "balanced":
            return SafeEatL10n.text(L10nKey.User.goalBalanced)
        default:
            return SafeEatL10n.text(L10nKey.Common.notSet)
        }
    }
}

enum PaymentChannelMapper {
    static let allChannels = ["wechat", "alipay", "apple_iap"]

    static func title(_ channel: String) -> String {
        switch channel {
        case "alipay":
            return SafeEatL10n.text(L10nKey.User.paymentAlipay)
        case "apple_iap":
            return SafeEatL10n.text(L10nKey.User.paymentAppleIAP)
        default:
            return SafeEatL10n.text(L10nKey.User.paymentWechat)
        }
    }
}

enum AiAdviceLevelMapper {
    static func title(_ level: String) -> String {
        switch level {
        case "basic":
            return "简版"
        case "advanced":
            return "高级版"
        case "expert":
            return "专家版"
        default:
            return level
        }
    }
}
