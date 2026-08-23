import SwiftUI

/// 联系客服弹窗：展示小红书号、邮箱等联系方式
/// 使用 SafeEatSettingsSheetContainer 公共弹窗组件
struct ContactSupportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: AppStore

    @State private var showCopiedToast = false

    private var displayXhs: String {
        ConfigParamStore.shared.getString("contact_xhs", fallback: "6745295622")
    }

    private var displayEmail: String {
        ConfigParamStore.shared.getString("contact_email", fallback: "bizeaselink_SE@163.com")
    }

    var body: some View {
        SafeEatSettingsSheetContainer(
            title: SafeEatL10n.text(L10nKey.Auth.contactSupport),
            subtitle: SafeEatL10n.text(L10nKey.Auth.contactSupportSubtitle),
            contentHeight: 140,
            primaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.ok)) { dismiss() }
        ) {
            VStack(spacing: 12) {
                // 小红书号：点击复制 + toast
                contactRow(
                    iconView: AnyView(
                        Image("XhsIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    ),
                    iconColor: Color(red: 1.0, green: 0.24, blue: 0.24),
                    title: SafeEatL10n.text(L10nKey.Auth.contactXhs),
                    value: displayXhs,
                    trailingIcon: "doc.on.doc"
                ) {
                    copyToClipboard(displayXhs)
                }

                // 邮箱：点击打开 mailto（与 HelpCenterView 行为一致）
                contactRow(
                    iconView: AnyView(
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(SafeEatTheme.primary)
                    ),
                    iconColor: SafeEatTheme.primary,
                    title: SafeEatL10n.text(L10nKey.Auth.contactEmail),
                    value: displayEmail,
                    trailingIcon: "arrow.up.right.square"
                ) {
                    openMailto(displayEmail)
                }
            }
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                Text(SafeEatL10n.text(L10nKey.Auth.contactCopied))
                    .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black.opacity(colorScheme == .dark ? 0.85 : 0.75))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showCopiedToast)
        .task {
            if let token = store.session?.accessToken {
                await ConfigParamStore.shared.forceRefresh(accessToken: token)
            }
        }
    }

    private func contactRow(iconView: AnyView, iconColor: Color, title: String, value: String, trailingIcon: String, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                iconView
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(iconColor.opacity(0.10))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                    Text(value)
                        .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                }

                Spacer()

                Image(systemName: trailingIcon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.64))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        showCopiedToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCopiedToast = false
        }
    }

    private func openMailto(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ContactSupportSheet()
        .environmentObject(AppStore())
}
