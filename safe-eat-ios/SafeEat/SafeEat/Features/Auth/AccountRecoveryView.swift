import SwiftUI

/// 注销恢复视图：通过手机号+验证码恢复已注销的账号
struct AccountRecoveryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    /// 从登录页带入的手机号
    let phone: String

    @State private var inputPhone: String
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showCaptchaSheet = false
    @State private var nextSmsNeedsCaptcha = false
    @State private var devCodeHint: String?
    @State private var showSuccess = false

    @ObservedObject private var smsCountdownManager = SMSCountdownManager.shared

    private var canSubmit: Bool {
        inputPhone.trimmingCharacters(in: .whitespacesAndNewlines).count == 11
            && code.count >= 4
            && !isLoading
    }

    init(phone: String = "") {
        self.phone = phone
        _inputPhone = State(initialValue: phone)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.accountRecoveryTitle))
                        recoveryContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showCaptchaSheet) {
            CaptchaSheet(phone: inputPhone, scene: "cancel-deletion", templateCode: "100001") { devCode in
                if let devCode, !devCode.isEmpty {
                    devCodeHint = devCode
                }
                nextSmsNeedsCaptcha = true
            }
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: showErrorMessage) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(SafeEatL10n.text(L10nKey.Auth.accountRecoverySuccess), isPresented: $showSuccess) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) {
                // 恢复成功后，如果需要设置密码则跳转设置密码页，否则直接进首页
                // AppStore.finishLogin 已处理 requiresPasswordSetup
            }
        }
    }

    private var showErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Components

    private var authBackground: some View {
        ZStack {
            SafeEatMainGradientBackground()

            Circle()
                .fill(Color(red: 0.89, green: 0.95, blue: 0.90).opacity(colorScheme == .dark ? 0.10 : 0.82))
                .frame(width: 260, height: 260)
                .blur(radius: 4)
                .offset(x: -120, y: -260)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color(red: 0.96, green: 0.90, blue: 0.80).opacity(colorScheme == .dark ? 0.10 : 0.62))
                .frame(width: 220, height: 140)
                .rotationEffect(.degrees(-14))
                .offset(x: 132, y: -280)

            Circle()
                .fill(SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.08 : 0.35))
                .frame(width: 280, height: 280)
                .offset(x: 118, y: 320)
        }
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button {
            // 返回登录页
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.dismiss(animated: true)
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(width: 46, height: 46)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.76))
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func heroBlock(title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AppLogoView(size: 44, animate: false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(SafeEatL10n.text(L10nKey.Brand.appName))
                        .font(SafeEatFont.custom(22, relativeTo: .title2, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Text(SafeEatL10n.text(L10nKey.Brand.slogan))
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(SafeEatTheme.primaryDeep)
                }
            }

            Text(title)
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
        }
    }

    private var recoveryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SafeEatL10n.text(L10nKey.Auth.accountRecoverySubtitle))
                .font(SafeEatFont.custom(15, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)

            recoveryField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $inputPhone, keyboardType: .numberPad)

            // 验证码行
            HStack(spacing: 12) {
                recoveryField(title: SafeEatL10n.text(L10nKey.Auth.codeLabel), text: $code, keyboardType: .numberPad)

                Button {
                    Task { await requestSMS() }
                } label: {
                    Text(smsCountdownManager.countdown > 0 ? "\(smsCountdownManager.countdown)s" : (smsCountdownManager.isSending ? SafeEatL10n.text(L10nKey.Common.sending) : SafeEatL10n.text(L10nKey.Common.sendCode)))
                        .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 56)
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
                .disabled(smsCountdownManager.isSending || smsCountdownManager.countdown > 0 || inputPhone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11)
            }

            if let devCodeHint, !devCodeHint.isEmpty {
                Text(SafeEatL10n.format(L10nKey.Auth.smsHintFormat, devCodeHint))
                    .font(SafeEatFont.textStyle(.footnote))
                    .foregroundStyle(Color(red: 0.82, green: 0.47, blue: 0.18))
            }

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.accountRecoveryAction), isLoading: isLoading) {
                Task { await recoverAccount() }
            }
            .disabled(!canSubmit)
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    private func recoveryField(title: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        TextField(title, text: text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .font(SafeEatFont.custom(16, relativeTo: .body))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
            )
    }

    private func authPrimaryButton(title: String, isLoading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(title)
                        .frame(maxWidth: .infinity)
                }
            }
            .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
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
    }

    private var cardBackground: some View {
        Group {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.64))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Actions

    private func requestSMS() async {
        guard inputPhone.trimmingCharacters(in: .whitespacesAndNewlines).count == 11 else { return }

        if nextSmsNeedsCaptcha {
            showCaptchaSheet = true
            return
        }

        do {
            let response = try await store.sendSMS(phone: inputPhone, scene: "cancel-deletion", templateCode: "100001")
            SMSCountdownManager.shared.markSent()
            if let devCode = response.devCode, !devCode.isEmpty {
                devCodeHint = devCode
            }
            if response.needCaptcha == true {
                nextSmsNeedsCaptcha = true
            }
        } catch let error as APIError {
            if error.localizedDescription.contains("图形验证码") {
                nextSmsNeedsCaptcha = true
                showCaptchaSheet = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recoverAccount() async {
        isLoading = true
        defer { isLoading = false }

        await store.cancelDeletionPublic(phone: inputPhone, code: code)

        if store.accountDeletingDetected {
            errorMessage = SafeEatL10n.text(L10nKey.Auth.accountDeletingMessage)
            store.accountDeletingDetected = false
        } else if store.session != nil {
            showSuccess = true
        } else if store.errorMessage != nil {
            errorMessage = store.errorMessage
        }
    }
}

#Preview {
    NavigationStack {
        AccountRecoveryView(phone: "13800138000")
            .environmentObject(AppStore())
    }
}
