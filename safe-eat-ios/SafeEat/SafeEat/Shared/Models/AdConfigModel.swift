import Foundation

struct AdConfigResponse: Decodable {
    let placements: [AdPlacementConfig]
    let configParams: AdsConfigParams?
}

struct AdsConfigParams: Codable {
    let rewardQuota: Int
    let dailyLimit: Int
    let floatWindowDailyLimit: Int
    let floatWindowInterval: Int
}

struct AdPlacementConfig: Codable, Identifiable {
    var id: String { code }

    let code: String
    let slotId: String?
    let enabled: Bool
}

enum AdPlacementCode: String, CaseIterable {
    case rewardVideo = "reward_video"
    case splash = "splash"
    case interstitial = "interstitial"
    case native = "native"
    case banner = "banner"
    case floatWindow = "float_window"
}
