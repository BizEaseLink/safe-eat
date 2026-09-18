import SwiftUI

/// 登录提示弹窗 — 未登录时使用需登录的功能触发
struct LoginPromptSheet: View {
    let featureHint: String?
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeMealSettingsSheetContainer(
            title: "需要登录",
            subtitle: featureHint ?? "登录后即可使用完整功能",
            contentHeight: 100,
            primaryButton: SheetButton(title: "去登录") {
                dismiss()
                store.dismissLoginPrompt()
                store.goToLogin()
            },
            secondaryButton: SheetButton(title: "稍后") {
                dismiss()
                store.dismissLoginPrompt()
            }
        ) {
            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(SafeMealTheme.primary.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(SafeMealTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("登录账号")
                            .font(SafeMealFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeMealTheme.textPrimary)

                        Text(featureHint ?? "登录后即可使用完整功能")
                            .font(SafeMealFont.textStyle(.footnote))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }
            }
        }
    }
}
