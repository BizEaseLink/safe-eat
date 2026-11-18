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
        case loading          // 开屏加载初始化（参数/配置/用户数据）
        case logoAnimation    // Logo 动画播放中
        case splashAd         // 开屏广告展示中
        case ready            // 进入主页面
    }

    @Environment(\.colorScheme) private var colorScheme

    @State private var launchPhase: LaunchPhase = .loading
    @State private var logoScale: CGFloat = 0.65
    @State private var showSplashAd = false
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

    /// 集中权限引导：相机 + 通知（ATT 已在启动流程中单独请求）
    /// 只在首次进入 ready 时调用一次（UserDefaults 标记），避免功能触发时反复弹窗。
    private func requestRemainingPermissions() async {
        // 相机：未决定时才请求（已允许/已拒绝不再弹）
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        // 通知：未决定时才请求
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        }
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

                // 开屏加载层（初始化参数/配置/用户数据）
                if launchPhase == .loading {
                    splashLoadingLayer
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

    /// 开屏加载层：品牌背景 + Logo + 加载指示；并行加载参数/配置/用户数据
    private var splashLoadingLayer: some View {
        ZStack {
            SafeMealMainGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                AppLogoView(size: 120)
                ProgressView()
                    .tint(SafeMealTheme.primary)
            }
        }
        .transition(.opacity)
        .task {
            // 设置通知 delegate（仅一次）
            notificationDelegate.configure(store: store)
            // 并行加载：用户业务数据 + 通知状态 + 广告配置
            async let bootstrap: Void = store.bootstrap()
            async let notify: Void = settings.refreshNotificationStatus()
            async let ads: Void = AdConfigStore.shared.fetchConfig()
            _ = await (bootstrap, notify, ads)

            withAnimation(.easeOut(duration: 0.25)) {
                launchPhase = .logoAnimation
            }
        }
    }

    /// Logo 动画层：全屏背景 + 居中 Logo + 缩放渐显动画
    private var logoAnimationLayer: some View {
        ZStack {
            // 首页同款主背景（不带几何装饰块，避免与其他遮罩层混杂）
            SafeMealMainGradientBackground()
                .ignoresSafeArea()

            // Logo：Lottie 品牌动画（播放一次）+ 弹性放大入场
            LottieLoadingView(size: 160, loop: false)
                .frame(width: 170, height: 170)
                .scaleEffect(logoScale)
                .shadow(
                    color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.18),
                    radius: 12,
                    y: 6
                )
                .onAppear {
                    // 弹一弹：0.65 缩放弹到 1.0
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.55)) {
                        logoScale = 1.0
                    }
                }

        }
        .transition(.opacity)
        .task {
            // Logo 动画播放完毕后决定下一步（广告配置在加载阶段已拉取）
            try? await Task.sleep(for: .seconds(Self.logoAnimationDuration))

            // ① ATT：必须在任何追踪数据收集（友盟/广告 SDK 启动）之前请求
            let status = await ATTrackingManager.requestTrackingAuthorization()
            print("[UMeng] IDFA 权限状态: \(status.rawValue)")

            // ② ATT 完成后再启动友盟统计 + 广告 SDK
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
    }
}
