import SwiftUI

/// 消息列表视图（已合并到 MessageCenterView，此文件保留供外部引用兼容）
struct MessageListView: View {
    @ObservedObject var notificationStore: NotificationStore
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    let onNavigateAction: (([String: String]?) -> Void)?
    let onShowDisclosure: ((String) -> Void)?

    var body: some View {
        Group {
            if notificationStore.messages.isEmpty && !notificationStore.isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "bell.slash")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.4))
                    Text(SafeEatL10n.text(L10nKey.Message.emptyTitle))
                        .font(SafeEatFont.custom(18, relativeTo: .title3))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notificationStore.messages) { message in
                            MessageRowView(message: message) {
                                handleMessageTap(message)
                            }
                        }

                        if notificationStore.hasMore {
                            ProgressView()
                                .padding(.vertical, 20)
                                .task {
                                    guard let token = store.session?.accessToken else { return }
                                    await notificationStore.fetchMessages(accessToken: token, refresh: false)
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func handleMessageTap(_ message: NotificationMessage) {
        guard let token = store.session?.accessToken else { return }

        if !message.isRead {
            Task { await notificationStore.markAsRead(accessToken: token, notificationId: message.id) }
        }

        switch message.actionType {
        case "navigate":
            onNavigateAction?(message.actionParams)
        case "open_url":
            if let urlString = message.actionParams?["url"],
               let url = URL(string: urlString),
               let scheme = url.scheme?.lowercased(),
               scheme == "https" || scheme == "http" {
                #if canImport(UIKit)
                UIApplication.shared.open(url)
                #endif
            }
        case "show_disclosure":
            let category = message.actionParams?["category"] ?? "privacy_policy"
            onShowDisclosure?(category)
        default:
            break
        }
    }
}
