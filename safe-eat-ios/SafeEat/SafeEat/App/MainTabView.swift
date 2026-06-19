import SwiftUI

// 共享导航状态：子页面通过 Environment 通知 MainTabView 自己是否在根页面
@Observable
class TabNavigationState {
    var isHistoryAtRoot: Bool = true
}

private struct TabNavigationStateKey: EnvironmentKey {
    static let defaultValue = TabNavigationState()
}

extension EnvironmentValues {
    var tabNavigationState: TabNavigationState {
        get { self[TabNavigationStateKey.self] }
        set { self[TabNavigationStateKey.self] = newValue }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @State private var showCamera = false
    @State private var showMembership = false
    @State private var showQuotaExceeded = false
    @State private var recognitionPhase: RecognitionPhase?
    @State private var recognizingPreviewImage: UIImage?
    @State private var resultRoute: ResultRoute?
    @State private var showAdRewardResult = false
    @State private var adRewardResultType: AdRewardResultType = .claimFailed
    @State private var showSignupBonus = false
    // 识别流程中间数据
    @State private var identifySession: IdentifySessionData?
    @Environment(\.colorScheme) private var colorScheme
    @State private var scanPressed = false
    @State private var homePath = NavigationPath()
    @State private var historyPath = NavigationPath()
    // @State private var trendPath = NavigationPath()  // v1.3.0 启用
    @State private var profilePath = NavigationPath()

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

    @State private var tabNavState = TabNavigationState()

    private var isAtRoot: Bool {
        switch selectedTab {
        case .home:
            return homePath.isEmpty && resultRoute == nil && !showMembership && recognitionPhase == nil
        case .history:
            return historyPath.isEmpty && tabNavState.isHistoryAtRoot
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
                            onShowMembership: { showMembership = true },
                            onOpenResult: { itemId in
                                resultRoute = ResultRoute(id: itemId, itemId: itemId)
                            }
                        )
                        .navigationDestination(item: $resultRoute) { route in
                            ResultView(itemId: route.itemId)
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
                    }
                }
            }

            // 识别中加载遮罩
            if let phase = recognitionPhase {
                SafeEatLoadingOverlay(
                    phase: phase,
                    previewImage: recognizingPreviewImage,
                    onCandidateSelected: { selectedName, sessionId in
                        performConfirm(selectedName: selectedName, sessionId: sessionId)
                    },
                    onDismiss: {
                        recognitionPhase = nil
                        recognizingPreviewImage = nil
                    }
                )
                .transition(.opacity)
                .zIndex(30)
            }

