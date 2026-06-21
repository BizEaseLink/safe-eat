import SwiftUI

/// 消息列表视图 — 在 MessageCenterView 内部使用
struct MessageListView: View {
    @ObservedObject var notificationStore: NotificationStore
    @EnvironmentObject private var store: AppStore
    let onNavigateAction: (([String: String]?) -> Void)?
    let onShowDisclosure: ((String) -> Void)?

    var body: some View {
        Group {
            if notificationStore.messages.isEmpty && !notificationStore.isLoading {
                emptyView
            } else {
                listContent
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))
            Text(SafeEatL10n.text(L10nKey.Message.emptyTitle))
                .font(SafeEatFont.custom(18, relativeTo: .title3))
                .foregroundStyle(SafeEatTheme.textSecondary)
            Text(SafeEatL10n.text(L10nKey.Message.emptySubtitle))
                .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(notificationStore.messages) { message in
                    MessageRowView(message: message) {
                        handleMessageTap(message)
                    }

                    if message.id != notificationStore.messages.last?.id {
                        Divider()
                            .padding(.leading, 36)
                    }
                }

                if notificationStore.hasMore {
                    ProgressView()
                        .padding(.vertical, 16)
                        .task {
                            guard let token = store.session?.accessToken else { return }
                            await notificationStore.fetchMessages(accessToken: token, refresh: false)
                        }
                }
            }
        }
    }

    private func handleMessageTap(_ message: NotificationMessage) {
        guard let token = store.session?.accessToken else { return }

        if !message.isRead {
            Task {
                await notificationStore.markAsRead(accessToken: token, notificationId: message.id)
            }
        }

        switch message.actionType {
        case "navigate":
            onNavigateAction?(message.actionParams)
        case "open_url":
            if let urlString = message.actionParams?["url"],
               let url = URL(string: urlString) {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #endif
            }
        case "show_disclosure":
            let category = message.actionParams?["category"] ?? "privacy_policy"
            onShowDisclosure?(category)
        case "none", _:
            break
        }
    }
}
