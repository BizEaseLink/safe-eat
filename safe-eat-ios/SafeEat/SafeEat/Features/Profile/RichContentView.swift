import SwiftUI
import WebKit

/// 直接渲染 HTML，WKWebView 自带滚动，不做高度计算
struct RichContentView: UIViewRepresentable {
    let html: String
    var contentPadding: CGFloat = 20

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let styled = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            :root { color-scheme: light dark; }
            body {
                font-family: -apple-system, sans-serif;
                font-size: 15px;
                line-height: 1.6;
                margin: 0; padding: \(contentPadding)px;
                color: #333;
                box-sizing: border-box;
                overflow-wrap: anywhere;
                -webkit-text-size-adjust: 100%;
            }
            * { box-sizing: border-box; }
            @media (prefers-color-scheme: dark) { body { color: #e0e0e0; } }
            img { max-width: 100%; height: auto; border-radius: 8px; margin: 8px 0; }
            h1,h2,h3,h4,h5,h6 { margin-top: 16px; margin-bottom: 8px; }
            p { margin: 8px 0; }
            table { width: 100%; border-collapse: collapse; display: block; overflow-x: auto; }
            ul,ol { padding-left: 20px; }
            a { color: #2E7D32; }
            hr { border: none; border-top: 1px solid #e0e0e0; margin: 24px 0; }
            @media (prefers-color-scheme: dark) { hr { border-top-color: #444; } }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
        webView.loadHTMLString(styled, baseURL: nil)
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
