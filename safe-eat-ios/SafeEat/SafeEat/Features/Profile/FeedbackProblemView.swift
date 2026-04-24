import SwiftUI
import UIKit

struct FeedbackProblemView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Feedback.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Feedback.subtitle)
        ) {
            ProfileSurfaceCard {
                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Profile.Feedback.versionLabel),
                    value: version
                )

                Divider().overlay(SafeEatTheme.line)

                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Profile.Feedback.deviceLabel),
                    value: SafeEatL10n.format(L10nKey.Profile.Feedback.device, UIDevice.current.model)
                )
            }

            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.Feedback.hint))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }
        }
    }
}
