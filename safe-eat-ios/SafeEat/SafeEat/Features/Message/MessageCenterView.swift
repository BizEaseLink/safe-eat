import SwiftUI

/// 消息中心页面
struct MessageCenterView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var scrollOffset: CGFloat = 0
    @State private var showDisclosureSheet = false
    @State private var disclosureCategory: String?
    @State private var selectedMessage: NotificationMessage?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                pageBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        SafeEatGlobalScrollOffsetReader(scrollOffset: $scrollOffset)

                        Color.clear.frame(height: proxy.safeAreaInsets.top + 74)

                        heroSection

                        // 全部已读 — 始终显示
                        markAllReadButton
                            .padding(.top, 16)

                        messageList
                            .padding(.top, 20)

                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }

                SafeEatTopBackChrome(
                    title: SafeEatL10n.text(L10nKey.Message.centerTitle),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top,
                    onBack: { dismiss() }
                )
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showDisclosureSheet) {
            if let category = disclosureCategory {
                DisclosureSheetWrapper(category: category)
            }
        }
        .sheet(item: $selectedMessage) { message in
            MessageDetailSheet(message: message)
        }
        .task {
            guard let token = store.session?.accessToken else { return }
            async let _: Void = store.notificationStore.fetchUnreadCount(accessToken: token)
            await store.notificationStore.fetchMessages(accessToken: token, refresh: true)
        }
    }

    // MARK: - 背景

    private var pageBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.12, green: 0.13, blue: 0.15), Color(red: 0.09, green: 0.10, blue: 0.12)]
                    : [Color(red: 0.99, green: 0.995, blue: 0.99), Color(red: 0.965, green: 0.978, blue: 0.968)],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.15 : 0.52), Color.clear],
                center: .topLeading, startRadius: 18, endRadius: 360
            )
            RadialGradient(
                colors: [Color(red: 0.98, green: 0.91, blue: 0.78).opacity(colorScheme == .dark ? 0.08 : 0.30), Color.clear],
                center: .topTrailing, startRadius: 12, endRadius: 280
            )
        }
    }

    // MARK: - 大标题

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(SafeEatL10n.text(L10nKey.Message.centerTitle))
                .font(SafeEatFont.custom(36, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.isZh ? "重要通知与更新尽在这里" : "Important notices and updates")
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    // MARK: - 全部已读/重置按钮（始终可点击）

    private var hasUnreadMessages: Bool {
        store.notificationStore.messages.contains { !$0.isRead }
    }

    private var markAllReadButton: some View {
        Button {
            if hasUnreadMessages {
                guard let token = store.session?.accessToken else { return }
                Task { await store.notificationStore.markAllAsRead(accessToken: token) }
            } else {
                store.notificationStore.resetAllRead()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: hasUnreadMessages ? "checkmark.circle" : "arrow.counterclockwise.circle")
                    .font(.system(size: 14, weight: .semibold))
                Text(hasUnreadMessages
                    ? SafeEatL10n.text(L10nKey.Message.markAllRead)
                    : (SafeEatL10n.isZh ? "重置未读" : "Reset unread"))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
            }
            .foregroundStyle(SafeEatTheme.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.18 : 0.72)
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 消息列表

    private var messageList: some View {
        Group {
            if store.notificationStore.messages.isEmpty && !store.notificationStore.isLoading {
                emptyView
            } else {
                messageCards
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "bell.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.4))
            Text(SafeEatL10n.text(L10nKey.Message.emptyTitle))
                .font(SafeEatFont.custom(18, relativeTo: .title3))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var messageCards: some View {
        LazyVStack(spacing: 12) {
            ForEach(store.notificationStore.messages) { message in
                MessageRowView(message: message) {
                    handleMessageTap(message)
                }
            }
            if store.notificationStore.hasMore {
                ProgressView().padding(.vertical, 20)
                    .task {
                        guard let token = store.session?.accessToken else { return }
                        await store.notificationStore.fetchMessages(accessToken: token, refresh: false)
                    }
            }
        }
    }

    // MARK: - 消息点击 — 根据动作类型分流

    private func handleMessageTap(_ message: NotificationMessage) {
        if !message.isRead, let token = store.session?.accessToken {
            Task { await store.notificationStore.markAsRead(accessToken: token, notificationId: message.id) }
        }

        let action = message.actionType ?? "none"
        #if DEBUG
        print("[MessageCenter] handleMessageTap: actionType=\(action), actionParams=\(String(describing: message.actionParams))")
        #endif

        switch action {
        case "navigate":
            if let route = message.actionParams?["route"] {
                handleNavigateAction(route: route, params: message.actionParams)
            }
        case "show_disclosure":
            let category = message.actionParams?["category"] ?? "privacy_policy"
            disclosureCategory = category
            showDisclosureSheet = true
        case "open_url":
            if let urlString = message.actionParams?["url"] {
                disclosureCategory = "external_url:\(urlString)"
                showDisclosureSheet = true
            }
        default:
            selectedMessage = message
        }
    }

    private func handleNavigateAction(route: String, params: [String: String]?) {
        // 先关闭消息中心，再切换 tab/导航
        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            switch route {
            case "membership":
                store.selectedRootTab = .profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    store.pushProfileRoute = .membership
                }
            case "update":
                store.selectedRootTab = .profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    store.pushProfileRoute = .updates
                }
            case "history":
                store.selectedRootTab = .history
            case "annual_report":
                store.selectedRootTab = .history
            case "feedback":
                store.selectedRootTab = .profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    store.pushProfileRoute = .feedback
                }
            case "helpCenter":
                store.selectedRootTab = .profile
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    store.pushProfileRoute = .helpCenter
                }
            default:
                break
            }
        }
    }
}

