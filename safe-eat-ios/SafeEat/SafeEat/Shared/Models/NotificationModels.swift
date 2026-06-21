import Foundation

struct NotificationMessage: Identifiable, Codable {
    let id: String
    let type: String
    let title: String
    let titleEn: String
    let content: String
    let contentEn: String
    let actionType: String
    let actionParams: [String: String]?
    let isRead: Bool
    let readAt: String?
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case id, type, title, titleEn, content, contentEn
        case actionType, actionParams, isRead, readAt, createdAt
    }
}

struct UnreadCountResponse: Decodable {
    let count: Int
}

// MARK: - 显示辅助（在 View 层使用）

extension NotificationMessage {
    /// 根据当前语言返回对应标题
    var displayTitle: String {
        SafeEatL10n.isZh ? title : titleEn
    }

    /// 根据当前语言返回对应内容
    var displayContent: String {
        SafeEatL10n.isZh ? content : contentEn
    }

    /// 消息类型的本地化显示名
    var typeLabel: String {
        switch type {
        case "marketing":
            return SafeEatL10n.text(L10nKey.Message.typeMarketing)
        case "app_update":
            return SafeEatL10n.text(L10nKey.Message.typeAppUpdate)
        case "disclosure_update":
            return SafeEatL10n.text(L10nKey.Message.typeDisclosureUpdate)
        case "food_safety_alert":
            return SafeEatL10n.text(L10nKey.Message.typeFoodSafetyAlert)
        case "feedback_resolved":
            return SafeEatL10n.text(L10nKey.Message.typeFeedbackResolved)
        case "feedback_reward":
            return SafeEatL10n.text(L10nKey.Message.typeFeedbackReward)
        case "annual_report":
            return SafeEatL10n.text(L10nKey.Message.typeAnnualReport)
        default:
            return SafeEatL10n.text(L10nKey.Message.typeMarketing)
        }
    }
}
