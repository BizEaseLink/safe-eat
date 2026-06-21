import Foundation
import Combine

@MainActor
final class NotificationStore: ObservableObject {
    private let api: SafeEatAPI

    @Published var unreadCount: Int = 0
    @Published var messages: [NotificationMessage] = []
    @Published var isLoading: Bool = false
    @Published var page: Int = 1
    @Published var total: Int = 0
    @Published var filterType: String? = nil

    var hasMore: Bool { messages.count < total }

    // 本地已读缓存：纯本地管理，不依赖后端 API
    // 逻辑：本地标记已读 → 远程拉取时按本地已读集合覆盖显示
    //       刷新后清理不在当前列表中的旧 id
    private var localReadIds: Set<String> = []

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init(api: SafeEatAPI = SafeEatAPI()) {
        self.api = api
    }

    func fetchUnreadCount(accessToken: String) async {
        do {
            let response = try await api.getUnreadCount(accessToken: accessToken)
            // 远程未读数减去本地已读数，避免重复计数
            let localReadInRemote = messages.filter { localReadIds.contains($0.id) && !$0.isRead }.count
            unreadCount = max(0, response.count - localReadInRemote)
        } catch {
            #if DEBUG
            print("[NotificationStore] fetchUnreadCount failed: \(error)")
            #endif
        }
    }

    func fetchMessages(accessToken: String, refresh: Bool = true) async {
        isLoading = true
        defer { isLoading = false }

        let targetPage = refresh ? 1 : page + 1

        do {
            let result = try await api.getNotifications(
                accessToken: accessToken,
                page: targetPage,
                pageSize: 20,
                type: filterType
            )
            // 远程拉取后，按本地已读缓存覆盖 isRead 状态
            let adjusted = result.items.map { msg -> NotificationMessage in
                if localReadIds.contains(msg.id) && !msg.isRead {
                    return NotificationMessage(
                        id: msg.id, type: msg.type,
                        title: msg.title, titleEn: msg.titleEn,
                        content: msg.content, contentEn: msg.contentEn,
                        actionType: msg.actionType, actionParams: msg.actionParams,
                        targetType: msg.targetType, targetParams: msg.targetParams,
                        enabled: msg.enabled, startsAt: msg.startsAt, expiresAt: msg.expiresAt,
                        createdAt: msg.createdAt, updatedAt: msg.updatedAt,
                        isRead: true, readAt: msg.readAt ?? Self.isoFormatter.string(from: Date())
                    )
                }
                return msg
            }

            // 清理本地已读列表中不在当前消息列表里的 id（消息已被30天清理或过期删除）
            let currentIds = Set(adjusted.map { $0.id })
            localReadIds = localReadIds.intersection(currentIds)

            if refresh {
                messages = adjusted
            } else {
                messages.append(contentsOf: adjusted)
            }
            page = targetPage
            total = result.total

            // 重新计算本地未读数
            unreadCount = adjusted.filter { !$0.isRead }.count
        } catch {
            #if DEBUG
            print("[NotificationStore] fetchMessages failed: \(error)")
            #endif
        }
    }

    func markAsRead(accessToken: String, notificationId: String) async {
        // 已本地标记为已读，跳过
        if localReadIds.contains(notificationId),
           let msg = messages.first(where: { $0.id == notificationId }), msg.isRead {
            return
        }

        // 先本地标记，确保 UI 立即响应
        localReadIds.insert(notificationId)
        if let index = messages.firstIndex(where: { $0.id == notificationId }) {
            let msg = messages[index]
            if !msg.isRead {
                messages[index] = NotificationMessage(
                    id: msg.id, type: msg.type,
                    title: msg.title, titleEn: msg.titleEn,
                    content: msg.content, contentEn: msg.contentEn,
                    actionType: msg.actionType, actionParams: msg.actionParams,
                    targetType: msg.targetType, targetParams: msg.targetParams,
                    enabled: msg.enabled, startsAt: msg.startsAt, expiresAt: msg.expiresAt,
                    createdAt: msg.createdAt, updatedAt: msg.updatedAt,
                    isRead: true, readAt: Self.isoFormatter.string(from: Date())
                )
                if unreadCount > 0 { unreadCount -= 1 }
            }
        }

        // 异步同步到服务器（失败不影响本地已读状态）
        do {
            try await api.markNotificationRead(accessToken: accessToken, notificationId: notificationId)
        } catch {
            #if DEBUG
            print("[NotificationStore] markAsRead API failed (本地已标记，不影响): \(error)")
            #endif
        }
    }

    func markAllAsRead(accessToken: String) async {
        // 先本地标记所有消息为已读（纯本地操作，不依赖后端）
        let now = Self.isoFormatter.string(from: Date())
        for msg in messages {
            localReadIds.insert(msg.id)
        }
        messages = messages.map { msg in
            if msg.isRead { return msg }
            return NotificationMessage(
                id: msg.id, type: msg.type,
                title: msg.title, titleEn: msg.titleEn,
                content: msg.content, contentEn: msg.contentEn,
                actionType: msg.actionType, actionParams: msg.actionParams,
                targetType: msg.targetType, targetParams: msg.targetParams,
                enabled: msg.enabled, startsAt: msg.startsAt, expiresAt: msg.expiresAt,
                createdAt: msg.createdAt, updatedAt: msg.updatedAt,
                isRead: true, readAt: now
            )
        }
        unreadCount = 0

        // 异步同步到服务器（失败不影响本地已读状态）
        do {
            try await api.markAllNotificationsRead(accessToken: accessToken)
        } catch {
            #if DEBUG
            print("[NotificationStore] markAllAsRead API failed (本地已标记，不影响): \(error)")
            #endif
        }
    }

    /// 清空本地已读缓存，恢复全部消息为未读状态
    func resetAllRead() {
        localReadIds.removeAll()
        messages = messages.map { msg in
            if !msg.isRead { return msg }
            return NotificationMessage(
                id: msg.id, type: msg.type,
                title: msg.title, titleEn: msg.titleEn,
                content: msg.content, contentEn: msg.contentEn,
                actionType: msg.actionType, actionParams: msg.actionParams,
                targetType: msg.targetType, targetParams: msg.targetParams,
                enabled: msg.enabled, startsAt: msg.startsAt, expiresAt: msg.expiresAt,
                createdAt: msg.createdAt, updatedAt: msg.updatedAt,
                isRead: false, readAt: nil
            )
        }
        unreadCount = messages.count
    }
}
