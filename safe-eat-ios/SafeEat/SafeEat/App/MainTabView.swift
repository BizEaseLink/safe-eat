import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedRootTab) {
            NavigationStack {
                ScanHomeView()
            }
            .tag(AppRootTab.home)
            .tabItem {
                Label(SafeEatL10n.text(L10nKey.Home.title), systemImage: "camera.viewfinder")
            }

            NavigationStack {
                MenuWeekView()
            }
            .tag(AppRootTab.history)
            .tabItem {
                Label(SafeEatL10n.text(L10nKey.Menu.title), systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(AppRootTab.profile)
            .tabItem {
                Label(SafeEatL10n.text(L10nKey.Profile.title), systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStore())
}
