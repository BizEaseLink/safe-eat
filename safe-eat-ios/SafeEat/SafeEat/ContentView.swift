import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.session == nil {
                LoginView()
//                ScanHomeView()
            } else {
                MainTabView()
            }
        }
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        ), actions: {
            Button("知道了") {
                store.errorMessage = nil
            }
        }, message: {
            Text(store.errorMessage ?? "")
        })
    }
}

#Preview {
    ContentView()
        .environmentObject(AppStore())
}
