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

    var hasMore: Bool { messages.count < total }

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
            unreadCount = response.count
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
                type: nil
            )
            if refresh {
                messages = result.items
            } else {
                messages.append(contentsOf: result.items)
            }
            page = targetPage
            total = result.total
        } catch {
            #if DEBUG
            print("[NotificationStore] fetchMessages failed: \(error)")
            #endif
        }
    }

    func markAsRead(accessToken: String, notificationId: String) async {
        do {
            try await api.markNotificationRead(accessToken: accessToken, notificationId: notificationId)
            if let index = messages.firstIndex(where: { $0.id == notificationId }) {
                let msg = messages[index]
                messages[index] = NotificationMessage(
                    id: msg.id, type: msg.type,
                    title: msg.title, titleEn: msg.titleEn,
                    content: msg.content, contentEn: msg.contentEn,
                    actionType: msg.actionType, actionParams: msg.actionParams,
                    isRead: true, readAt: Self.isoFormatter.string(from: Date()),
                    createdAt: msg.createdAt
                )
            }
            if unreadCount > 0 {
                unreadCount -= 1
            }
        } catch {
            #if DEBUG
            print("[NotificationStore] markAsRead failed: \(error)")
            #endif
        }
    }

    func markAllAsRead(accessToken: String) async {
        do {
            try await api.markAllNotificationsRead(accessToken: accessToken)
            let now = Self.isoFormatter.string(from: Date())
            messages = messages.map { msg in
                NotificationMessage(
                    id: msg.id, type: msg.type,
                    title: msg.title, titleEn: msg.titleEn,
                    content: msg.content, contentEn: msg.contentEn,
                    actionType: msg.actionType, actionParams: msg.actionParams,
                    isRead: true, readAt: now,
                    createdAt: msg.createdAt
                )
            }
            unreadCount = 0
        } catch {
            #if DEBUG
            print("[NotificationStore] markAllAsRead failed: \(error)")
            #endif
        }
    }
}
