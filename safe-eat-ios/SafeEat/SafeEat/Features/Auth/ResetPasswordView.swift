import SwiftUI

enum ResetPasswordPhoneMode {
    case input
    case fixed
}

struct ResetPasswordView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let phoneMode: ResetPasswordPhoneMode

    @State private var phone = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showCaptchaSheet = false
    @State private var nextSmsNeedsCaptcha = false
    @State private var devCodeHint: String?

    @ObservedObject private var smsCountdownManager = SMSCountdownManager.shared

    private var currentPhone: String {
        store.profile?.phone ?? ""
    }

    private var maskedPhone: String {
        let p = currentPhone
        guard p.count == 11 else { return p }
        let start = p.index(p.startIndex, offsetBy: 3)
        let end = p.index(p.startIndex, offsetBy: 7)
        return String(p[..<start]) + "****" + String(p[end...])
    }

    private var displayPhone: String {
        phoneMode == .fixed ? currentPhone : phone
    }

    private var successMessage: String {
        phoneMode == .input ? "密码已重置，请重新登录" : SafeEatL10n.text(L10nKey.Auth.resetPasswordSuccess)
    }

    private var canSubmit: Bool {
        let phoneValid = phoneMode == .fixed ? currentPhone.count == 11 : phone.count == 11
        let passwordResult = PasswordValidator.validate(newPassword)
        return phoneValid && code.count >= 4 && passwordResult.isValid && !confirmPassword.isEmpty && newPassword == confirmPassword && !isLoading
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Auth.resetPasswordTitle),
            subtitle: SafeEatL10n.text(L10nKey.Auth.resetPasswordSubtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    if phoneMode == .fixed {
                        ProfileDisabledField(text: maskedPhone, colorScheme: colorScheme)
                    } else {
                        ProfileTextField(
                            title: SafeEatL10n.text(L10nKey.Auth.phoneLabel),
                            text: $phone,
                            keyboardType: .numberPad
                        )
                    }

                    ProfileCodeRow(
                        code: $code,
                        isDisabled: smsCountdownManager.isSending || smsCountdownManager.countdown > 0 || (phoneMode == .input && phone.count != 11),
                        buttonText: smsCountdownManager.countdown > 0
                            ? "\(smsCountdownManager.countdown)s"
                            : (smsCountdownManager.isSending
                                ? SafeEatL10n.text(L10nKey.Common.sending)
                                : SafeEatL10n.text(L10nKey.Common.sendCode))
                    ) {
                        Task { await requestSMS() }
                    }

                    ProfileSecureField(
                        title: SafeEatL10n.text(L10nKey.Auth.newPasswordLabel),
                        text: $newPassword
                    )

                    passwordRequirementHints(newPassword)

                    ProfileSecureField(
                        title: SafeEatL10n.text(L10nKey.Auth.confirmPasswordLabel),
                        text: $confirmPassword
                    )

                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        Text(SafeEatL10n.text(L10nKey.Auth.passwordMismatch))
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.danger)
                    }
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Auth.resetPasswordAction),
                isLoading: isLoading,
                isDisabled: !canSubmit
            ) {
                resetPassword()
            }
        }
        .sheet(isPresented: $showCaptchaSheet) {
            CaptchaSheet(phone: displayPhone, scene: "reset-password", templateCode: "100003") { devCode in
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
        .alert(successMessage, isPresented: $showSuccess) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) { dismiss() }
        }
    }

    private var showErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Actions

    private func requestSMS() async {
        let targetPhone = displayPhone
        guard targetPhone.count == 11 else { return }

        if nextSmsNeedsCaptcha {
            showCaptchaSheet = true
            return
        }

        do {
            let response = try await store.sendSMS(phone: targetPhone, scene: "reset-password", templateCode: "100003")
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

    private func resetPassword() {
        let result = PasswordValidator.validate(newPassword)
        guard result.isValid else {
            errorMessage = "密码必须包含大写字母、小写字母、数字和特殊字符"
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = SafeEatL10n.text(L10nKey.Auth.passwordMismatch)
            return
        }
        isLoading = true
        Task {
            do {
                _ = try await store.api.resetPassword(phone: displayPhone, code: code, newPassword: newPassword)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - 密码强度提示

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
}
