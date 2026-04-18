import Foundation
import CoreGraphics

enum AppConfig {
    static let appCode = "safe-eat"
    static let apiBaseURL = URL(string: "http://192.168.31.123:3000/api")!
    static let imageCompressionQuality: CGFloat = 0.9
    static let historyFileName = "safe-eat-history.json"
    static let historyImageFolder = "SafeEatHistoryImages"
}
