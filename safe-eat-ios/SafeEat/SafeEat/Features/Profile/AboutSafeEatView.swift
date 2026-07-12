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
                        title: SafeEatL10n.text(L10nKey.Profile.About.minorProtection)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.autoRenewalNotice) {
                    ProfileNavigationRow(
                        icon: "arrow.triangle.2.circlepath",
                        title: SafeEatL10n.text(L10nKey.Profile.About.autoRenewalNotice)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.permissionUsage) {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: SafeEatL10n.text(L10nKey.Profile.About.permissionUsage)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.aiDisclaimer) {
                    ProfileNavigationRow(
                        icon: "lightbulb",
                        title: SafeEatL10n.text(L10nKey.Profile.About.aiDisclaimer)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.adServiceNotice) {
                    ProfileNavigationRow(
                        icon: "megaphone",
                        title: SafeEatL10n.text(L10nKey.Profile.About.adServiceNotice)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink(value: ProfileRoute.cancellationGuide) {
                    ProfileNavigationRow(
                        icon: "person.crop.circle.badge.minus",
                        title: SafeEatL10n.text(L10nKey.Profile.About.cancellationGuide)
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

            VStack(spacing: 4) {
                Text(SafeEatL10n.text(L10nKey.Profile.About.icpRecord))
                    .font(SafeEatFont.custom(11, relativeTo: .caption2))
                    .foregroundStyle(Color.gray.opacity(0.6))
                Text(SafeEatL10n.text(L10nKey.Profile.About.copyright))
                    .font(SafeEatFont.custom(11, relativeTo: .caption2))
                    .foregroundStyle(Color.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }
}
