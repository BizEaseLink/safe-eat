import MessageUI
import SwiftUI
import UIKit

struct FeedbackProblemView: View {
    @State private var showMailComposer = false
    @State private var mailResult: Result<MFMailComposeResult, Error>?

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var deviceInfo: String {
        let device = UIDevice.current
        return """
        设备：\(device.model)
        系统版本：\(device.systemName) \(device.systemVersion)
        应用版本：\(version) (\(build))
        """
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
                VStack(alignment: .leading, spacing: 12) {
                    Text(SafeEatL10n.text(L10nKey.Profile.Feedback.hint))
                        .font(SafeEatFont.textStyle(.body))
                        .foregroundStyle(SafeEatTheme.textPrimary)

                    Divider().overlay(SafeEatTheme.line)

                    Button(action: { showMailComposer = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.primary)

                            Text(SafeEatL10n.text(L10nKey.Profile.Feedback.emailAction))
                                .font(SafeEatFont.textStyle(.body))
                                .foregroundStyle(SafeEatTheme.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } footer: {
            EmptyView()
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposeView(
                toRecipients: ["1440531680@qq.com"],
                subject: "食安安用户反馈",
                messageBody: "\n\n---\n\(deviceInfo)"
            )
        }
    }
}

// MARK: - MFMailComposeViewController 包装

struct MailComposeView: UIViewControllerRepresentable {
    let toRecipients: [String]
    let subject: String
    let messageBody: String

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients(toRecipients)
        controller.setSubject(subject)
        controller.setMessageBody(messageBody, isHTML: false)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}
