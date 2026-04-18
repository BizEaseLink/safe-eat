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
                Label("首页", systemImage: "camera.viewfinder")
            }

            NavigationStack {
                MenuWeekView()
            }
            .tag(AppRootTab.history)
            .tabItem {
                Label("菜单", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                ProfileView()
            }
            .tag(AppRootTab.profile)
            .tabItem {
                Label("个人", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStore())
}
