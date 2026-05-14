import UIKit

enum UMengConfig {
    static let appKey: String = {
        Bundle.main.infoDictionary?["UMengAppKey"] as? String ?? ""
    }()

    enum SlotId {
        static var rewardVideo: String {
            AdConfigStore.shared.slotId(for: .rewardVideo)
                ?? "100009245"
        }

        static var splash: String {
            AdConfigStore.shared.slotId(for: .splash) ?? ""
        }

        static var native: String {
            AdConfigStore.shared.slotId(for: .native)
                ?? "100009241"
        }

        static var banner: String {
            AdConfigStore.shared.slotId(for: .banner)
                ?? "100009250"
        }

        static var interstitial: String {
            AdConfigStore.shared.slotId(for: .interstitial)
                ?? "100009251"
        }

        static var floatWindow: String {
            AdConfigStore.shared.slotId(for: .floatWindow)
                ?? "100009243"
        }
    }
}
