import SwiftUI

/// 新用户欢迎弹窗 — 首次使用时展示
/// 当后端 trialAvailable=true 时，在欢迎内容下接一段免费试用领取区块，合成一个引导链路
struct NewUserWelcomeSheet: View {
    @EnvironmentObject private var store: AppStore
    @State private var isActivatingTrial = false
    @State private var successMessage: String?

    let onDismiss: () -> Void

    var body: some View {
        SafeMealSettingsSheetContainer(
            title: SafeMealL10n.text(L10nKey.Home.welcomeTitle),
            subtitle: SafeMealL10n.text(L10nKey.Home.welcomeSubtitle),
            contentHeight: contentHeight,
            primaryButton: primaryButton,
            secondaryButton: store.trialAvailable
                ? SheetButton(title: SafeMealL10n.text(L10nKey.Home.trialPromptLaterAction)) {
                    onDismiss()
                }
                : nil
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeMealTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeMealTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(SafeMealL10n.text(L10nKey.Home.welcomeAppName))
                            .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeMealTheme.textPrimary)

                        Text(SafeMealL10n.text(L10nKey.Home.welcomeAppTagline))
                            .font(SafeMealFont.textStyle(.footnote))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }
            }

            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(
                        icon: "camera.fill",
                        title: SafeMealL10n.text(L10nKey.Home.welcomeFeatureScanTitle),
                        detail: SafeMealL10n.text(L10nKey.Home.welcomeFeatureScanDetail)
                    )
                    featureRow(
                        icon: "chart.bar.fill",
                        title: SafeMealL10n.text(L10nKey.Home.welcomeFeatureScoreTitle),
                        detail: SafeMealL10n.text(L10nKey.Home.welcomeFeatureScoreDetail)
                    )
                    featureRow(
                        icon: "bell.fill",
                        title: SafeMealL10n.text(L10nKey.Home.welcomeFeatureReminderTitle),
                        detail: SafeMealL10n.text(L10nKey.Home.welcomeFeatureReminderDetail)
                    )
                }
            }

            if store.trialAvailable {
                trialCard
            }
        }
        .alert(SafeMealL10n.text(L10nKey.Membership.noticeTitle), isPresented: Binding(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button(SafeMealL10n.text(L10nKey.Common.ok)) {
                successMessage = nil
                onDismiss()
            }
        } message: {
            Text(successMessage ?? "")
        }
        // 试用激活失败：走 store.errorMessage 通道，sheet 不关，让用户重试或点"稍后再说"
        .alert(SafeMealL10n.text(L10nKey.Membership.noticeTitle), isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button(SafeMealL10n.text(L10nKey.Common.ok)) {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private var contentHeight: CGFloat {
        // 基础欢迎内容高度 + 试用卡高度（仅在 trialAvailable 时加）
        store.trialAvailable ? 400 : 230
    }

    private var primaryButton: SheetButton {
        if store.trialAvailable {
            return SheetButton(
                title: SafeMealL10n.text(L10nKey.Home.trialPromptClaimAction),
                isLoading: isActivatingTrial
            ) {
                Task { await activateTrial() }
            }
        } else {
            return SheetButton(title: SafeMealL10n.text(L10nKey.Home.welcomeStartAction)) { onDismiss() }
        }
    }

    private var trialCard: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeMealTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeMealTheme.warning)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(SafeMealL10n.text(L10nKey.Home.trialPromptBadgeTitle))
                            .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeMealTheme.textPrimary)

                        Text(SafeMealL10n.text(L10nKey.Home.trialPromptBadgeSubtitle))
                            .font(SafeMealFont.textStyle(.footnote))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }

                Text(SafeMealL10n.text(L10nKey.Home.trialPromptFootnote))
                    .font(SafeMealFont.textStyle(.caption))
                    .foregroundStyle(SafeMealTheme.textSecondary)
            }
        }
    }

    private func activateTrial() async {
        isActivatingTrial = true
        defer { isActivatingTrial = false }
        // 走共享激活流程：成功刷新 membership/plans 并返回 true；失败写入 store.errorMessage 并返回 false
        let ok = await store.activateTrialAndRefresh()
        if ok {
            // 成功：弹统一成功提示，用户点 OK 后再关 sheet（先关 sheet alert 会消失）
            successMessage = SafeMealL10n.text(L10nKey.Home.trialPromptSuccessMessage)
        }
        // 失败：store.errorMessage 已设置，sheet 不关，让用户重试或点"稍后再说"
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SafeMealTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(SafeMealFont.textStyle(.subheadline))
                .foregroundStyle(SafeMealTheme.textPrimary)

            Spacer()

            Text(detail)
                .font(SafeMealFont.textStyle(.caption))
                .foregroundStyle(SafeMealTheme.textSecondary)
        }
    }
}
