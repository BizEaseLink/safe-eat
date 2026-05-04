import Foundation

struct AdConfigResponse: Decodable {
    let placements: [AdPlacementConfig]
}

struct AdPlacementConfig: Codable, Identifiable {
    var id: String { code }

    let code: String
    let slotId: String?
    let enabled: Bool
    let rewardQuota: Int
    let dailyLimit: Int
}

enum AdPlacementCode: String, CaseIterable {
    case rewardVideo = "reward_video"
    case splash = "splash"
    case interstitial = "interstitial"
    case native = "native"
    case banner = "banner"
}
