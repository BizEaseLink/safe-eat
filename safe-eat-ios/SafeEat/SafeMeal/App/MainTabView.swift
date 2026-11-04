import SwiftUI

// 历史 Tab 内的页面层级状态。
// 不用 @Observable class 跨视图追踪（依赖环境传递 + Observation 追踪，易断链），
// 改用 Environment 绑定的 Binding<Bool> 直连 MainTabView 的 @State，
// 写值必然触发 MainTabView body 重算，最可靠。
private struct HistoryStackRootKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(true)
}

private struct ResultDetailPresentedKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    /// 是否在 MenuWeekView 根页面（未 push 日/周视图）
    var historyStackRoot: Binding<Bool> {
        get { self[HistoryStackRootKey.self] }
        set { self[HistoryStackRootKey.self] = newValue }
    }
    /// 是否从 HistoryDayView/HistoryWeekView push 到了 ResultView
    var resultDetailPresented: Binding<Bool> {
        get { self[ResultDetailPresentedKey.self] }
        set { self[ResultDetailPresentedKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @State private var showCamera = false
    @State private var showNonFoodSheet = false
    @State private var showMembership = false
    @State private var showQuotaExceeded = false

    @State private var recognitionPhase: RecognitionPhase?
    @State private var recognizingPreviewImage: UIImage?
    @State private var resultRoute: ResultRoute?
    @State private var showAdRewardResult = false
    @State private var adRewardResultType: AdRewardResultType = .claimFailed
    // 识别流程中间数据
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var scanPressed = false
    @State private var homePath = NavigationPath()
    @State private var historyPath = NavigationPath()
    // @State private var trendPath = NavigationPath()  // v1.3.0 启用
    @State private var profilePath = NavigationPath()
    @State private var showNotificationCenter = false

    private var adConfig: AdConfigStore { AdConfigStore.shared }

    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    private var isFreeQuotaExceeded: Bool {
        guard store.profile?.currentPlanTier == nil || store.profile?.currentPlanTier == "free" else { return false }
        guard let quota = store.dailyQuota else { return false }
        return quota.remainingQuota <= 0
    }

    private var isLoggedIn: Bool {
        guard store.hasBootstrapped else { return true }
        return store.session != nil
    }

    // 当前选中的 Tab
    @State private var selectedTab: AppRootTab = .home

    // 历史 Tab 的页面层级状态（via Environment Binding 直写，见 isAtRoot）
    @State private var historyStackRoot = true
    @State private var resultDetailPresented = false

    private var isAtRoot: Bool {
        switch selectedTab {
        case .home:
            return homePath.isEmpty && resultRoute == nil && !showMembership && recognitionPhase == nil && !showNotificationCenter
        case .history:
            // historyPath 恒为空（MenuWeekView 用本地 dayRoute/weekRoute push）
            // historyStackRoot: 是否在 MenuWeekView 根页面（子视图经 Binding 直写）
            // resultDetailPresented: 是否 push 到了 ResultView（HistoryDay/WeekView 经 Binding 直写）
            let histPathEmpty = historyPath.isEmpty
            let root = historyStackRoot
            let detail = resultDetailPresented
            let atRoot = histPathEmpty && root && !detail
            #if DEBUG
            print("[DBG isAtRoot] selectedTab=\(selectedTab) pathEmpty=\(histPathEmpty) historyStackRoot=\(root) resultDetailPresented=\(detail) => atRoot=\(atRoot)")
            #endif
            return atRoot
        // case .trend:  // v1.3.0 启用
        //     return trendPath.isEmpty
        case .profile:
            return profilePath.isEmpty
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // 内容区域
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack(path: $homePath) {
                        ScanHomeView(
                            showNotificationCenter: $showNotificationCenter,
                            onShowMembership: { showMembership = true },
                            onOpenResult: { itemId in
                                resultRoute = ResultRoute(id: itemId, itemId: itemId)
                            }
                        )
                        .navigationDestination(item: $resultRoute) { route in
                            ResultView(itemId: route.itemId, isPending: route.isPending)
                        }
                        .navigationDestination(isPresented: $showMembership) {
                            MembershipPurchaseView()
                        }
                    }

                case .history:
                    NavigationStack(path: $historyPath) {
                        MenuWeekView()
                    }

                // case .trend:  // v1.3.0 启用
                //     NavigationStack(path: $trendPath) {
                //         TrendPlaceholderView()
                //     }

                case .profile:
                    NavigationStack(path: $profilePath) {
                        ProfileView()
                            .navigationDestination(item: $store.pushProfileRoute) { route in
                                profileDestination(for: route)
                            }
                    }
                }
            }


            // 底部浮动导航区域（只在根页面显示）
            if isAtRoot {
                floatingBottomBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAtRoot)
        .toolbar(.hidden, for: .tabBar)
        .environment(\.historyStackRoot, $historyStackRoot)
        .environment(\.resultDetailPresented, $resultDetailPresented)
        .onChange(of: store.retakeRequested) { _, flag in
            if flag {
                store.retakeRequested = false
                showCamera = true
            }
        }
        .onChange(of: store.selectedRootTab) { _, newTab in
            if selectedTab != newTab {
                selectedTab = newTab
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { payload in
                guard !isFreeQuotaExceeded else {
                    showQuotaExceeded = true
                    return
                }
                // P5：拍照直入结果页骨架屏，identify 移到结果页执行（砍「识别中遮罩」）
                store.pendingRecognition = PendingRecognitionTask(croppedImage: payload.croppedImage, rawImage: payload.rawImage)
                recognitionPhase = nil
                recognizingPreviewImage = nil
                selectedTab = .home
                store.selectedRootTab = .home
                resultRoute = ResultRoute(id: UUID().uuidString, itemId: "pending-\(UUID().uuidString)", isPending: true)
            }
        }
        .sheet(isPresented: $showNonFoodSheet) {
            SafeMealSettingsSheetContainer(
                title: SafeMealL10n.text(L10nKey.RecognitionPhase.nonFoodTitle),
                subtitle: SafeMealL10n.text(L10nKey.RecognitionPhase.nonFoodSubtitle),
                contentHeight: 120,
                primaryButton: SheetButton(title: SafeMealL10n.text(L10nKey.Result.actionRetake)) {
                    showNonFoodSheet = false
                    showCamera = true
                },
                secondaryButton: SheetButton(title: SafeMealL10n.text(L10nKey.Common.back)) {
                    showNonFoodSheet = false
                }
            ) {
                // 内容区：展示用户拍的预览图，提示未识别
                if let preview = recognizingPreviewImage {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .sheet(isPresented: $showQuotaExceeded) {
            QuotaExceededSheet(
                snapshot: store.dailyQuota ?? DailyQuotaSnapshot(
                    planTier: "FREE",
                    totalQuota: 0,
                    usedCount: 0,
                    remainingQuota: 0,
                    adClaimsCount: 0,
                    adRewardPerWatch: nil,
                    adWatchLimit: nil,
                    remainingAdWatchCount: nil,
                    quotaDate: "",
                    monthlyTotalQuota: nil,
                    monthlyUsedCount: nil,
                    monthlyRemaining: nil,
                    periodStart: nil,
                    periodEnd: nil
                ),
                onWatchAd: adConfig.rewardVideoEnabled ? { watchRewardAd() } : nil,
                onUpgrade: { showQuotaExceeded = false; showMembership = true },
                onDismiss: { showQuotaExceeded = false }
            )
        }
        .sheet(isPresented: $showAdRewardResult) {
            AdRewardResultSheet(resultType: adRewardResultType)
        }
        .alert(
            SafeMealL10n.text(L10nKey.Common.notice),
            isPresented: Binding<Bool>(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            ),
            actions: {
                Button(SafeMealL10n.text(L10nKey.Common.ok), role: .cancel) { store.errorMessage = nil }
            },
            message: {
                Text(store.errorMessage ?? "")
            }
        )
        // 本地网络权限被拒绝时的专用引导弹窗
        .alert(
            SafeMealL10n.text(L10nKey.Errors.localNetworkDeniedTitle),
            isPresented: $store.showLocalNetworkDenied,
            actions: {
                Button(SafeMealL10n.text(L10nKey.Errors.localNetworkOpenSettings)) {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(settingsURL)
                }
                Button(SafeMealL10n.text(L10nKey.Common.cancel), role: .cancel) {}
            },
            message: {
                Text(SafeMealL10n.text(L10nKey.Errors.localNetworkDeniedBody))
            }
        )
        .task {
            await store.refreshDailyQuota()
        }
        // 初始化配置：进入首页 2 秒后后台拉取广告配置和参数配置
        // 仅在初始化时检查缓存过期，使用时直接读内存不检查过期
        .task {
            try? await Task.sleep(for: .seconds(2))
            async let adConfigTask: Void = AdConfigStore.shared.fetchConfig()
            if let token = store.session?.accessToken {
                async let paramConfigTask: Void = ConfigParamStore.shared.fetchConfig(accessToken: token)
                _ = await (adConfigTask, paramConfigTask)
            } else {
                await adConfigTask
            }
            // 配置拉取完成后，执行依赖配置的动作
            if !isPaidMember && adConfig.interstitialEnabled {
                InterstitialAdManager.shared.preloadAd()
            }
            if !isPaidMember && adConfig.floatWindowEnabled {
                let scenes = UIApplication.shared.connectedScenes
                let windowScene = scenes.first as? UIWindowScene
                let window = windowScene?.windows.first(where: { $0.isKeyWindow })
                FloatingIconAdManager.shared.loadAndShow(from: window?.rootViewController)
            }
        }
    }

    // MARK: - 浮动底部导航栏

    private var floatingBottomBar: some View {
        HStack(spacing: 4) {
            // 拍摄按钮
            scanBarItem

            tabBarItem(tab: .home, icon: "house.fill", label: SafeMealL10n.text(L10nKey.Tab.home))

            tabBarItem(tab: .history, icon: "book.closed.fill", label: SafeMealL10n.text(L10nKey.Tab.menu))

            // tabBarItem(tab: .trend, icon: "chart.line.uptrend.xyaxis", label: SafeMealL10n.text(L10nKey.Tab.trend))  // v1.3.0 启用

            tabBarItem(tab: .profile, icon: "person.fill", label: SafeMealL10n.text(L10nKey.Tab.profile))
        }
        .accessibilityIdentifier("floatingBottomBar")
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
        )
        .overlay(
            Capsule()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private var scanBarItem: some View {
        Button {
            scanPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                scanPressed = false
            }
            startScan()
        } label: {
            VStack(spacing: 6) {
                HugeIcon(glyph: .camera01, size: 18)
                    .foregroundColor(scanPressed ? SafeMealTheme.primary : SafeMealTheme.textSecondary)
                Text(SafeMealL10n.text(L10nKey.Tab.scan))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(scanPressed ? SafeMealTheme.primary : SafeMealTheme.textSecondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(minWidth: 56)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(scanPressed ? SafeMealTheme.primary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func tabBarItem(tab: AppRootTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        let iconColor: Color = isSelected ? SafeMealTheme.primary : SafeMealTheme.textSecondary
        return Button {
            selectedTab = tab
            store.selectedRootTab = tab
        } label: {
            VStack(spacing: 6) {
                HugeIcon(sf: icon, size: 18)
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(iconColor)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(minWidth: 56)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? SafeMealTheme.primary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 扫描逻辑

    private func startScan() {
        guard recognitionPhase == nil else { return }

        guard store.session != nil else {
            store.requireLogin(featureHint: SafeMealL10n.text(L10nKey.Home.scanAction))
            return
        }

        if isFreeQuotaExceeded {
            showQuotaExceeded = true
            return
        }

        showCamera = true
    }

    private func watchRewardAd() {
        guard let vc = AdTopVC.resolve() else {
            print("[UMeng] 无法获取 rootViewController")
            return
        }
        print("[UMeng] 开始加载激励视频，vc=\(vc)")
        RewardAdManager.shared.loadAndShow(from: vc,
            onReward: { proofToken in
                Task {
                    do {
                        _ = try await store.authorizedRequest { token in
                            try await store.api.claimAdReward(
                                accessToken: token,
                                payload: ClaimAdRewardPayload(
                                    placementCode: "reward_video",
                                    proofToken: proofToken
                                )
                            )
                        }
                        await store.refreshProfile()
                        await store.refreshDailyQuota()
                        adRewardResultType = .success(rewardQuota: store.dailyQuota?.adRewardPerWatch ?? Int(ConfigParamStore.shared.getNumber("ads_reward_video_quota", fallback: 3)))
                        showQuotaExceeded = false
                        showAdRewardResult = true
                    } catch {
                        print("[UMeng] claimReward 失败: \(error)")
                        await store.refreshProfile()
                        await store.refreshDailyQuota()
                        adRewardResultType = .claimFailed
                        showQuotaExceeded = false
                        showAdRewardResult = true
                    }
                }
            },
            onClose: { normalClose in
                if !normalClose {
                    adRewardResultType = .loadFailed
                    showAdRewardResult = true
                }
            }
        )
    }

    @ViewBuilder
    private func profileDestination(for route: ProfileRoute) -> some View {
        switch route {
        case .membership:
            MembershipPurchaseView()
        case .updates:
            UpdateSettingsView()
        case .feedback:
            FeedbackProblemView()
        case .helpCenter:
            HelpCenterView()
        default:
            ProfileView()
        }
    }
}

private struct ResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID
    /// P2: 待确认直进结果页（confirm 在结果页 pending 态执行，itemId 为占位）
    var isPending: Bool = false

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


#Preview {
    MainTabView()
        .environmentObject(AppStore())
        .environmentObject(AppSettingsStore.shared)
}
