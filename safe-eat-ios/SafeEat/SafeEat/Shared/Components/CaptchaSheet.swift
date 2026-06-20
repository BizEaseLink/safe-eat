import SwiftUI
import WebKit

/// 用 WKWebView 渲染 SVG data URI
struct SvgWebView: UIViewRepresentable {
    let svgBase64: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(
            """
            <html><body style="margin:0;display:flex;justify-content:center;align-items:center;background:transparent">
            <img src="\(svgBase64)" style="height:50px;width:auto;" />
            </body></html>
            """,
            baseURL: nil
        )
    }
}

/// 图形验证码弹窗：获取验证码图片，用户输入后确认
struct CaptchaSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let phone: String
    let scene: String?
    let templateCode: String?
    let onSuccess: (_ devCode: String?) -> Void

    @State private var captchaId: String?
    @State private var svgBase64: String?
    @State private var inputCode = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "安全验证",
            subtitle: "请输入图片中的字符",
            contentHeight: 160,
            primaryButton: SheetButton(
                title: "确认",
                isLoading: isSubmitting,
                isDisabled: inputCode.count < 2
            ) {
                submitCaptcha()
            },
            secondaryButton: SheetButton(title: "取消") {
                dismiss()
            }
        ) {
            captchaImageArea

            inputField

            if let errorMessage {
                Text(errorMessage)
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.danger)
            }
        }
        .task {
            await loadCaptcha()
        }
    }

    // MARK: - 验证码图片

    private var captchaImageArea: some View {
        VStack(spacing: 8) {
            Group {
                if let svgBase64 {
                    SvgWebView(svgBase64: svgBase64)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        .frame(height: 50)
                        .overlay { ProgressView() }
                }
            }
            .onTapGesture {
                Task { await loadCaptcha() }
            }

            Button(action: { Task { await loadCaptcha() } }) {
                Label("看不清？换一张", systemImage: "arrow.clockwise")
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.primary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 输入框

    private var inputField: some View {
        TextField("请输入验证码", text: $inputCode)
            .font(SafeEatFont.custom(16, relativeTo: .body))
            .textInputAutocapitalization(.never)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SafeEatTheme.line, lineWidth: 1)
            )
    }

    // MARK: - 方法

    private func loadCaptcha() async {
        errorMessage = nil
        do {
            let response = try await store.getCaptcha()
            captchaId = response.captchaId
            svgBase64 = response.svgBase64
            inputCode = ""
        } catch {
            errorMessage = "获取验证码失败，请重试"
        }
    }

    @MainActor
    private func submitCaptcha() {
        guard let captchaId else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                let response = try await store.sendSMS(
                    phone: phone,
                    captchaId: captchaId,
                    captchaCode: inputCode,
                    scene: scene,
                    templateCode: templateCode
                )
                SMSCountdownManager.shared.markSent()
                dismiss()
                onSuccess(response.devCode)
            } catch {
                errorMessage = error.localizedDescription
                await loadCaptcha()
                isSubmitting = false
            }
        }
    }
}
