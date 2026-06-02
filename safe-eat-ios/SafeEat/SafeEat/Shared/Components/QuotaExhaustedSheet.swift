import SwiftUI

/// 额度耗尽弹窗 — 剩余次数不足时触发（通用版本）
struct QuotaExhaustedSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "次数不足",
            subtitle: "今日扫描次数已用完",
            detentHeight: store.profile?.currentPlanTier == "free" ? 420 : 330
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日次数已用完")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        if let quota = store.dailyQuota {
                            Text("已用 \(quota.usedCount)/\(quota.totalQuota) 次")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        } else {
                            Text("今日免费次数已用完")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }

            if store.profile?.currentPlanTier == "free" {
                ProfileSurfaceCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.primary.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "crown.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("升级会员")
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text("会员享有更多扫描次数")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }

                        Spacer()
                    }
                }
            }

            VStack(spacing: 10) {
                if store.session == nil {
                    ProfilePrimaryActionButton(title: "去登录", isLoading: false) {
                        dismiss()
                        store.goToLogin()
                    }
                }

                if store.profile?.currentPlanTier == "free" {
                    ProfilePrimaryActionButton(title: "查看会员", isLoading: false) {
                        dismiss()
                    }
                }

                ProfileSecondaryActionButton(title: "稍后") {
                    dismiss()
                }
            }
        }
    }
}