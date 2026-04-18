import SwiftUI
import UserNotifications

@main
struct SafeEatApp: App {
    @StateObject private var store = AppStore()

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
                .task {
                    await store.bootstrap()
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                        if let error = error {
                            print("通知授权失败: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}
