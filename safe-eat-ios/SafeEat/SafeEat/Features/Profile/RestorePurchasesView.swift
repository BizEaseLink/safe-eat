import SwiftUI

struct RestorePurchasesView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false
    @State private var resultMessage: String?

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.RestorePurchases.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.RestorePurchases.subtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    if isRestoring {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(SafeEatL10n.text(L10nKey.Profile.RestorePurchases.restoring))
                                .font(SafeEatFont.textStyle(.body))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    } else if let resultMessage {
                        Text(resultMessage)
                            .font(SafeEatFont.textStyle(.body))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                    } else {
                        Text(SafeEatL10n.text(L10nKey.Profile.RestorePurchases.subtitle))
                            .font(SafeEatFont.textStyle(.body))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Profile.RestorePurchases.title),
                isLoading: isRestoring
            ) {
                restorePurchases()
            }
        }
    }

    private func restorePurchases() {
        isRestoring = true
        resultMessage = nil
        Task {
            await store.restorePurchases()
            isRestoring = false
            if let error = store.purchaseError {
                resultMessage = error
            } else {
                resultMessage = SafeEatL10n.text(L10nKey.Profile.RestorePurchases.success)
            }
        }
    }
}