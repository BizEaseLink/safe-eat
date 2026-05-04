import SwiftUI
import AppTrackingTransparency
import Combine

@main
struct SafeEatApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settings = AppSettingsStore.shared
    @State private var adConfig = AdConfigStore.shared

    /// 入口流程阶段
    private enum LaunchPhase {
        case logoAnimation    // Logo 动画播放中
        case splashAd         // 开屏广告展示中
        case ready            // 进入主页面
    }

    @State private var launchPhase: LaunchPhase = .logoAnimation
    @State private var showSplashAd = false

    /// Logo 动画时长（秒）
    private static let logoAnimationDuration: TimeInterval = 1.67

    /// 付费会员跳过所有广告（开屏、插屏、信息流、Banner）
    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    /// 开屏广告是否应展示：配置启用 + 非付费会员 + 有有效 slotId
    private var shouldShowSplashAd: Bool {
        !isPaidMember && adConfig.splashEnabled && adConfig.slotId(for: .splash) != nil
    }

    init() {
        SafeEatFont.bootstrap()
        SafeEatAppearance.configure()

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
                        // 并行拉取广告配置和启动业务
                        await withTaskGroup(of: Void.self) { group in
                            group.addTask { await adConfig.fetchConfig() }
                            group.addTask {
                                ATTrackingManager.requestTrackingAuthorization { status in
                                    print("[UMeng] IDFA 权限状态: \(status.rawValue)")
                                }
                            }
                            group.addTask { await settings.refreshNotificationStatus() }
                            group.addTask { await store.bootstrap() }
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
                if paid { showSplashAd = false }
            }
            .onChange(of: adConfig.splashEnabled) { enabled in
                if !enabled { showSplashAd = false }
            }
            // App 从后台回到前台时，如果距上次获取超过 24h 则重新拉取
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task { await adConfig.fetchConfig() }
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
            // Logo 动画播放完毕后决定下一步
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
