import AuthenticationServices
import SwiftUI

private enum AuthScreen {
    case passwordLogin
    case codeLogin
    case register
    case bindPhone
}

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var screen: AuthScreen = .passwordLogin
    @State private var phone = ""
    @State private var code = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var devCodeHint: String?
    @State private var sendingSMS = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                authBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        Color.clear
                            .frame(height: SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)

                        backButton
                        heroBlock
                        contentCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 36)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: store.requiresPhoneBinding) { _ in
            syncScreenWithSession()
        }
        .onChange(of: store.session?.accessToken) { _ in
            syncScreenWithSession()
        }
    }

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

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(SafeEatTheme.primary.opacity(0.22))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(SafeEatTheme.primary)
                            .frame(width: 8, height: 8)
                    )

                Text(SafeEatL10n.text(L10nKey.Auth.onboardingEyebrow))
                    .font(SafeEatFont.custom(15, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primaryDeep)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.78))
            )
            .overlay(
                Capsule()
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(heroTitle)
                    .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(heroSubtitle)
                    .font(SafeEatFont.custom(15, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            switch screen {
            case .passwordLogin:
                passwordLoginContent
            case .codeLogin:
                codeLoginContent
            case .register:
                registerContent
            case .bindPhone:
                bindPhoneContent
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.10), radius: 22, y: 16)
    }

    private var passwordLoginContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.passwordLabel), text: $password)

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionLogin), isLoading: store.isLoading) {
                Task {
                    await store.loginWithPassword(phone: phone, password: password)
                }
            }
            .disabled(phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11 || password.count < 6 || store.isLoading)

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToCode)) {
                    screen = .codeLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToRegister)) {
                    screen = .register
                }
            }

            appleCircleButton
        }
    }

    private var codeLoginContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            codeField
            smsHintView

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionCodeLogin), isLoading: store.isLoading) {
                Task {
                    await store.login(phone: phone, code: code)
                }
            }
            .disabled(phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11 || code.count < 4 || store.isLoading)

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToPassword)) {
                    screen = .passwordLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToRegister)) {
                    screen = .register
                }
            }

            appleCircleButton
        }
    }

    private var registerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.phoneLabel), text: $phone, keyboardType: .numberPad)
            codeField
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.passwordLabel), text: $password)
            authSecureField(title: SafeEatL10n.text(L10nKey.Auth.confirmPasswordLabel), text: $confirmPassword)
            smsHintView

            authPrimaryButton(title: SafeEatL10n.text(L10nKey.Auth.actionRegister), isLoading: store.isLoading) {
                Task {
                    await register()
                }
            }
            .disabled(!canSubmitRegistration || store.isLoading)

            HStack {
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToPassword)) {
                    screen = .passwordLogin
                }
                Spacer()
                miniLink(title: SafeEatL10n.text(L10nKey.Auth.switchToCode)) {
                    screen = .codeLogin
                }
            }

            appleCircleButton
        }
    }

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
                screen = .passwordLogin
            }
        }
    }

    private var codeField: some View {
        HStack(spacing: 12) {
            authField(title: SafeEatL10n.text(L10nKey.Auth.codeLabel), text: $code, keyboardType: .numberPad)

            Button {
                Task {
                    await requestSMS()
                }
            } label: {
                Text(sendingSMS ? SafeEatL10n.text(L10nKey.Common.sending) : SafeEatL10n.text(L10nKey.Common.sendCode))
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
            .disabled(sendingSMS || phone.trimmingCharacters(in: .whitespacesAndNewlines).count != 11)
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

    private var heroTitle: String {
        switch screen {
        case .passwordLogin:
            return SafeEatL10n.text(L10nKey.Auth.passwordTitle)
        case .codeLogin:
            return SafeEatL10n.text(L10nKey.Auth.codeTitle)
        case .register:
            return SafeEatL10n.text(L10nKey.Auth.registerTitle)
        case .bindPhone:
            return SafeEatL10n.text(L10nKey.Auth.bindTitle)
        }
    }

    private var heroSubtitle: String {
        switch screen {
        case .passwordLogin:
            return SafeEatL10n.text(L10nKey.Auth.passwordSubtitle)
        case .codeLogin:
            return SafeEatL10n.text(L10nKey.Auth.codeSubtitle)
        case .register:
            return SafeEatL10n.text(L10nKey.Auth.registerSubtitle)
        case .bindPhone:
            return SafeEatL10n.text(L10nKey.Auth.bindSubtitle)
        }
    }

    private var canSubmitRegistration: Bool {
        phone.trimmingCharacters(in: .whitespacesAndNewlines).count == 11
            && code.count >= 4
            && password.count >= 6
            && confirmPassword.count >= 6
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

    private var appleCircleButton: some View {
        VStack(spacing: 8) {
            ZStack {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName]
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(width: 56, height: 56)
                .clipShape(Circle())

                Circle()
                    .fill(Color.black)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .allowsHitTesting(false)

                Image(systemName: "apple.logo")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .allowsHitTesting(false)
            }

            Text(SafeEatL10n.text(L10nKey.Auth.appleAction))
                .font(SafeEatFont.custom(12, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func requestSMS() async {
        sendingSMS = true
        defer { sendingSMS = false }

        do {
            let response = try await store.sendSMS(phone: phone)
            devCodeHint = response.devCode
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func register() async {
        guard password == confirmPassword else {
            store.errorMessage = SafeEatL10n.text(L10nKey.Auth.passwordMismatch)
            return
        }

        await store.registerWithPassword(phone: phone, code: code, password: password)
    }

    private func handleBack() {
        switch screen {
        case .codeLogin, .register:
            resetFields()
            screen = .passwordLogin
        case .bindPhone:
            store.logout()
            resetFields()
            screen = .passwordLogin
        case .passwordLogin:
            store.resetOnboarding()
        }
    }

    private func syncScreenWithSession() {
        if store.requiresPhoneBinding {
            screen = .bindPhone
        } else if store.session == nil, screen == .bindPhone {
            screen = .passwordLogin
        }
    }

    private func resetFields() {
        phone = ""
        code = ""
        password = ""
        confirmPassword = ""
        devCodeHint = nil
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case let .success(authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            let formatter = PersonNameComponentsFormatter()
            let displayName = credential.fullName.flatMap { formatter.string(from: $0) }
                .flatMap { value -> String? in
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
                ?? SafeEatL10n.text(L10nKey.Auth.appleNameFallback)

            Task {
                await store.loginWithApple(appleSub: credential.user, displayName: displayName)
            }
        case let .failure(error):
            store.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStore())
        .environmentObject(AppSettingsStore.shared)
}
