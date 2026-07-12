import SwiftUI

/// 新用户欢迎弹窗 — 首次使用时展示
/// 当后端 trialAvailable=true 时，在欢迎内容下接一段免费试用领取区块，合成一个引导链路
struct NewUserWelcomeSheet: View {
    @EnvironmentObject private var store: AppStore
    @State private var isActivatingTrial = false

    let onDismiss: () -> Void

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "欢迎使用 SafeEat",
            subtitle: "让每一口都安心",
            contentHeight: contentHeight,
            primaryButton: primaryButton,
            secondaryButton: store.trialAvailable
                ? SheetButton(title: SafeEatL10n.text(L10nKey.Home.trialPromptLaterAction)) {
                    onDismiss()
                }
                : nil
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeEatTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("食品安全助手")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text("拍照即可检测食品成分安全性")
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(icon: "camera.fill", title: "拍照扫描", detail: "识别食品成分")
                    featureRow(icon: "chart.bar.fill", title: "安全评分", detail: "一目了然")
                    featureRow(icon: "bell.fill", title: "定时提醒", detail: "不遗漏保质期")
                }
            }

            if store.trialAvailable {
                trialCard
            }
        }
    }

    private var contentHeight: CGFloat {
        // 基础欢迎内容高度 + 试用卡高度（仅在 trialAvailable 时加）
        store.trialAvailable ? 400 : 230
    }

    private var primaryButton: SheetButton {
        if store.trialAvailable {
            return SheetButton(
                title: SafeEatL10n.text(L10nKey.Home.trialPromptClaimAction),
                isLoading: isActivatingTrial
            ) {
                Task { await activateTrial() }
            }
        } else {
            return SheetButton(title: "开始体验") { onDismiss() }
        }
    }

    private var trialCard: some View {
        ProfileSurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeEatTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.warning)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(SafeEatL10n.text(L10nKey.Home.trialPromptBadgeTitle))
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(SafeEatL10n.text(L10nKey.Home.trialPromptBadgeSubtitle))
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }

                Text(SafeEatL10n.text(L10nKey.Home.trialPromptFootnote))
                    .font(SafeEatFont.textStyle(.caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }

    private func activateTrial() async {
        isActivatingTrial = true
        defer { isActivatingTrial = false }
        do {
            _ = try await store.activateTrialMembership()
            // 激活后强刷 membershipStatus + plans（含 trialAvailable），保证 trialAvailable 立即变 false
            await store.loadMembershipStatus()
            await store.loadPlansWithCampaigns()
            onDismiss()
        } catch {
            // 激活失败：错误走 store.errorMessage 通道，sheet 不关（让用户重试或点"稍后使用"）
            store.errorMessage = error.localizedDescription
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SafeEatTheme.primary)
                .frame(width: 24)

            Text(title)
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Spacer()

            Text(detail)
                .font(SafeEatFont.textStyle(.caption))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }
}