            // 底部浮动导航区域（只在根页面显示）
            if isAtRoot {
                floatingBottomBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isAtRoot)
        .toolbar(.hidden, for: .tabBar)
        .environment(tabNavState)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { payload in
                guard !isFreeQuotaExceeded else {
                    showQuotaExceeded = true
                    return
                }
                recognizingPreviewImage = payload.croppedImage.loadingOverlayPreviewImage()
                Task {
                    await recognize(croppedImage: payload.croppedImage, rawImage: payload.rawImage)
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
        .sheet(isPresented: $showSignupBonus) {
            SignupBonusSheet(bonusQuota: 10) {
                showSignupBonus = false
                store.pendingSignupBonus = false
            }
        }
        .alert(
            SafeEatL10n.text(L10nKey.Common.notice),
            isPresented: Binding<Bool>(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            ),
            actions: {
                Button(SafeEatL10n.text(L10nKey.Common.ok), role: .cancel) { store.errorMessage = nil }
            },
            message: {
                Text(store.errorMessage ?? "")
            }
        )
        .task {
            await store.refreshDailyQuota()
            if store.pendingSignupBonus {
                showSignupBonus = true
            }
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
            // 拍摄按钮（第一位）
            scanBarItem

            tabBarItem(tab: .home, icon: "house.fill", label: SafeEatL10n.text(L10nKey.Tab.home))

            tabBarItem(tab: .history, icon: "book.closed.fill", label: SafeEatL10n.text(L10nKey.Tab.menu))

            // tabBarItem(tab: .trend, icon: "chart.line.uptrend.xyaxis", label: SafeEatL10n.text(L10nKey.Tab.trend))  // v1.3.0 启用

            tabBarItem(tab: .profile, icon: "person.fill", label: SafeEatL10n.text(L10nKey.Tab.profile))
        }
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
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(scanPressed ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                Text(SafeEatL10n.text(L10nKey.Tab.scan))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(scanPressed ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(minWidth: 56)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(scanPressed ? SafeEatTheme.primary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private func tabBarItem(tab: AppRootTab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        let iconColor: Color = isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary
        return Button {
            selectedTab = tab
            store.selectedRootTab = tab
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
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
                    .fill(isSelected ? SafeEatTheme.primary.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 扫描逻辑

    private func startScan() {
        guard recognitionPhase == nil else { return }

        guard store.session != nil else {
            store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Home.scanAction))
            return
        }

        if isFreeQuotaExceeded {
            showQuotaExceeded = true
            return
        }

        showCamera = true
    }

    @MainActor
    private func recognize(croppedImage: UIImage, rawImage: UIImage) async {
        guard store.session != nil else {
            store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Home.scanAction))
            return
        }

        recognitionPhase = .identifying

        guard let uploadData = croppedImage.jpegDataForUpload() else {
            store.errorMessage = SafeEatL10n.text(L10nKey.Errors.imageCaptureFailed)
            recognitionPhase = nil
            recognizingPreviewImage = nil
            return
        }

        do {
            // 并行：identify API + 本地预览图处理同时进行
            async let identifyTask = store.authorizedRequest { token in
                try await store.api.identify(accessToken: token, imageData: uploadData, fileName: "capture.jpg")
            }
            async let previewTask = BackgroundRemovalService.makePreviewImage(
                from: croppedImage,
                adviceLevel: nil
            )

            let identifyResult = try await identifyTask
            let previewImage = await previewTask

            // 无候选 → 非食物提示
            if identifyResult.candidates.isEmpty {
                recognitionPhase = .nonFood
                recognizingPreviewImage = previewImage
                return
            }

            // 高置信（≥ 0.95）且只有1个候选 → 直接进入智评阶段
            if identifyResult.candidates.count == 1 && identifyResult.candidates[0].confidence >= 0.95 {
                recognitionPhase = .evaluating
                recognizingPreviewImage = previewImage

                do {
                    let record = try await store.authorizedRequest { token in
                        try await store.api.confirm(
                            accessToken: token,
                            selectedName: identifyResult.candidates[0].name,
                            sessionId: identifyResult.sessionId
                        )
                    }
                    let item = try store.recordRecognition(
                        record,
                        originalImage: croppedImage,
                        previewImage: previewImage,
                        rawImage: rawImage,
                        alternateNames: identifyResult.candidates.map { $0.name }
                    )
                    recognitionPhase = nil
                    recognizingPreviewImage = nil
                    selectedTab = .home
                    store.selectedRootTab = .home
                    resultRoute = ResultRoute(id: item.id, itemId: item.id)
                } catch {
                    recognitionPhase = nil
                    recognizingPreviewImage = nil
                    if isQuotaExceededError(error) {
                        showQuotaExceeded = true
                    } else {
                        store.handleAPIError(error)
                    }
                }
            } else {
                // 多候选或低置信 → 进入选择阶段
                identifySession = IdentifySessionData(
                    candidates: identifyResult.candidates,
                    sessionId: identifyResult.sessionId,
                    croppedImage: croppedImage,
                    rawImage: rawImage,
                    previewImage: previewImage
                )
                recognizingPreviewImage = previewImage
                recognitionPhase = .selecting(candidates: identifyResult.candidates, sessionId: identifyResult.sessionId)
            }
        } catch {
            #if DEBUG
            print("[MainTabView] recognize error: \(error)")
            if let apiError = error as? APIError {
                print("[MainTabView] APIError: \(apiError)")
            }
            #endif
            recognitionPhase = nil
            recognizingPreviewImage = nil
            if isQuotaExceededError(error) {
                showQuotaExceeded = true
            } else {
                store.handleAPIError(error)
            }
        }
    }

    // confirm 流程：从候选选择后调用
    @MainActor
    private func performConfirm(selectedName: String, sessionId: String) {
        guard let session = identifySession else { return }

        recognitionPhase = .evaluating
        recognizingPreviewImage = session.previewImage

        Task {
            do {
                let record = try await store.authorizedRequest { token in
                    try await store.api.confirm(
                        accessToken: token,
                        selectedName: selectedName,
                        sessionId: sessionId
                    )
                }
                let item = try store.recordRecognition(
                    record,
                    originalImage: session.croppedImage,
                    previewImage: session.previewImage,
                    rawImage: session.rawImage,
                    alternateNames: session.candidates.map { $0.name }
                )
                identifySession = nil
                recognitionPhase = nil
                recognizingPreviewImage = nil
                selectedTab = .home
                store.selectedRootTab = .home
                resultRoute = ResultRoute(id: item.id, itemId: item.id)
            } catch {
                identifySession = nil
                recognitionPhase = nil
                recognizingPreviewImage = nil
                if isQuotaExceededError(error) {
                    showQuotaExceeded = true
                } else {
                    store.handleAPIError(error)
                }
            }
        }
    }

    private func isQuotaExceededError(_ error: Error) -> Bool {
        guard case let APIError.server(status, message) = error else { return false }
        return status == 400 && message == SafeEatL10n.text(L10nKey.Errors.requestQuotaExceeded)
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
}

private struct ResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// identify 会话数据：候选列表 + sessionId + 原图/预览图
struct IdentifySessionData {
    let candidates: [IdentifyCandidate]
    let sessionId: String
    let croppedImage: UIImage
    let rawImage: UIImage?
    let previewImage: UIImage?
}

#Preview {
    MainTabView()
        .environmentObject(AppStore())
        .environmentObject(AppSettingsStore.shared)
}
