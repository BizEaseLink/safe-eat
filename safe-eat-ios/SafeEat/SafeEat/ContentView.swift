import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    private let versionStore = AppVersionStore.shared

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
        // 版本更新弹窗：通过直接引用 versionStore 建立 @Observable 观察关系
        .sheet(item: Binding(
            get: { versionStore.updateInfo },
            set: { versionStore.updateInfo = $0 }
        )) { info in
            if info.forceUpdate {
                ForceUpdateSheet()
                    .interactiveDismissDisabled()
            } else {
                UpdateAvailableSheet()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
