import SwiftUI

struct CacheSettingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showClearConfirm = false

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.Cache.title),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Cache.subtitle)
        ) {
            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.Cache.currentSection)) {
                ProfileStaticRow(label: SafeEatL10n.text(L10nKey.Profile.Cache.localRecords), value: "\(store.localCacheCount)")
                Divider().overlay(SafeEatTheme.line)
                ProfileStaticRow(label: SafeEatL10n.text(L10nKey.Profile.Cache.cacheSize), value: store.localCacheSizeText)
            }

            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.Cache.actionSection)) {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    HStack {
                        Text(SafeEatL10n.text(L10nKey.Profile.Cache.clearAction))
                            .foregroundStyle(SafeEatTheme.danger)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .alert(SafeEatL10n.text(L10nKey.Profile.Cache.confirmTitle), isPresented: $showClearConfirm) {
            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
            Button(SafeEatL10n.text(L10nKey.Common.clear), role: .destructive) {
                store.clearLocalCache()
            }
        } message: {
            Text(SafeEatL10n.text(L10nKey.Profile.Cache.confirmMessage))
        }
    }
}
