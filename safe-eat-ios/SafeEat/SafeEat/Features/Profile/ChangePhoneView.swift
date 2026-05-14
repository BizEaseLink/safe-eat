import SwiftUI

struct ChangePhoneView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var step: ChangePhoneStep = .verifyCurrent
    @State private var currentCode = ""
    @State private var newPhone = ""
    @State private var newCode = ""
    @State private var isLoading = false
    @State private var currentCountdown = 0
    @State private var newCountdown = 0
    @State private var errorMessage: String?
    @State private var showSuccess = false

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
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: showErrorMessage) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(SafeEatL10n.text(L10nKey.Profile.ChangePhone.success), isPresented: $showSuccess) {
            Button(SafeEatL10n.text(L10nKey.Common.ok)) { dismiss() }
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
                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Profile.ChangePhone.currentPhoneLabel),
                    value: maskedCurrentPhone
                )

                Divider().overlay(SafeEatTheme.line)

                HStack(spacing: 12) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Auth.codeLabel),
                        text: $currentCode,
                        keyboardType: .numberPad
                    )

                    Button(action: sendCurrentCode) {
                        Text(currentCountdown > 0
                             ? "\(currentCountdown)s"
                             : SafeEatL10n.text(L10nKey.Common.sendCode))
                            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(currentCountdown > 0 ? SafeEatTheme.textSecondary : SafeEatTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(currentCountdown > 0)
                }
            }
        }
    }

    // MARK: - Step 2: 输入新手机

    private var inputNewPhoneContent: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.ChangePhone.newPhoneLabel)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.ChangePhone.newPhoneLabel),
                        text: $newPhone,
                        keyboardType: .phonePad
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                HStack(spacing: 12) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Auth.codeLabel),
                        text: $newCode,
                        keyboardType: .numberPad
                    )

                    Button(action: sendNewCode) {
                        Text(newCountdown > 0
                             ? "\(newCountdown)s"
                             : SafeEatL10n.text(L10nKey.Profile.ChangePhone.sendNewCode))
                            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(newCountdown > 0 ? SafeEatTheme.textSecondary : SafeEatTheme.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(newCountdown > 0 || newPhone.count < 11)
                }
            }
        }
    }

    // MARK: - Actions

    private func sendCurrentCode() {
        guard let phone = store.profile?.phone else { return }
        startCurrentCountdown()
        Task {
            do {
                _ = try await store.sendSMS(phone: phone)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func verifyCurrentPhone() {
        isLoading = true
        Task {
            do {
                // 验证当前手机验证码：通过登录接口验证验证码有效性
                let phone = store.profile?.phone ?? ""
                _ = try await store.api.login(phone: phone, code: currentCode)
                // 验证码有效，进入下一步
                step = .inputNew
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func sendNewCode() {
        guard newPhone.count >= 11 else { return }
        startNewCountdown()
        Task {
            do {
                _ = try await store.sendSMS(phone: newPhone)
            } catch {
                errorMessage = error.localizedDescription
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

    private func startNewCountdown() {
        newCountdown = 60
        newTimer?.invalidate()
        newTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            newCountdown -= 1
            if newCountdown <= 0 { newTimer?.invalidate() }
        }
    }
}

private enum ChangePhoneStep {
    case verifyCurrent
    case inputNew
}