import SwiftUI

@main
struct SafeEatApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settings = AppSettingsStore.shared

    init() {
        SafeEatFont.bootstrap()
        SafeEatAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .safeEatBaseFont()
                .tint(SafeEatTheme.primary)
                .environmentObject(store)
                .environmentObject(settings)
                .environment(\.locale, settings.displayLocale)
                .task {
                    await settings.refreshNotificationStatus()
                    await store.bootstrap()
                }
        }
    }
}
