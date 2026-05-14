import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if !store.hasBootstrapped {
                ProgressView()
            } else if !store.hasCompletedOnboarding {
                OnboardingView()
            } else if store.shouldShowLoginAfterOnboarding {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .sheet(isPresented: $store.showLoginPrompt, onDismiss: {
            store.dismissLoginPrompt()
        }) {
            LoginPromptSheet(featureHint: store.loginPromptFeature)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
