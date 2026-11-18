import SwiftUI
import AppTrackingTransparency
import AVFoundation
import Combine

@main
struct SafeMealApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var settings = AppSettingsStore.shared
    private var adConfig: AdConfigStore { AdConfigStore.shared }
    private let notificationDelegate = NotificationDelegate()

    /// 入口流程阶段
    private enum LaunchPhase {
        case splash           // 开屏（同一页：加载中 → 加载完成播动画）
        case splashAd         // 开屏广告展示中
        case ready            // 进入主页面
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @State private var launchPhase: LaunchPhase = .splash
    @State private var logoScale: CGFloat = 1.0
    /// 开屏初始化是否完成（完成后同一页切 Lottie 动画）
    @State private var splashBootstrapped = false
    @State private var splashPlayingLottie = false
    @State private var showSplashAd = false
    /// ATT + 初始化流程是否已开始（避免重复）
    @State private var attFlowStarted = false
    /// 是否已完成「集中权限引导」（相机/通知只请求一次，避免用户觉得反复弹）
    @AppStorage("sm_permission_onboarding_done") private var permissionOnboardingDone = false

    /// Logo 动画时长（秒）
    /// Logo 动画时长（秒）：Lottie 单次约 1.67s，留缓冲后约 2.6s（原来太短）
    private static let logoAnimationDuration: TimeInterval = 2.6

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
        SafeMealFont.bootstrap()
        SafeMealAppearance.configure()
    }

    /// ATT + 初始化 + 开屏动画：**必须在 scenePhase == .active 时调用**，否则系统不弹窗（直接返回 0）。
    /// 全部在同一个开屏页内完成：ATT → 加载参数/配置 → 切 Lottie → 启动 SDK → 开屏广告判断。
    private func performATTThenInit() async {
        guard !attFlowStarted else { return }
        attFlowStarted = true

        print("[ATT] 请求前 scenePhase=\(scenePhase)")
        let status = await ATTrackingManager.requestTrackingAuthorization()
        print("[ATT] 请求结果 status=\(status.rawValue)（0=未决定 1=受限 2=拒绝 3=授权）")

        // 初始化（网络请求 / 参数 / 配置）
        notificationDelegate.configure(store: store)
        async let bootstrap: Void = store.bootstrap()
        async let notify: Void = settings.refreshNotificationStatus()
        async let ads: Void = AdConfigStore.shared.fetchConfig()
        _ = await (bootstrap, notify, ads)

        // 初始化完成 → 同一页切 Lottie 动画（loading 隐藏）
        splashBootstrapped = true
        withAnimation(.easeOut(duration: 0.25)) {
            splashPlayingLottie = true
        }

        // 动画播完 → 启动友盟统计/广告 SDK → 开屏广告判断
        try? await Task.sleep(for: .seconds(Self.logoAnimationDuration))
        startUMengSDKs()
        withAnimation(.easeOut(duration: 0.3)) {
            if shouldShowSplashAd {
                launchPhase = .splashAd
                showSplashAd = true
            } else {
                launchPhase = .ready
            }
        }
    }

    /// 集中权限引导：相机 + 通知（ATT 已在启动流程中单独请求）
    /// 只在首次进入 ready 时调用一次（UserDefaults 标记），避免功能触发时反复弹窗。
    private func requestRemainingPermissions() async {
        // 相机不在这里请求：改为用户打开拍照时再提示（避免启动就索取相机权限）
        // 通知：未决定时才请求
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        }
    }

    /// 系统是否为深色外观（直接读窗口 traitCollection，避免 ATT 弹窗后 SwiftUI colorScheme 环境异常导致深浅色跳变）

    /// 读取系统外观（优先 keyWindow 的 traitCollection）
    private func readSystemDark() -> Bool {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
            if let window {
                return window.traitCollection.userInterfaceStyle == .dark
            }
        }
        return UITraitCollection.current.userInterfaceStyle == .dark
    }

    /// 启动友盟 SDK（统计 + 广告）。**必须在 ATT 授权完成后调用**：
    /// Apple 要求 ATT 权限请求出现在任何可用于追踪的数据收集之前，否则审核 2.1 打回。
    private func startUMengSDKs() {
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
                    .id(settings.language) // 切换语言时重建整棵视图树,所有 L10n 文案立即生效
                    .safeMealBaseFont()
                    .tint(SafeMealTheme.primary)
                    .environmentObject(store)
                    .environmentObject(settings)
                    .environment(\.locale, settings.displayLocale)
                    .task {
                        // 注入会员判断闭包给插屏广告管理器（视图安装后再取 @StateObject，避免临时实例）
                        InterstitialAdManager.shared.isPremiumProvider = { [store] in
                            guard let tier = store.profile?.currentPlanTier else { return false }
                            return tier != "free"
                        }
                    }

                // 开屏页（同一页：加载初始化 → 完成后播 Lottie 动画）
                if launchPhase == .splash {
                    SplashOverlay(
                        bootstrapped: splashBootstrapped,
                        playingLottie: splashPlayingLottie
                    )
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
            // ATT 需要 app 处于 active 才弹：启动时若还是 inactive，等变为 active 再请求
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, launchPhase == .splash, !attFlowStarted else { return }
                Task { await performATTThenInit() }
            }
            // 集中权限引导：首次进入首页/登录页后，一次性请求相机 + 通知（之后不再弹）
            .onChange(of: launchPhase) { phase in
                guard phase == .ready, !permissionOnboardingDone else { return }
                permissionOnboardingDone = true
                Task { await requestRemainingPermissions() }
            }
            // App 从后台回到前台时，刷新配置
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    // 回到前台时用 fetchConfig（检查缓存 TTL），未过期则跳过
                    await AdConfigStore.shared.fetchConfig()
                    // 已登录才刷新用户相关数据
                    if store.session != nil {
                        await store.refreshProfile()
                        if let token = store.session?.accessToken {
                            await ConfigParamStore.shared.fetchConfig(accessToken: token)
                        }
                        await store.refreshDailyQuota()
                    }
                    await AppVersionStore.shared.checkVersion()
                    // profile 刷新完成后，由这里统一触发插屏广告判断
                    InterstitialAdManager.shared.onAppBecameActive()
                    // 浮窗广告：回到前台时检查是否可以再次弹出（受每日次数和间隔时间限制）
                    if !isPaidMember && adConfig.floatWindowEnabled {
                        let scenes = UIApplication.shared.connectedScenes
                        let windowScene = scenes.first as? UIWindowScene
                        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
                        FloatingIconAdManager.shared.loadAndShow(from: window?.rootViewController)
                    }
                }
            }
        }
    }

}