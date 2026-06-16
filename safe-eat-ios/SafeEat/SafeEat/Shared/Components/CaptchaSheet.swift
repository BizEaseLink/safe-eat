import SwiftUI

/// 图形验证码弹窗：获取验证码图片，用户输入后确认
struct CaptchaSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let phone: String
    let onSuccess: () -> Void

    @State private var captchaId: String?
    @State private var captchaImageURL: URL?
    @State private var svgBase64: String?
    @State private var inputCode = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("安全验证")
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text("请输入图片中的字符")
                .font(SafeEatFont.custom(14, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

            // 验证码图片
            Group {
                if let svgBase64, let url = URL(string: svgBase64) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        default:
                            ProgressView()
                        }
                    }
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.gray.opacity(0.1))
                    )
                } else {
                    ProgressView()
                        .frame(height: 50)
                }
            }
            .onTapGesture {
                Task { await loadCaptcha() }
            }

            // 刷新按钮
            Button(action: { Task { await loadCaptcha() } }) {
                Label("看不清？换一张", systemImage: "arrow.clockwise")
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.primary)
            }
            .buttonStyle(.plain)

            // 输入框
            TextField("请输入验证码", text: $inputCode)
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.gray.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(SafeEatTheme.line, lineWidth: 1)
                )

            // 错误提示
            if let errorMessage {
                Text(errorMessage)
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.danger)
            }

            // 按钮
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)

                Button(action: submitCaptcha) {
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("确认")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(inputCode.count < 2 || isSubmitting)
                .opacity(inputCode.count >= 2 ? 1.0 : 0.5)
            }
        }
        .padding(24)
        .task {
            await loadCaptcha()
        }
    }

    private func loadCaptcha() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await store.getCaptcha()
            captchaId = response.captchaId
            svgBase64 = response.svgBase64
            inputCode = ""
        } catch {
            errorMessage = "获取验证码失败，请重试"
        }
        isLoading = false
    }

    private func submitCaptcha() {
        guard let captchaId else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                _ = try await store.sendSMS(
                    phone: phone,
                    captchaId: captchaId,
                    captchaCode: inputCode
                )
                SMSCountdownManager.shared.markSent()
                dismiss()
                onSuccess()
            } catch {
                // 验证码错误，刷新图片让用户重试
                errorMessage = error.localizedDescription
                await loadCaptcha()
            }
            isSubmitting = false
        }
    }
}
