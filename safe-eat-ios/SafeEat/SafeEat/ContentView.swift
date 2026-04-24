import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if !store.hasBootstrapped {
                ProgressView()
            } else if !store.hasCompletedOnboarding {
                OnboardingView()
            } else if store.session == nil || store.requiresPhoneBinding {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .alert(
            SafeEatL10n.text(L10nKey.Errors.sessionExpired),
            isPresented: $store.showLoginPrompt,
            actions: {
                Button(SafeEatL10n.text(L10nKey.Auth.goLogin)) {
                    store.showLoginPrompt = false
                    store.logout()
                }
                Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {
                    store.showLoginPrompt = false
                }
            },
            message: {
                Text(SafeEatL10n.text(L10nKey.Auth.loginPromptMessage))
            }
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
