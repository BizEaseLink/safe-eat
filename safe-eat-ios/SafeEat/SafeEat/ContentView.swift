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
        // 强制更新弹窗
        .sheet(isPresented: Binding<Bool>(
            get: { AppVersionStore.shared.updateInfo?.forceUpdate == true },
            set: { if !$0 { AppVersionStore.shared.dismissUpdate() } }
        )) {
            ForceUpdateSheet()
        }
        // 普通更新弹窗
        .sheet(isPresented: Binding<Bool>(
            get: { AppVersionStore.shared.updateInfo?.needsUpdate == true && AppVersionStore.shared.updateInfo?.forceUpdate != true },
            set: { if !$0 { AppVersionStore.shared.dismissUpdate() } }
        )) {
            UpdateAvailableSheet()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
