import SwiftUI

struct ChangePhoneView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var step: ChangePhoneStep = .verifyCurrent
    @State private var currentCode = ""
    @State private var newPhone = ""
    @State private var newCode = ""
    @State private var isLoading = false
    @State private var currentCountdown = 0
    @State private var newCountdown = 0
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var oldSmsSent = false
    @State private var showCaptchaSheet = false
    @State private var nextNewSmsNeedsCaptcha = false
    @State private var devCodeHint: String?

    @State private var currentTimer: Timer?
    @State private var newTimer: Timer?

    private var maskedCurrentPhone: String {
        let phone = store.profile?.phone ?? ""
        guard phone.count >= 11 else { return phone }
        let start = phone.index(phone.startIndex, offsetBy: 3)
        let end = phone.index(phone.startIndex, offsetBy: 7)
        return phone.replacingCharacters(in: start..<end, with: "****")
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.ChangePhone.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.ChangePhone.subtitle)
        ) {
            if step == .verifyCurrent {
                verifyCurrentPhoneContent
            } else {
                inputNewPhoneContent
            }
        } footer: {
            if step == .verifyCurrent {
                ProfilePrimaryActionButton(
                    title: SafeEatL10n.text(L10nKey.Profile.ChangePhone.stepVerifyCurrent),
                    isLoading: isLoading,
                    isDisabled: currentCode.count < 4
                ) {
                    verifyCurrentPhone()
                }
            } else {
                ProfilePrimaryActionButton(
                    title: SafeEatL10n.text(L10nKey.Profile.ChangePhone.stepInputNew),
                    isLoading: isLoading,
                    isDisabled: newCode.count < 4 || newPhone.count < 11
                ) {
                    updatePhone()
                }
            }
        }
        .sheet(isPresented: $showCaptchaSheet) {
            CaptchaSheet(phone: newPhone, scene: "change-phone-new", templateCode: "100004") { devCode in
                if let devCode, !devCode.isEmpty {
                    devCodeHint = devCode
                }
                nextNewSmsNeedsCaptcha = true
            }
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: showErrorMessage) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(SafeEatL10n.text(L10nKey.Profile.ChangePhone.success), isPresented: $showSuccess) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) { dismiss() }
        }
        .onDisappear {
            currentTimer?.invalidate()
            newTimer?.invalidate()
        }
    }

    private var showErrorMessage: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - Step 1: 验证当前手机

    private var verifyCurrentPhoneContent: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                ProfileDisabledField(text: maskedCurrentPhone, colorScheme: colorScheme)

                ProfileCodeRow(
                    code: $currentCode,
                    isDisabled: oldSmsSent || currentCountdown > 0,
                    buttonText: oldSmsSent
                        ? SafeEatL10n.text(L10nKey.Auth.smsSent)
                        : (currentCountdown > 0
                           ? "\(currentCountdown)s"
                           : SafeEatL10n.text(L10nKey.Common.sendCode)),
                    action: sendCurrentCode
                )

                smsHintView
            }
        }
    }

    // MARK: - Step 2: 输入新手机

    private var inputNewPhoneContent: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                ProfileTextField(
                    title: SafeEatL10n.text(L10nKey.Profile.ChangePhone.newPhoneLabel),
                    text: $newPhone,
                    keyboardType: .phonePad
                )

                ProfileCodeRow(
                    code: $newCode,
                    isDisabled: newCountdown > 0 || newPhone.count < 11,
                    buttonText: newCountdown > 0
                        ? "\(newCountdown)s"
                        : SafeEatL10n.text(L10nKey.Profile.ChangePhone.sendNewCode),
                    action: sendNewCode
                )

                smsHintView
            }
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

    // MARK: - Actions

    private func sendCurrentCode() {
        guard let phone = store.profile?.phone else { return }
        startCurrentCountdown()
        Task {
            do {
                _ = try await store.authorizedRequest { token in
                    try await store.api.sendChangePhoneOldSms(accessToken: token, phone: phone)
                }
                oldSmsSent = true
            } catch {
                errorMessage = error.localizedDescription
                stopCurrentCountdown()
            }
        }
    }

    private func verifyCurrentPhone() {
        guard let phone = store.profile?.phone else {
            errorMessage = "手机号获取失败"
            return
        }
        isLoading = true
        Task {
            do {
                let result = try await store.authorizedRequest { token in
                    try await store.api.verifyChangePhoneOld(accessToken: token, phone: phone, code: currentCode)
                }
                if result.verified == true {
                    step = .inputNew
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func sendNewCode() {
        guard newPhone.count >= 11 else { return }

        if nextNewSmsNeedsCaptcha {
            showCaptchaSheet = true
            return
        }

        startNewCountdown()
        Task {
            do {
                let response = try await store.sendSMS(phone: newPhone, scene: "change-phone-new", templateCode: "100004")
                SMSCountdownManager.shared.markSent()
                if let devCode = response.devCode, !devCode.isEmpty {
                    devCodeHint = devCode
                }
                if response.needCaptcha == true {
                    nextNewSmsNeedsCaptcha = true
                }
            } catch let error as APIError {
                if error.localizedDescription.contains("图形验证码") {
                    nextNewSmsNeedsCaptcha = true
                    showCaptchaSheet = true
                } else {
                    errorMessage = error.localizedDescription
                }
                stopNewCountdown()
            } catch {
                errorMessage = error.localizedDescription
                stopNewCountdown()
            }
        }
    }

    private func updatePhone() {
        isLoading = true
        Task {
            do {
                let updated = try await store.authorizedRequest { token in
                    try await store.api.changePhone(accessToken: token, newPhone: newPhone, code: newCode)
                }
                store.profile = updated
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - 倒计时

    private func startCurrentCountdown() {
        currentCountdown = 60
        currentTimer?.invalidate()
        currentTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentCountdown -= 1
            if currentCountdown <= 0 { currentTimer?.invalidate() }
        }
    }

    private func stopCurrentCountdown() {
        currentTimer?.invalidate()
        currentCountdown = 0
    }

    private func startNewCountdown() {
        newCountdown = 60
        newTimer?.invalidate()
        newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            newCountdown -= 1
            if newCountdown <= 0 { newTimer?.invalidate() }
        }
    }

    private func stopNewCountdown() {
        newTimer?.invalidate()
        newCountdown = 0
    }
}

private enum ChangePhoneStep: Hashable {
    case verifyCurrent
    case inputNew
}
