import SwiftUI

/// 普通更新弹窗 — 当前版本低于最新版本但高于最低支持版本
struct UpdateAvailableSheet: View {
    private let store = AppVersionStore.shared

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "发现新版本",
            subtitle: store.updateInfo?.releaseNotes ?? "有新版本可用",
            detentHeight: 380
        ) {
            if let notes = store.updateInfo?.releaseNotes, !notes.isEmpty {
                ProfileSurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(SafeEatTheme.primary.opacity(0.12))
                                    .frame(width: 46, height: 46)

                                Image(systemName: "sparkles")
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

                        Text(notes)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            VStack(spacing: 10) {
                ProfilePrimaryActionButton(title: "立即更新", isLoading: false) {
                    store.openAppStore()
                }

                ProfileSecondaryActionButton(title: "稍后提醒") {
                    store.skipCurrentVersion()
                }
            }
        }
    }
}