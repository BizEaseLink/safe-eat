import SwiftUI
import WebKit

struct DisclosureDetailView: View {
    let title: String
    let category: String

    @EnvironmentObject private var store: AppStore
    @State private var htmlContent: String?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            // 文档内容固定白底黑字,无论深浅色模式都强制白底,避免深色模式下黑底看不清
            Color.white.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let err = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundStyle(SafeEatTheme.warning)
                    Text(err)
                        .font(SafeEatFont.textStyle(.body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button {
                        errorMessage = nil
                        isLoading = true
                        Task { await loadDisclosure() }
                    } label: {
                        Text(SafeEatL10n.text(L10nKey.Common.retry))
                            .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                }
                .padding(20)
            } else if let html = htmlContent {
                // 完整 HTML 文档直接用 WebView 渲染，不再额外包装
                FullHTMLWebView(html: html)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Text(SafeEatL10n.text(L10nKey.Errors.invalidResponse))
                        .font(SafeEatFont.textStyle(.body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .padding(20)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDisclosure() }
    }

    private func loadDisclosure() async {
        do {
            let result = try await store.api.fetchDisclosure(category: category)
            // 每个 category 只有一条记录，取第一条的 content
            if let first = result.items.first {
                htmlContent = first.content
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// 渲染完整 HTML 文档（已含 <html><head><style>），不做二次包装
struct FullHTMLWebView: UIViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
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
