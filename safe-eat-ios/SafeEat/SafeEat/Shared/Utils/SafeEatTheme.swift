import SwiftUI
import UIKit

enum SafeEatTheme {
    static let primaryDeep = Color(hex: 0x1D5D43)
    static let primary = Color(hex: 0x2E7D5A)
    static let primarySoft = Color(hex: 0xDFF2E7)
    static let accent = Color(hex: 0xB9DEC4)

    static let success = Color(hex: 0x3D9B62)
    static let warning = Color(hex: 0xD6A545)
    static let danger = Color(hex: 0xC95B44)

    static let textPrimary = Color(dynamicLight: 0x19342C, dark: 0xF3F6F4)
    static let textSecondary = Color(dynamicLight: 0x60746D, dark: 0xC3CBC8)
    static let line = Color(dynamicLight: 0x19342C, dark: 0xFFFFFF, lightOpacity: 0.10, darkOpacity: 0.08)

    static let primaryDeepUIColor = UIColor(hex: 0x1D5D43)
    static let primaryUIColor = UIColor(hex: 0x2E7D5A)
    static let primarySoftUIColor = UIColor(hex: 0xDFF2E7)
    static let accentUIColor = UIColor(hex: 0xB9DEC4)
    static let successUIColor = UIColor(hex: 0x3D9B62)
    static let warningUIColor = UIColor(hex: 0xD6A545)
    static let dangerUIColor = UIColor(hex: 0xC95B44)
    static let textPrimaryUIColor = UIColor(dynamicLight: 0x19342C, dark: 0xF3F6F4)
    static let textSecondaryUIColor = UIColor(dynamicLight: 0x60746D, dark: 0xC3CBC8)
}

private extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }

    init(dynamicLight lightHex: UInt32, dark darkHex: UInt32, lightOpacity: Double = 1, darkOpacity: Double = 1) {
        self.init(
            uiColor: UIColor { trait in
                UIColor(
                    hex: trait.userInterfaceStyle == .dark ? darkHex : lightHex,
                    alpha: trait.userInterfaceStyle == .dark ? darkOpacity : lightOpacity
                )
            }
        )
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    convenience init(dynamicLight lightHex: UInt32, dark darkHex: UInt32) {
        self.init { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? darkHex : lightHex)
        }
    }
}
