import SwiftUI

/// 会员提示弹窗 — 使用付费功能时触发
struct MembershipPromptSheet: View {
    let featureHint: String?
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "升级会员",
            subtitle: featureHint ?? "解锁全部高级功能"
        ) {
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
                        Text("会员权益")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(featureHint ?? "解锁全部高级功能")
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("恢复购买")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text("如果之前已购买会员，可在此恢复")
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        Task {
                            await store.restorePurchases()
                            dismiss()
                        }
                    } label: {
                        Text("恢复")
                            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(Color.orange)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            ProfilePrimaryActionButton(title: "查看会员", isLoading: false) {
                dismiss()
            }

            ProfileSecondaryActionButton(title: "稍后") {
                dismiss()
            }
        }
    }
}
