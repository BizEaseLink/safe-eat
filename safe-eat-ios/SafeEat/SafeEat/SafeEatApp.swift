import SwiftUI
import AppTrackingTransparency
import Combine

@main
struct SafeEatApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settings = AppSettingsStore.shared
    private var adConfig: AdConfigStore { AdConfigStore.shared }
    private let notificationDelegate = NotificationDelegate()

    /// 入口流程阶段
    private enum LaunchPhase {
        case logoAnimation    // Logo 动画播放中
        case splashAd         // 开屏广告展示中
        case ready            // 进入主页面
    }

    @State private var launchPhase: LaunchPhase = .logoAnimation
    @State private var showSplashAd = false
    @State private var hasCompletedLaunch = false

    /// Logo 动画时长（秒）
    private static let logoAnimationDuration: TimeInterval = 1.67

    /// 付费会员跳过所有广告（开屏、插屏、信息流、Banner）
    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    /// 开屏广告是否应展示：配置启用 + 非付费会员 + 有有效 slotId
    private var shouldShowSplashAd: Bool {
        !isPaidMember && adConfig.splashEnabled && !(adConfig.slotId(for: .splash) ?? "").isEmpty
    }

    init() {
        SafeEatFont.bootstrap()
        SafeEatAppearance.configure()

        // 注入会员判断闭包给插屏广告管理器
        InterstitialAdManager.shared.isPremiumProvider = { [store] in
            guard let tier = store.profile?.currentPlanTier else { return false }
            return tier != "free"
        }

        #if DEBUG
        UMConfigure.setLogEnabled(true)
        UMUnionAdSdk.enableLogs(true)
        #endif
        UMConfigure.initWithAppkey(UMengConfig.appKey, channel: "App Store")
        UMUnionAdSdk.start()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .safeEatBaseFont()
                    .tint(SafeEatTheme.primary)
                    .environmentObject(store)
                    .environmentObject(settings)
                    .environment(\.locale, settings.displayLocale)
                    .task {
                        // 设置通知 delegate + 启动业务（广告配置用缓存，不在此 fetch）
                        notificationDelegate.configure(store: store)
                        await store.bootstrap()
                        await settings.refreshNotificationStatus()
                        ATTrackingManager.requestTrackingAuthorization { status in
                            print("[UMeng] IDFA 权限状态: \(status.rawValue)")
                        }
                    }

                // Logo 动画层
                if launchPhase == .logoAnimation {
                    logoAnimationLayer
                }

                // 开屏广告层
                if launchPhase == .splashAd && showSplashAd {
                    SplashAdOverlay(isShowing: $showSplashAd)
                        .onDisappear {
                            launchPhase = .ready
                        }
                        .task {
                            // 广告超时保护：5 秒后自动跳过
                            try? await Task.sleep(for: .seconds(5))
                            if launchPhase == .splashAd {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    launchPhase = .ready
                                }
                            }
                        }
                }
            }
            .onChange(of: isPaidMember) { paid in
                if paid {
                    showSplashAd = false
                    FloatingIconAdManager.shared.dismiss()
                }
            }
            .onChange(of: adConfig.splashEnabled) { enabled in
                if !enabled { showSplashAd = false }
            }
            // App 从后台回到前台时，刷新配置
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    await AdConfigStore.shared.forceRefresh()
                    await store.refreshDailyQuota()
                    await AppVersionStore.shared.checkVersion()
                }
            }
            .task {
                // 标记冷启动完成（延迟到首屏就绪后）
                try? await Task.sleep(for: .seconds(2))
                hasCompletedLaunch = true

                // 启动广告配置定时刷新（首次立即拉取，之后每 2 小时刷新）
                await AdConfigStore.shared.fetchConfig()
                AdConfigStore.shared.startPeriodicRefresh()

                // 版本检查
                await AppVersionStore.shared.checkVersion()

                // 预加载插屏广告
                if !isPaidMember && adConfig.interstitialEnabled {
                    InterstitialAdManager.shared.preloadAd()
                }
                // 浮窗广告：首次进入主页面时展示（非付费会员 + 配置启用）
                if !isPaidMember && adConfig.floatWindowEnabled {
                    let scenes = UIApplication.shared.connectedScenes
                    let windowScene = scenes.first as? UIWindowScene
                    let window = windowScene?.windows.first(where: { $0.isKeyWindow })
                    FloatingIconAdManager.shared.loadAndShow(from: window?.rootViewController)
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
            // Logo 动画播放完毕后决定下一步，广告配置用缓存直接判断
            try? await Task.sleep(for: .seconds(Self.logoAnimationDuration))
            withAnimation(.easeOut(duration: 0.3)) {
                if shouldShowSplashAd {
                    launchPhase = .splashAd
                    showSplashAd = true
                } else {
                    launchPhase = .ready
                }
            }
        }
    }
}
