import SwiftUI

/// 普通更新弹窗 — 当前版本低于最新版本但高于最低支持版本，可关闭
struct UpdateAvailableSheet: View {
    private let store = AppVersionStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // 主标题
            Text("更新提醒")
                .font(SafeEatFont.custom(24, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .padding(.top, 28)

            // 次要标题
            Text("发现新版本：\(store.updateInfo?.latestVersion ?? "最新")")
                .font(SafeEatFont.custom(16, relativeTo: .subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .padding(.top, 8)

            // 固定高度可滚动更新信息
            if let notes = store.updateInfo?.releaseNotes, !notes.isEmpty {
                ScrollView {
                    Text(notes)
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 180)
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }

            Spacer(minLength: 16)

            // 更新按钮
            Button {
                store.openAppStore()
            } label: {
                Text("立即更新")
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            // 取消按钮
            Button {
                store.skipCurrentVersion()
            } label: {
                Text("稍后提醒")
                    .font(SafeEatFont.custom(16, relativeTo: .subheadline, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
}