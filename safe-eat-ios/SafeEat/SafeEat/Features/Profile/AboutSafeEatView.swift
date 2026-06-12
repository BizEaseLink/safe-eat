import SwiftUI

struct AboutSafeEatView: View {
    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.About.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.About.subtitle)
        ) {
            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.About.disclosureSection)) {
                NavigationLink(value: ProfileRoute.userAgreement) {
                    ProfileNavigationRow(
                        icon: "doc.text",
                        title: SafeEatL10n.text(L10nKey.Profile.About.userAgreement)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.privacyPolicy) {
                    ProfileNavigationRow(
                        icon: "hand.raised",
                        title: SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.valueAdded) {
                    ProfileNavigationRow(
                        icon: "star.circle",
                        title: SafeEatL10n.text(L10nKey.Profile.About.valueAdded)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.minorProtection) {
                    ProfileNavigationRow(
                        icon: "figure.child.circle",
                        title: "未成年人保护指引"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.autoRenewalNotice) {
                    ProfileNavigationRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: "自动续费说明"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.permissionUsage) {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: "权限使用说明"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.aiDisclaimer) {
                    ProfileNavigationRow(
                        icon: "lightbulb",
                        title: "AI 免责声明"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.adServiceNotice) {
                    ProfileNavigationRow(
                        icon: "megaphone",
                        title: "广告服务说明"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.cancellationGuide) {
                    ProfileNavigationRow(
                        icon: "person.crop.circle.badge.minus",
                        title: "账号注销指引"
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.certificate) {
                    ProfileNavigationRow(
                        icon: "checkmark.seal.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.About.certificate)
                    )
                }
                .buttonStyle(.plain)
            }

            Text("© 2026 郑凯杰. All Rights Reserved.")
                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                .foregroundStyle(Color.gray.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
                .padding(.bottom, 16)
        }
    }
}
