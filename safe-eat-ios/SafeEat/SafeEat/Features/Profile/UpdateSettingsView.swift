import StoreKit
import SwiftUI
import UIKit

struct UpdateSettingsView: View {
    @State private var isChecking = false
    @State private var showUpdateSheet = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Update.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Update.subtitle)
        ) {
            ProfileSurfaceCard {
                ProfileStaticRow(
                    label: SafeEatL10n.text(L10nKey.Profile.Update.versionLabel),
                    value: version
                )

                Divider().overlay(SafeEatTheme.line)

                Text(SafeEatL10n.text(L10nKey.Profile.Update.latest))
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }

            ProfileSurfaceCard {
                Button(action: openAppStore) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.primary)

                        Text(SafeEatL10n.text(L10nKey.Profile.Update.checkAction))
                            .font(SafeEatFont.textStyle(.body))
                            .foregroundStyle(SafeEatTheme.primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openAppStore() {
        // 使用 SKStoreProductViewController 打开 App Store
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            // 降级：使用 URL 方式
            openAppStoreURL()
            return
        }

        let storeVC = SKStoreProductViewController()
        storeVC.delegate = StoreProductDelegate.shared

        // App Store ID 需要替换为实际值
        let params: [String: Any] = [SKStoreProductParameterITunesItemIdentifier: AppConfig.appStoreID]

        storeVC.loadProduct(withParameters: params) { _, error in
            if error != nil {
                // 加载失败，降级使用 URL
                DispatchQueue.main.async {
                    openAppStoreURL()
                }
            }
        }

        rootVC.present(storeVC, animated: true)
    }

    private func openAppStoreURL() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(AppConfig.appStoreID)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - SKStoreProductViewController Delegate

private class StoreProductDelegate: NSObject, SKStoreProductViewControllerDelegate {
    static let shared = StoreProductDelegate()

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true)
    }
}