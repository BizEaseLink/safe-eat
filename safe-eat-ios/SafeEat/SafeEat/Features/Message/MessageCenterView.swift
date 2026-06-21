import SwiftUI

struct MessageCenterView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showDisclosureSheet = false
    @State private var disclosureCategory: String?

    var body: some View {
        MessageListView(
            notificationStore: store.notificationStore,
            onNavigateAction: { params in
                handleNavigateAction(params)
            },
            onShowDisclosure: { category in
                disclosureCategory = category
                showDisclosureSheet = true
            }
        )
        .navigationTitle(SafeEatL10n.text(L10nKey.Message.centerTitle))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.notificationUnreadCount > 0 {
                    Button {
                        markAllRead()
                    } label: {
                        Text(SafeEatL10n.text(L10nKey.Message.markAllRead))
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showDisclosureSheet) {
            if let category = disclosureCategory {
                DisclosureSheetWrapper(category: category)
            }
        }
        .task {
            guard let token = store.session?.accessToken else { return }
            await store.notificationStore.fetchMessages(accessToken: token, refresh: true)
        }
    }

    private func markAllRead() {
        guard let token = store.session?.accessToken else { return }
        Task {
            await store.notificationStore.markAllAsRead(accessToken: token)
        }
    }

    private func handleNavigateAction(_ params: [String: String]?) {
        guard let route = params?["route"] else { return }
        switch route {
        case "membership":
            store.selectedRootTab = .profile
        case "update":
            Task { await AppVersionStore.shared.checkVersion() }
        case "annual_report":
            break
        default:
            break
        }
    }
}

/// 协议弹窗包装
private struct DisclosureSheetWrapper: View {
    let category: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DisclosureWebView(category: category)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 协议内容展示
private struct DisclosureWebView: View {
    let category: String
    @State private var items: [DisclosureItem] = []
    @State private var isLoading = true

    private let api = SafeEatAPI()

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let first = items.first {
                ScrollView {
                    Text(htmlToPlainText(first.content))
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .padding(16)
                }
            } else {
                Text(SafeEatL10n.text(L10nKey.Message.emptyTitle))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
        .task {
            do {
                let result = try await api.fetchDisclosure(category: category, pageSize: 1)
                items = result.items
            } catch {
                #if DEBUG
                print("[DisclosureWebView] fetch failed: \(error)")
                #endif
            }
            isLoading = false
        }
    }

    private func htmlToPlainText(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else { return html }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        return html
    }
}

#Preview {
    NavigationStack {
        MessageCenterView()
            .environmentObject(AppStore())
    }
}
