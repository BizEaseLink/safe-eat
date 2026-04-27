import SwiftUI

struct AboutSafeEatView: View {
    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.About.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.About.subtitle)
        ) {
            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.About.appName))
                    .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(SafeEatL10n.text(L10nKey.Profile.About.intro))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.About.sectionTitle))
                    .font(SafeEatFont.textStyle(.headline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(SafeEatL10n.text(L10nKey.Profile.About.sectionBody))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.About.disclosureSection)) {
                NavigationLink {
                    DisclosureDetailView(
                        title: SafeEatL10n.text(L10nKey.Profile.About.userAgreement),
                        category: "用户协议"
                    )
                } label: {
                    ProfileNavigationRow(
                        icon: "doc.text",
                        title: SafeEatL10n.text(L10nKey.Profile.About.userAgreement)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    DisclosureDetailView(
                        title: SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy),
                        category: "隐私政策"
                    )
                } label: {
                    ProfileNavigationRow(
                        icon: "hand.raised",
                        title: SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    DisclosureDetailView(
                        title: SafeEatL10n.text(L10nKey.Profile.About.valueAdded),
                        category: "增值服务协议"
                    )
                } label: {
                    ProfileNavigationRow(
                        icon: "star.circle",
                        title: SafeEatL10n.text(L10nKey.Profile.About.valueAdded)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                NavigationLink {
                    CertificateGalleryView()
                } label: {
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