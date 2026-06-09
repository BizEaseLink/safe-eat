import SwiftUI

/// 注册奖励弹窗 — 新用户注册后获得额外扫描次数
struct SignupBonusSheet: View {
    let bonusQuota: Int
    let onDismiss: () -> Void

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "注册奖励",
            subtitle: "恭喜获得额外扫描次数",
            detentHeight: 290
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "gift.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("+\(bonusQuota) 次扫描")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(SafeEatL10n.text(L10nKey.Home.signupBonusSubtitle))
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            ProfilePrimaryActionButton(title: "开始使用", isLoading: false) {
                onDismiss()
            }
        }
    }
}
