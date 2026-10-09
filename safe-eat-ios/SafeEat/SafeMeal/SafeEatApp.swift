import SwiftUI
import Combine

@main
struct SafeMealApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settings = AppSettingsStore.shared
    private let notificationDelegate = NotificationDelegate()

    /// 入口流程阶段
    private enum LaunchPhase {
        case logoAnimation    // Logo 动画播放中
        case ready            // 进入主页面
    }

    @State private var launchPhase: LaunchPhase = .logoAnimation

    /// Logo 动画时长（秒）
    private static let logoAnimationDuration: TimeInterval = 1.67

    init() {
        SafeMealFont.bootstrap()
        SafeMealAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .id(settings.language) // 切换语言时重建整棵视图树,所有 L10n 文案立即生效
                    .safeMealBaseFont()
                    .tint(SafeMealTheme.primary)
                    .environmentObject(store)
                    .environmentObject(settings)
                    .environment(\.locale, settings.displayLocale)
                    .task {
                        // 设置通知 delegate + 启动业务
                        notificationDelegate.configure(store: store)
                        await store.bootstrap()
                        await settings.refreshNotificationStatus()
                    }

                // Logo 动画层
                if launchPhase == .logoAnimation {
                    logoAnimationLayer
                }
            }
            // App 从后台回到前台时，刷新配置
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    // 已登录才刷新用户相关数据
                    if store.session != nil {
                        await store.refreshProfile()
                        if let token = store.session?.accessToken {
                            await ConfigParamStore.shared.fetchConfig(accessToken: token)
                        }
                        await store.refreshDailyQuota()
                    }
                    await AppVersionStore.shared.checkVersion()
                }
            }
        }
    }

    /// Logo 动画层：全屏背景 + 居中 Logo + 缩放渐显动画
    private var logoAnimationLayer: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            AppLogoView(size: 160, animate: true)
        }
        .transition(.opacity)
        .task {
            // Logo 动画播放完毕后进入主页面
            try? await Task.sleep(for: .seconds(Self.logoAnimationDuration))
            withAnimation(.easeOut(duration: 0.3)) {
                launchPhase = .ready
            }
        }
    }
}
