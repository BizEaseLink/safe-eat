import UIKit

enum UMengConfig {
    static let appKey = "69f4675e9a7f376488d17f59"

    enum SlotId {
        static var rewardVideo: String {
            AdConfigStore.shared.slotId(for: .rewardVideo)
                ?? "100009245"
        }

        static var splash: String {
            AdConfigStore.shared.slotId(for: .splash)
                ?? "100009243"
        }

        static var native: String {
            AdConfigStore.shared.slotId(for: .native)
                ?? "100009241"
        }
    }
}
