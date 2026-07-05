import AuthenticationServices
import SwiftUI

// MARK: - 登录页路由

enum LoginRoute: Hashable {
    case codeLogin
    case passwordLogin
    case register
    case bindPhone
    case forgotPassword
    case accountRecovery
    case setPassword
}

// MARK: - 登录页主视图

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var devCodeHint: String?
    @State private var showNewUserAlert = false
    @State private var showPasswordLoginError = false
    @State private var loginRoute: LoginRoute? = nil
    @State private var agreedToTerms = false
    @State private var showCaptchaSheet = false
    @State private var nextSmsNeedsCaptcha = false
    @State private var showAccountDeletingAlert = false
    @State private var showAccountLockedAlert = false
    @State private var showContactSupport = false
    @State private var showTermsNotAgreed = false

    var body: some View {
        NavigationStack {
            codeLoginPage
                .navigationDestination(item: $loginRoute) { route in
                    switch route {
                    case .codeLogin:
                        codeLoginPage
                    case .passwordLogin:
                        passwordLoginPage
                    case .register:
                        registerPage
                    case .bindPhone:
                        bindPhonePage
                    case .forgotPassword:
                        ResetPasswordView(phoneMode: .input)
                    case .accountRecovery:
                        AccountRecoveryView(phone: phone)
                    case .setPassword:
                        setPasswordPage
                    }
                }
        }
        .onChange(of: store.requiresPhoneBinding) { _ in
            syncRouteWithSession()
        }
        .onChange(of: store.session?.accessToken) { _ in
            syncRouteWithSession()
        }
        .onChange(of: store.isNewUser) { newValue in
            if newValue {
                showNewUserAlert = true
            }
        }
        .onChange(of: store.requiresRegistration) { newValue in
            if newValue && loginRoute != .setPassword {
                loginRoute = .setPassword
            }
        }
        .onChange(of: store.requiresPasswordSetup) { newValue in
            if newValue && loginRoute != .setPassword {
                loginRoute = .setPassword
            }
        }
        .sheet(isPresented: $showNewUserAlert) {
            NewUserWelcomeSheet(
                onDismiss: {
                    showNewUserAlert = false
                    store.isNewUser = false
                }
            )
        }
        .sheet(isPresented: $showCaptchaSheet) {
            CaptchaSheet(phone: phone, scene: loginRoute == .register ? "register" : "login", templateCode: "100001") { devCode in
                // 验证码发送成功，非生产环境显示 devCode 提示
                if let devCode, !devCode.isEmpty {
                    devCodeHint = devCode
                }
                // 弹过验证码后，后续请求都走 CaptchaSheet
                nextSmsNeedsCaptcha = true
            }
        }
        .sheet(isPresented: $showContactSupport) {
            ContactSupportSheet()
        }
        .alert(SafeEatL10n.text(L10nKey.Auth.accountDeletingTitle), isPresented: $showAccountDeletingAlert) {
            Button(SafeEatL10n.text(L10nKey.Auth.accountDeletingRecover)) {
                loginRoute = .accountRecovery
            }
            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
        } message: {
            Text(SafeEatL10n.text(L10nKey.Auth.accountDeletingMessage))
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: $showTermsNotAgreed) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) {}
        } message: {
            Text(SafeEatL10n.text(L10nKey.Auth.termsNotAgreed))
        }
        .alert(SafeEatL10n.text(L10nKey.Auth.accountLockedTitle), isPresented: $showAccountLockedAlert) {
            Button(SafeEatL10n.text(L10nKey.Auth.loginWithSms)) {
                loginRoute = .codeLogin
            }
            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
        } message: {
            Text(SafeEatL10n.text(L10nKey.Auth.accountLockedMessage))
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: showError) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var showError: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }

    // MARK: - 验证码登录页（默认页）

    private var codeLoginPage: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.codeTitle))
                        codeLoginContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 密码登录页

    private var passwordLoginPage: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.passwordTitle))
                        passwordLoginContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 注册页

    private var registerPage: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.registerTitle))
                        registerContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 绑定手机页

    private var bindPhonePage: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.bindTitle))
                        bindPhoneContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 设置密码页（验证码登录后强制设置）

    private var setPasswordPage: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        heroBlock(title: SafeEatL10n.text(L10nKey.Auth.setPasswordTitle))
                        setPasswordContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { hideKeyboard() }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - 共享组件

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

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

            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.56))
                .frame(width: 176, height: 118)
                .rotationEffect(.degrees(12))
                .offset(x: 128, y: -116)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color(red: 0.86, green: 0.93, blue: 0.88).opacity(colorScheme == .dark ? 0.08 : 0.66))
                .frame(width: 154, height: 104)
                .rotationEffect(.degrees(-9))
                .offset(x: -128, y: -38)

            Circle()
                .fill(SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.08 : 0.35))
                .frame(width: 280, height: 280)
                .offset(x: 118, y: 320)
        }
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button {
            handleBack()
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

    // MARK: - 验证码登录内容

    private var codeLoginContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            codeField
            smsHintView

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionCodeLogin), isLoading: store.isLoading) {
                Task {
                    await performSmsLogin()
                }
            }
            .disabled(phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11 || code.count < 4 || store.isLoading)

            // 底部辅助入口：忘记密码 | 联系客服
            HStack {
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.forgotPassword)) {
                    loginRoute = .forgotPassword
                }
                Text("|")
                    .font(SafeEatFont.custom(14, relativeTo: .footnote))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.contactSupport)) {
                    showContactSupport = true
                }
                Spacer()
            }

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToPassword)) {
                    loginRoute = .passwordLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToRegister)) {
                    loginRoute = .register
                }
            }
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    // MARK: - 密码登录内容

    private var passwordLoginContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.passwordLabel), text: $password)

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionLogin), isLoading: store.isLoading) {
                Task {
                    await performPasswordLogin()
                }
            }
            .disabled(phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11 || password.count < 6 || store.isLoading)
            .alert(SafeEatL10n.text(L10nKey.Auth.passwordLoginErrorTitle), isPresented: $showPasswordLoginError) {
                Button(SafeEatL10n.text(L10nKey.Auth.switchToRegister)) {
                    loginRoute = .register
                }
                Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
            } message: {
                Text(SafeEatL10n.text(L10nKey.Auth.passwordLoginErrorMessage))
            }

            // 底部辅助入口：忘记密码 | 联系客服
            HStack {
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.forgotPassword)) {
                    loginRoute = .forgotPassword
                }
                Text("|")
                    .font(SafeEatFont.custom(14, relativeTo: .footnote))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.contactSupport)) {
                    showContactSupport = true
                }
                Spacer()
            }

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToCode)) {
                    loginRoute = .codeLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToRegister)) {
                    loginRoute = .register
                }
            }
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    // MARK: - 注册内容

    private var registerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            codeField
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.passwordLabel), text: $password)
            passwordRequirementHints(password)
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.confirmPasswordLabel), text: $confirmPassword)
            if !confirmPassword.isEmpty && password != confirmPassword {
                Text(SafeEatL10n.text(L10nKey.Auth.passwordMismatch))
                    .font(SafeEatFont.textStyle(.footnote))
                    .foregroundStyle(SafeEatTheme.danger)
            }
            smsHintView

            termsAgreementRow

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionRegister), isLoading: store.isLoading) {
                Task {
                    await register()
                }
            }
            .disabled(!canSubmitRegistration || !agreedToTerms || store.isLoading)

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToPassword)) {
                    loginRoute = .passwordLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToCode)) {
                    loginRoute = .codeLogin
                }
            }
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    // MARK: - 绑定手机内容

    private var bindPhoneContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            codeField
            smsHintView

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionBind), isLoading: store.isLoading) {
                Task {
                    await store.bindApplePhone(phone: phone, code: code)
                }
            }
            .disabled(phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11 || code.count < 4 || store.isLoading)

            miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchBackWelcome)) {
                store.logout()
                resetFields()
                loginRoute = nil
            }
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    // MARK: - 设置密码内容

    /// 是否为新用户注册场景（无 token，需要验证码）
    private var isRegistrationFlow: Bool {
        store.requiresRegistration
    }

    private var setPasswordContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isRegistrationFlow {
                Text(SafeEatL10n.text(L10nKey.Auth.setPasswordSubtitle))
                    .font(SafeEatFont.custom(15, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
                    .disabled(true)
                codeField
                smsHintView
            }

            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.passwordLabel), text: $password)
            passwordRequirementHints(password)
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.confirmPasswordLabel), text: $confirmPassword)
            if !confirmPassword.isEmpty && password != confirmPassword {
                Text(SafeEatL10n.text(L10nKey.Auth.passwordMismatch))
                    .font(SafeEatFont.textStyle(.footnote))
                    .foregroundStyle(SafeEatTheme.danger)
            }

            // 注册需要同意协议
            if isRegistrationFlow {
                termsAgreementRow
            }

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.setPasswordTitle), isLoading: store.isLoading) {
                if isRegistrationFlow && !agreedToTerms {
                    showTermsNotAgreed = true
                    return
                }
                Task {
                    await setPassword()
                }
            }
            .disabled(!canSubmitSetPassword || store.isLoading)
        }
        .padding(24)
        .background(cardBackground)
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    // MARK: - 共享子组件

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

    private var codeField: some View {
        HStack(spacing: 12) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.codeLabel), text: $code, keyboardType: .numberPad)

            Button {
                Task {
                    await requestSMS()
                }
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
            .disabled(smsCountdownManager.isSending || smsCountdownManager.countdown > 0 || phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11)
        }
    }

    @ViewBuilder
    private var smsHintView: some View {
        if let devCodeHint, !devCodeHint.isEmpty {
            Text(SafeEatL10n.format(L10nKey.Auth.smsHintFormat, devCodeHint))
                .font(SafeEatFont.textStyle(.footnote))
                .foregroundStyle(Color(red: 0.82, green: 0.47, blue: 0.18))
        }
    }

    @ViewBuilder
    private func passwordRequirementHints(_ password: String) -> some View {
        if !password.isEmpty {
            let result = PasswordValidator.validate(password)
            VStack(alignment: .leading, spacing: 4) {
                requirementRow(text: SafeEatL10n.text(L10nKey.Auth.passwordRequirementLength), passed: result.isLengthValid)
                requirementRow(text: SafeEatL10n.text(L10nKey.Auth.passwordRequirementUppercase), passed: result.hasUppercase)
                requirementRow(text: SafeEatL10n.text(L10nKey.Auth.passwordRequirementLowercase), passed: result.hasLowercase)
                requirementRow(text: SafeEatL10n.text(L10nKey.Auth.passwordRequirementDigit), passed: result.hasDigit)
                requirementRow(text: SafeEatL10n.text(L10nKey.Auth.passwordRequirementSpecial), passed: result.hasSpecialChar)
            }
        }
    }

    private func requirementRow(text: String, passed: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundStyle(passed ? SafeEatTheme.success : SafeEatTheme.textSecondary)
            Text(text)
                .font(SafeEatFont.textStyle(.caption2))
                .foregroundStyle(passed ? SafeEatTheme.success : SafeEatTheme.textSecondary)
        }
    }

    // 注册页协议勾选
    @State private var showDisclosureCategory: DisclosureLink?

    private var termsAgreementRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                agreedToTerms.toggle()
            } label: {
                Image(systemName: agreedToTerms ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(agreedToTerms ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
            }
            .buttonStyle(.plain)

            termsFlowText
                .font(SafeEatFont.custom(13, relativeTo: .caption))
                .fixedSize(horizontal: false, vertical: true)
        }
        .sheet(item: $showDisclosureCategory) { link in
            NavigationStack {
                DisclosureDetailView(title: link.title, category: link.category)
            }
        }
    }

    private func linkText(_ display: String, url: String) -> AttributedString {
        var attr = AttributedString(display)
        attr.foregroundColor = SafeEatTheme.primary
        attr.underlineStyle = .single
        attr.link = URL(string: url)
        return attr
    }

    private var termsFlowText: some View {
        let ua = SafeEatL10n.text(L10nKey.Auth.termsUserAgreement)
        let pp = SafeEatL10n.text(L10nKey.Auth.termsPrivacyPolicy)

        return (
            Text(SafeEatL10n.text(L10nKey.Auth.termsPrefix))
                .foregroundStyle(SafeEatTheme.textSecondary)
            + Text(linkText(ua, url: "safeeat://user_agreement"))
            + Text(SafeEatL10n.text(L10nKey.Auth.termsAnd))
                .foregroundStyle(SafeEatTheme.textSecondary)
            + Text(linkText(pp, url: "safeeat://privacy_policy"))
        )
        .environment(\.openURL, OpenURLAction { url in
            guard let host = url.host() else { return .discarded }
            let title = host == "user_agreement" ? ua : pp
            showDisclosureCategory = DisclosureLink(category: host, title: title)
            return .handled
        })
    }

    private var canSubmitRegistration: Bool {
        let passwordResult = PasswordValidator.validate(password)
        return phone.trimmingCharacters(in: .whitespacesAndNewlines).count == 11
            && code.count >= 4
            && passwordResult.isValid
            && !confirmPassword.isEmpty
            && password == confirmPassword
    }

    private var canSubmitSetPassword: Bool {
        let passwordResult = PasswordValidator.validate(password)
        let passwordValid = passwordResult.isValid
            && !confirmPassword.isEmpty
            && password == confirmPassword

        if isRegistrationFlow {
            // 新用户注册：需要手机号 + 验证码 + 密码
            return phone.trimmingCharacters(in: .whitespacesAndNewlines).count == 11
                && code.count >= 4
                && passwordValid
        } else {
            // 老用户设密码：只需要密码
            return passwordValid
        }
    }

    private func authField(title: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
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

    private func authSecureField(title: String, text: Binding<String>) -> some View {
        SecureField(title, text: text)
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

    private func miniLink(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                .foregroundStyle(SafeEatTheme.primaryDeep)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 倒计时管理器

    @ObservedObject private var smsCountdownManager = SMSCountdownManager.shared

    // MARK: - 操作方法

    /// 统一登录入口：检测 ACCOUNT_DELETING 错误码
    private func performSmsLogin() async {
        await store.login(phone: phone, code: code)
        if store.accountDeletingDetected {
            showAccountDeletingAlert = true
            store.accountDeletingDetected = false
        }
    }

    /// 统一密码登录入口：检测 ACCOUNT_DELETING / ACCOUNT_LOCKED 错误码
    private func performPasswordLogin() async {
        await store.loginWithPassword(phone: phone, password: password)
        if store.accountDeletingDetected {
            showAccountDeletingAlert = true
            store.accountDeletingDetected = false
            return
        }
        if store.accountLockedDetected {
            showAccountLockedAlert = true
            store.accountLockedDetected = false
            return
        }
        if store.isNewUser == false && store.session == nil && !store.isLoading {
            showPasswordLoginError = true
        }
    }

    private func requestSMS() async {
        // 根据当前页面决定场景：注册页用 register，其他用 login
        let scene: String = loginRoute == .register ? "register" : "login"
        let templateCode: String = loginRoute == .register ? "100001" : "100001"

        // 已知需要验证码，直接弹 CaptchaSheet
        if nextSmsNeedsCaptcha {
            showCaptchaSheet = true
            return
        }
        // 先直接发短信（不带 captcha），每天前5次免验证码
        do {
            let response = try await store.sendSMS(phone: phone, scene: scene, templateCode: templateCode)
            SMSCountdownManager.shared.markSent()
            if let devCode = response.devCode, !devCode.isEmpty {
                devCodeHint = devCode
            }
            // 后端提示下次需要验证码
            if response.needCaptcha == true {
                nextSmsNeedsCaptcha = true
            }
        } catch let error as APIError {
            if error.localizedDescription.contains("图形验证码") {
                nextSmsNeedsCaptcha = true
                showCaptchaSheet = true
            } else {
                store.errorMessage = error.localizedDescription
            }
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func register() async {
        let result = PasswordValidator.validate(password)
        guard result.isValid else {
            store.errorMessage = "密码必须包含大写字母、小写字母、数字和特殊字符"
            return
        }
        guard password == confirmPassword else {
            store.errorMessage = SafeEatL10n.text(L10nKey.Auth.passwordMismatch)
            return
        }

        await store.registerWithPassword(phone: phone, code: code, password: password)
    }

    private func setPassword() async {
        let result = PasswordValidator.validate(password)
        guard result.isValid else {
            store.errorMessage = "密码必须包含大写字母、小写字母、数字和特殊字符"
            return
        }
        guard password == confirmPassword else {
            store.errorMessage = SafeEatL10n.text(L10nKey.Auth.passwordMismatch)
            return
        }

        if isRegistrationFlow {
            // 新用户注册：验证码 + 密码（底层调用 setPassword API）
            await store.registerWithPassword(phone: phone, code: code, password: password)
            if store.session != nil {
                store.requiresRegistration = false
                await store.completePasswordSetup()
            }
        } else {
            // 老用户设密码：只需密码（用 token 验证身份）
            await store.setPasswordAfterLogin(password: password)
            if store.session != nil {
                await store.completePasswordSetup()
            }
        }
    }

    private func handleBack() {
        if loginRoute == nil {
            store.resetOnboarding()
        } else if loginRoute == .setPassword && isRegistrationFlow {
            // 新用户注册流程不允许返回（必须设置密码完成注册）
            return
        } else {
            loginRoute = nil
        }
    }

    private func syncRouteWithSession() {
        if store.requiresPhoneBinding {
            loginRoute = .bindPhone
        } else if store.session == nil, loginRoute == .bindPhone {
            loginRoute = nil
        }
    }

    private func resetFields() {
        phone = ""
        code = ""
        password = ""
        confirmPassword = ""
        devCodeHint = nil
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStore())
        .environmentObject(AppSettingsStore.shared)
}
