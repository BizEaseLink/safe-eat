import SwiftUI

/// 新用户欢迎弹窗 — 首次使用时展示
struct NewUserWelcomeSheet: View {
    let onDismiss: () -> Void

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "欢迎使用 SafeEat",
            subtitle: "让每一口都安心",
            contentHeight: 230,
            primaryButton: SheetButton(title: "开始体验") { onDismiss() }
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
