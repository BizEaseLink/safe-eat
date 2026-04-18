import Foundation

struct UserProfile: Codable {
    let id: String
    let appId: String
    let phone: String
    let currentPlanTier: String?
    let healthTags: [String]?
    let fitnessGoal: String?
    let avoidIngredients: [String]?
    let dietaryPreferences: [String]?
}

struct MembershipPlan: Codable, Identifiable {
    let id: String
    let tier: String
    let billingCycle: String
    let title: String?
    let description: String?
    let priceFen: Int
    let marketPriceFen: Int?
}

struct MembershipPlanListResponse: Codable {
    let items: [MembershipPlan]
}
