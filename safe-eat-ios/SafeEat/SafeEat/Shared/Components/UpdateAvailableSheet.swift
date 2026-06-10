import SwiftUI

/// 普通更新弹窗 — 当前版本低于最新版本但高于最低支持版本，可关闭
struct UpdateAvailableSheet: View {
    private let store = AppVersionStore.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: "更新提醒",
            subtitle: "发现新版本：\(store.updateInfo?.latestVersion ?? "最新")",
            contentHeight: 180,
            primaryButton: SheetButton(title: "立即更新") {
                store.openAppStore()
            },
            secondaryButton: SheetButton(title: "稍后提醒") {
                dismiss()
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
