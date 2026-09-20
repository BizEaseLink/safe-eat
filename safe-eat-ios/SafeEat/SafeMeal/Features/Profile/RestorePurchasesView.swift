import SwiftUI

struct RestorePurchasesView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false
    @State private var resultMessage: String?

    var body: some View {
        ProfileSecondaryPage(
            title: SafeMealL10n.text(L10nKey.Profile.RestorePurchases.title),
            subtitle: SafeMealL10n.text(L10nKey.Profile.RestorePurchases.subtitle)
        ) {
            ProfileSurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    if isRestoring {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(SafeMealL10n.text(L10nKey.Profile.RestorePurchases.restoring))
                                .font(SafeMealFont.textStyle(.body))
                                .foregroundStyle(SafeMealTheme.textSecondary)
                        }
                    } else if let resultMessage {
                        Text(resultMessage)
                            .font(SafeMealFont.textStyle(.body))
                            .foregroundStyle(SafeMealTheme.textPrimary)
                    } else {
                        Text(SafeMealL10n.text(L10nKey.Profile.RestorePurchases.subtitle))
                            .font(SafeMealFont.textStyle(.body))
                            .foregroundStyle(SafeMealTheme.textSecondary)
                    }
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeMealL10n.text(L10nKey.Profile.RestorePurchases.title),
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
                resultMessage = SafeMealL10n.text(L10nKey.Profile.RestorePurchases.success)
            }
        }
    }
}