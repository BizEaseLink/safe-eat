import Foundation

// MARK: - 通知消息模型

struct NotificationMessage: Identifiable, Codable, Equatable {
    let id: String
    let type: String
    let title: String?
    let titleEn: String?
    let content: String?
    let contentEn: String?
    let actionType: String?
    let actionParams: [String: String]?
    let targetType: String?
    let targetParams: [String: String]?
    let enabled: Bool?
    let startsAt: String?
    let expiresAt: String?
    let createdAt: String?
    let updatedAt: String?
    let isRead: Bool
    let readAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, titleEn, content, contentEn
        case actionType, actionParams, targetType, targetParams
        case enabled, startsAt, expiresAt
        case createdAt, updatedAt, isRead, readAt
    }

    // 从后端 JSON 解码
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "marketing"
        title = try c.decodeIfPresent(String.self, forKey: .title)
        titleEn = try c.decodeIfPresent(String.self, forKey: .titleEn)
        content = try c.decodeIfPresent(String.self, forKey: .content)
        contentEn = try c.decodeIfPresent(String.self, forKey: .contentEn)
        actionType = try c.decodeIfPresent(String.self, forKey: .actionType) ?? "none"
        // actionParams: 兼容后端返回对象或字符串或 null
        actionParams = Self.decodeStringDict(from: c, forKey: .actionParams)
        targetType = try c.decodeIfPresent(String.self, forKey: .targetType)
        targetParams = Self.decodeStringDict(from: c, forKey: .targetParams)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? true
        startsAt = try c.decodeIfPresent(String.self, forKey: .startsAt)
        expiresAt = try c.decodeIfPresent(String.self, forKey: .expiresAt)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        isRead = try c.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        readAt = try c.decodeIfPresent(String.self, forKey: .readAt)
    }

    // 本地创建（NotificationStore 用）
    init(
        id: String, type: String,
        title: String?, titleEn: String?,
        content: String?, contentEn: String?,
        actionType: String?, actionParams: [String: String]?,
        targetType: String?, targetParams: [String: String]?,
        enabled: Bool?, startsAt: String?, expiresAt: String?,
        createdAt: String?, updatedAt: String?,
        isRead: Bool, readAt: String?
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.titleEn = titleEn
        self.content = content
        self.contentEn = contentEn
        self.actionType = actionType
        self.actionParams = actionParams
        self.targetType = targetType
        self.targetParams = targetParams
        self.enabled = enabled
        self.startsAt = startsAt
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isRead = isRead
        self.readAt = readAt
    }

    // 兼容后端返回对象 / JSON 字符串 / null
    private static func decodeStringDict(from c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> [String: String]? {
        // 1. 尝试直接解码为 [String: String]
        if let dict = try? c.decodeIfPresent([String: String].self, forKey: key) {
            return dict
        }
        // 2. 尝试解码为字符串，再 JSON 解析
        if let str = try? c.decodeIfPresent(String.self, forKey: key),
           let data = str.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String] {
            return dict
        }
        // 3. 尝试解码为 [String: Any] 再转 [String: String]（后端 JSON 列可能返回非 String 值）
        if let anyDict = try? c.decodeIfPresent([String: AnyCodableValue].self, forKey: key) {
            return anyDict.mapValues { $0.stringValue }
        }
        return nil
    }

    // 中文类型标签
    var typeLabel: String {
        switch type {
        case "marketing": return "营销"
        case "app_update": return "更新"
        case "disclosure_update": return "协议"
        case "food_safety_alert": return "安全"
        case "feedback_resolved": return "反馈"
        case "feedback_reward": return "奖励"
        case "annual_report": return "年报"
        default: return "通知"
        }
    }

    // 英文类型标签
    var enTypeLabel: String {
        switch type {
        case "marketing": return "Marketing"
        case "app_update": return "Update"
        case "disclosure_update": return "Policy"
        case "food_safety_alert": return "Safety"
        case "feedback_resolved": return "Feedback"
        case "feedback_reward": return "Reward"
        case "annual_report": return "Annual"
        default: return "Notice"
        }
    }

    // 类型标签颜色
    var typeColor: (bg: String, fg: String) {
        switch type {
        case "marketing": return ("#DBEAFE", "#1D4ED8")
        case "app_update": return ("#CFFAFE", "#0E7490")
        case "disclosure_update": return ("#EDE9FE", "#6D28D9")
        case "food_safety_alert": return ("#FEE2E2", "#DC2626")
        case "feedback_resolved": return ("#D1FAE5", "#059669")
        case "feedback_reward": return ("#FEF3C7", "#D97706")
        case "annual_report": return ("#E0E7FF", "#4338CA")
        default: return ("#F3F4F6", "#4B5563")
        }
    }
}

// 用于解码 JSON 中可能包含非 String 值的字典
private struct AnyCodableValue: Codable {
    let stringValue: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            stringValue = s
        } else if let i = try? container.decode(Int.self) {
            stringValue = String(i)
        } else if let d = try? container.decode(Double.self) {
            stringValue = String(d)
        } else if let b = try? container.decode(Bool.self) {
            stringValue = String(b)
        } else {
            stringValue = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

// MARK: - 未读数响应

struct UnreadCountResponse: Codable {
    let count: Int

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        count = try c.decodeIfPresent(Int.self, forKey: .count) ?? 0
    }
}
