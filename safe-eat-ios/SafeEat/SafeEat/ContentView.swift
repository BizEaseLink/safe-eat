import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activeVersionSheet: VersionUpdateSheet?

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
        .sheet(item: $activeVersionSheet, onDismiss: {
            AppVersionStore.shared.dismissUpdate()
        }) { sheet in
            switch sheet {
            case .force:
                ForceUpdateSheet()
                    .interactiveDismissDisabled()
            case .normal:
                UpdateAvailableSheet()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppVersionStore.updateDetectedNotification)) { notification in
            guard let info = notification.object as? AppVersionCheckResponse else { return }
            store.dismissLoginPrompt()
            if info.forceUpdate {
                activeVersionSheet = .force
            } else if info.needsUpdate {
                activeVersionSheet = .normal
            }
        }
        .task {
            // 在视图挂载后检查版本，确保 .onReceive 已注册
            await AppVersionStore.shared.checkVersion()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}

private enum VersionUpdateSheet: String, Identifiable {
    case force
    case normal

    var id: String { rawValue }
}
