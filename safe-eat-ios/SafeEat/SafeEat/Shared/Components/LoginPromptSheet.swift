import SwiftUI

/// 登录提示弹窗 — 未登录时使用需登录的功能触发
struct LoginPromptSheet: View {
    let featureHint: String?
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "需要登录",
            subtitle: featureHint ?? "登录后即可使用完整功能"
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeEatTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("登录账号")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(featureHint ?? "登录后即可使用完整功能")
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            ProfilePrimaryActionButton(title: "去登录", isLoading: false) {
                dismiss()
                store.dismissLoginPrompt()
                store.goToLogin()
            }

            ProfileSecondaryActionButton(title: "稍后") {
                dismiss()
                store.dismissLoginPrompt()
            }
        }
    }
}
