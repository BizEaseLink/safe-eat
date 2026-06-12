import SwiftUI

/// 强制更新弹窗 — 当前版本低于最低支持版本，不可关闭
struct ForceUpdateSheet: View {
    private let store = AppVersionStore.shared

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "更新提醒",
            subtitle: "发现新版本：\(store.updateInfo?.latestVersion ?? "最新")",
            contentHeight: 230,
            dismissible: false,
            primaryButton: SheetButton(title: "立即更新") {
                store.openAppStore()
            }
        ) {
            if let notes = store.updateInfo?.releaseNotes, !notes.isEmpty {
                ProfileSurfaceCard {
                    ScrollView {
                        Text(notes)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 160)
                }
            }
        }
    }
}
