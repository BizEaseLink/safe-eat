import SwiftUI

/// 强制更新弹窗 — 当前版本低于最低支持版本
struct ForceUpdateSheet: View {
    private let store = AppVersionStore.shared

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "发现新版本",
            subtitle: store.updateInfo?.releaseNotes ?? "当前版本过低，需要更新才能继续使用"
        ) {
            if let notes = store.updateInfo?.releaseNotes, !notes.isEmpty {
                ProfileSurfaceCard {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(SafeEatTheme.primary.opacity(0.12))
                                .frame(width: 46, height: 46)

                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.primary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("版本 \(store.updateInfo?.latestVersion ?? "最新")")
                                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)

                            Text("新功能与优化")
                                .font(SafeEatFont.textStyle(.footnote))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    }
                }
            }

            ProfileSurfaceCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 46, height: 46)

                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("必须更新")
                            .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text("当前版本已无法使用，请更新到最新版本")
                            .font(SafeEatFont.textStyle(.footnote))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            ProfilePrimaryActionButton(title: "立即更新", isLoading: false) {
                store.openAppStore()
            }
        }
        .interactiveDismissDisabled()
    }
}
