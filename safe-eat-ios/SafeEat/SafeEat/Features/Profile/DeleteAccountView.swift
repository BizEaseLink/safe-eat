import SwiftUI

struct DeleteAccountView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var showConfirmDialog = false
    @State private var errorMessage: String?
    @State private var agreedToDelete = false
    @State private var verificationCode = ""
    @State private var isSendingCode = false

    // 注销冷静期相关
    @State private var deletionStatus: String = "none"  // none / pending_cooldown / checking
    @State private var cooldownEndsAt: Date?
    @State private var remainingSeconds: Int = 0
    @State private var countdownTimer: Timer?
    @State private var isCancelling = false
    @State private var showDeleteGuide = false

    private var smsCountdown: SMSCountdownManager { SMSCountdownManager.shared }

    /// 当前用户手机号
    private var userPhone: String {
        store.profile?.phone ?? ""
    }

    /// 脱敏手机号
    private var maskedPhone: String {
        let p = userPhone
        guard p.count == 11 else { return p }
        let start = p.index(p.startIndex, offsetBy: 3)
        let end = p.index(p.startIndex, offsetBy: 7)
        return String(p[..<start]) + "****" + String(p[end...])
    }

    /// 按钮是否可点击
    private var canSubmit: Bool {
        agreedToDelete && verificationCode.count >= 4 && !isLoading
    }

    /// 冷静期剩余时间文字
    private var cooldownText: String {
        guard remainingSeconds > 0 else { return "" }
        let days = remainingSeconds / 86400
        let hours = (remainingSeconds % 86400) / 3600
        let minutes = (remainingSeconds % 3600) / 60
        if days > 0 {
            return "\(days)天 \(hours)小时 \(minutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时 \(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.DeleteAccount.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.DeleteAccount.subtitle)
        ) {
            if deletionStatus == "pending_cooldown" {
                cooldownContent
            } else {
                requestDeletionContent
            }
        } footer: {
            if deletionStatus == "pending_cooldown" {
                ProfilePrimaryActionButton(
                    title: "撤回注销申请",
                    isLoading: isCancelling
                ) {
                    cancelDeletion()
                }
            } else {
                Button(role: .destructive, action: { showConfirmDialog = true }) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmButton))
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
                                    colors: [SafeEatTheme.danger.opacity(0.85), SafeEatTheme.danger],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1.0 : 0.45)
            }
        }
        .sheet(isPresented: $showDeleteGuide) {
            NavigationStack {
                DisclosureDetailView(
                    title: SafeEatL10n.text(L10nKey.Terms.deleteGuide),
                    category: "account_cancellation_guide"
                )
            }
        }
        .task {
            await checkDeletionStatus()
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
        .alert(
            SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmDialogTitle),
            isPresented: $showConfirmDialog
        ) {
            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
            Button(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmButton), role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.confirmDialogMessage))
        }
        .alert(SafeEatL10n.text(L10nKey.Common.notice), isPresented: showError) {
            Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var showError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    // MARK: - 冷静期内容

    private var cooldownContent: some View {
        VStack(spacing: 20) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("账号注销中")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                    } icon: {
                        Image(systemName: "hourglass.circle.fill")
                            .foregroundStyle(SafeEatTheme.warning)
                    }

                    Text("您的账号已进入7天注销冷静期，冷静期结束后账号将被永久注销。冷静期内您可以随时撤回注销申请。")
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)

                    if remainingSeconds > 0 {
                        HStack {
                            Text("剩余时间")
                                .font(SafeEatFont.custom(13, relativeTo: .caption))
                                .foregroundStyle(SafeEatTheme.textSecondary)

                            Spacer()

                            Text(cooldownText)
                                .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                                .foregroundStyle(SafeEatTheme.warning)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(SafeEatTheme.warning.opacity(0.08))
                        )
                    }
                }
            }

            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("注销后影响")
                        .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    VStack(alignment: .leading, spacing: 8) {
                        deletionImpactRow(icon: "person.crop.circle.badge.xmark", text: "个人资料将被永久删除")
                        deletionImpactRow(icon: "creditcard", text: "会员权益将立即失效")
                        deletionImpactRow(icon: "clock.arrow.circlepath", text: "手机号30天内不可重新注册")
                        deletionImpactRow(icon: "doc.text", text: "交易记录将匿名化保留3年")
                    }
                }
            }
        }
    }

    private func deletionImpactRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(SafeEatTheme.danger)
                .frame(width: 20)

            Text(text)
                .font(SafeEatFont.custom(13, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    // MARK: - 申请注销内容

    private var requestDeletionContent: some View {
        VStack(spacing: 16) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.warningTitle))
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(SafeEatTheme.danger)
                    }

                    Text(SafeEatL10n.text(L10nKey.Profile.DeleteAccount.warningBody))
                        .font(SafeEatFont.custom(15, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }

            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    ProfileDisabledField(text: maskedPhone, colorScheme: colorScheme)

                    ProfileCodeRow(
                        code: $verificationCode,
                        isDisabled: isSendingCode || smsCountdown.countdown > 0,
                        buttonText: isSendingCode
                            ? SafeEatL10n.text(L10nKey.Common.sending)
                            : (smsCountdown.countdown > 0
                                ? "\(smsCountdown.countdown)s"
                                : SafeEatL10n.text(L10nKey.Common.sendCode)),
                        useDangerColor: true,
                        action: { Task { await requestSMS() } }
                    )
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Button {
                    agreedToDelete.toggle()
                } label: {
                    Image(systemName: agreedToDelete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(agreedToDelete ? SafeEatTheme.danger : SafeEatTheme.textSecondary)
                }
                .buttonStyle(.plain)

                agreementText
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
        }
    }

    private func deleteLinkText(_ display: String, url: String) -> AttributedString {
        var attr = AttributedString(display)
        attr.foregroundColor = SafeEatTheme.danger
        attr.underlineStyle = .single
        attr.link = URL(string: url)
        return attr
    }

    private var agreementText: some View {
        let guide = SafeEatL10n.text(L10nKey.Terms.deleteGuide)

        return (
            Text(SafeEatL10n.text(L10nKey.Terms.deletePrefix))
                .foregroundStyle(SafeEatTheme.textSecondary)
            + Text(deleteLinkText(guide, url: "safeeat://account_cancellation_guide"))
            + Text(SafeEatL10n.text(L10nKey.Terms.deleteSuffix))
                .foregroundStyle(SafeEatTheme.textSecondary)
        )
        .environment(\.openURL, OpenURLAction { _ in
            showDeleteGuide = true
            return .handled
        })
    }

    // MARK: - Actions

    private func checkDeletionStatus() async {
        deletionStatus = "checking"
        do {
            let response = try await store.authorizedRequest { token in
                try await store.api.getDeletionStatus(accessToken: token)
            }
            deletionStatus = response.status
            cooldownEndsAt = response.cooldownEndsAt

            if response.status == "pending_cooldown", let endsAt = response.cooldownEndsAt {
                startCooldownCountdown(endsAt: endsAt)
            }
        } catch {
            deletionStatus = "none"
        }
    }

    private func startCooldownCountdown(endsAt: Date) {
        countdownTimer?.invalidate()

        func updateRemaining() {
            let remaining = Int(endsAt.timeIntervalSinceNow)
            if remaining <= 0 {
                remainingSeconds = 0
                countdownTimer?.invalidate()
                Task { await checkDeletionStatus() }
                return
            }
            remainingSeconds = remaining
        }

        updateRemaining()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemaining()
        }
    }

    private func requestSMS() async {
        isSendingCode = true
        defer { isSendingCode = false }
        do {
            _ = try await store.sendSMS(phone: userPhone, scene: "delete-account", templateCode: "100001")
            smsCountdown.markSent()
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func deleteAccount() {
        isLoading = true
        Task {
            do {
                let response = try await store.authorizedRequest { token in
                    try await store.api.deleteAccount(
                        accessToken: token,
                        phone: userPhone,
                        code: verificationCode
                    )
                }
                deletionStatus = response.status
                cooldownEndsAt = response.cooldownEndsAt
                if let endsAt = response.cooldownEndsAt {
                    startCooldownCountdown(endsAt: endsAt)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func cancelDeletion() {
        isCancelling = true
        Task {
            do {
                let response = try await store.authorizedRequest { token in
                    try await store.api.cancelDeletion(accessToken: token)
                }
                if response.status == "cancelled" {
                    deletionStatus = "none"
                    countdownTimer?.invalidate()
                    remainingSeconds = 0
                    await store.refreshProfile()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isCancelling = false
        }
    }
}