// MARK: - 纯文字消息详情弹框（通用弹出框）

private struct MessageDetailSheet: View {
    let message: NotificationMessage
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var displayTitle: String {
        SafeEatL10n.isZh ? (message.title ?? "") : (message.titleEn ?? message.title ?? "")
    }

    private var displayContent: String {
        SafeEatL10n.isZh ? (message.content ?? "") : (message.contentEn ?? message.content ?? "")
    }

    // 固定内容高度 200，内部滚动
    private let fixedContentHeight: CGFloat = 200

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: displayTitle,
            subtitle: nil,
            contentHeight: fixedContentHeight,
            dismissible: true,
            primaryButton: SheetButton(
                title: SafeEatL10n.isZh ? "已阅" : "Read",
                action: {
                    if !message.isRead, let token = store.session?.accessToken {
                        Task { await store.notificationStore.markAsRead(accessToken: token, notificationId: message.id) }
                    }
                    dismiss()
                }
            )
        ) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    if let createdAt = message.createdAt {
                        Text(createdAt.notificationTimeText)
                            .font(SafeEatFont.custom(12, relativeTo: .caption2))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .padding(.bottom, 10)
                    }

                    Text(displayContent)
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                }
            }
            .frame(height: fixedContentHeight)
        }
    }
}

// MARK: - 协议/外链弹窗（show_disclosure 和 open_url 共用）

private struct DisclosureSheetWrapper: View {
    let category: String
    @Environment(\.dismiss) private var dismiss

    // 判断是外链还是协议
    private var isExternalUrl: Bool {
        category.hasPrefix("external_url:")
    }

    private var urlString: String? {
        if isExternalUrl {
            return category.replacingOccurrences(of: "external_url:", with: "")
        }
        return nil
    }

    // 协议 category 对应的标题
    private var disclosureTitle: String {
        if isExternalUrl { return "" }
        switch category {
        case "privacy_policy": return SafeEatL10n.isZh ? "隐私政策" : "Privacy Policy"
        case "terms_of_service": return SafeEatL10n.isZh ? "服务条款" : "Terms of Service"
        case "disclaimer": return SafeEatL10n.isZh ? "免责声明" : "Disclaimer"
        default: return SafeEatL10n.isZh ? "协议详情" : "Details"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isExternalUrl, let urlStr = urlString, let url = URL(string: urlStr) {
                    // 外链：用 WebView
                    ExternalUrlView(url: url)
                } else {
                    // 协议：复用已有的 DisclosureDetailView
                    DisclosureDetailView(title: disclosureTitle, category: category)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// 外链 WebView
private struct ExternalUrlView: View {
    let url: URL
    @State private var isLoading = true

    var body: some View {
        ZStack {
            UrlWebView(url: url, isLoading: $isLoading)

            if isLoading {
                ProgressView()
                    .tint(SafeEatTheme.primary)
                    .padding(.top, 20)
            }
        }
    }
}

#if canImport(WebKit)
import WebKit

// 加载 URL 的 WebView
private struct UrlWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url == nil {
            webView.load(URLRequest(url: url))
        }
        context.coordinator.parent = self
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: UrlWebView?

        init(parent: UrlWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent?.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent?.isLoading = false
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
#endif

#Preview {
    NavigationStack {
        MessageCenterView()
            .environmentObject(AppStore())
    }
}
