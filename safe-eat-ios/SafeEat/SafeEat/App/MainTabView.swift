import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @State private var showCamera = false
    @State private var showMembership = false
    @State private var showQuotaExceeded = false
    @State private var isRecognizing = false
    @State private var recognizingPreviewImage: UIImage?
    @State private var resultRoute: ResultRoute?
    @State private var showAdRewardResult = false
    @State private var adRewardResultType: AdRewardResultType = .claimFailed
    @State private var showSignupBonus = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var scanPressed = false

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

    var body: some View {
        ZStack(alignment: .bottom) {
            // 内容区域
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
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
                    NavigationStack {
                        MenuWeekView()
                    }

                case .trend:
                    NavigationStack {
                        TrendPlaceholderView()
                    }

                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }

            // 识别中加载遮罩
            if isRecognizing {
                SafeEatLoadingOverlay(
                    title: SafeEatL10n.text(L10nKey.Home.loadingTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Home.loadingSubtitle),
                    previewImage: recognizingPreviewImage
                )
                .transition(.opacity)
                .zIndex(30)
            }

            // 底部浮动导航区域
            floatingBottomBar
        }
        .toolbar(.hidden, for: .tabBar)
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
                onUpgrade: { showMembership = true },
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
    }

    // MARK: - 浮动底部导航栏

    private var floatingBottomBar: some View {
        // 整体胶囊居中，拍摄按钮在胶囊内最右侧
        HStack(spacing: 4) {
            tabBarItem(tab: .home, icon: "house.fill", label: SafeEatL10n.text(L10nKey.Tab.home))
            tabBarItem(tab: .history, icon: "book.closed.fill", label: SafeEatL10n.text(L10nKey.Tab.menu))
            tabBarItem(tab: .trend, icon: "chart.line.uptrend.xyaxis", label: SafeEatL10n.text(L10nKey.Tab.trend))
            tabBarItem(tab: .profile, icon: "person.fill", label: SafeEatL10n.text(L10nKey.Tab.profile))

            // 拍摄按钮（圆形，与胶囊一体化）
            Button {
                scanPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    scanPressed = false
                }
                startScan()
            } label: {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(scanPressed ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(scanPressed ? SafeEatTheme.primary.opacity(0.12) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
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
        guard !isRecognizing else { return }

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

        isRecognizing = true
        defer {
            isRecognizing = false
            recognizingPreviewImage = nil
        }

        guard let uploadData = croppedImage.jpegDataForUpload() else {
            store.errorMessage = SafeEatL10n.text(L10nKey.Errors.imageCaptureFailed)
            return
        }

        do {
            let created = try await store.authorizedRequest { token in
                try await store.api.createRecognition(
                    accessToken: token,
                    imageData: uploadData,
                    fileName: "capture.jpg"
                )
            }
            let detailed = try await store.authorizedRequest { token in
                try await store.api.getRecognition(accessToken: token, recognitionId: created.id)
            }
            let previewImage = await BackgroundRemovalService.makePreviewImage(
                from: croppedImage,
                adviceLevel: detailed.adviceLevel
            )
            let item = try store.recordRecognition(
                detailed,
                originalImage: croppedImage,
                previewImage: previewImage,
                rawImage: rawImage
            )

            // 识别成功后切换到首页 Tab 并导航到结果页
            selectedTab = .home
            store.selectedRootTab = .home
            resultRoute = ResultRoute(id: item.id, itemId: item.id)
        } catch {
            if isQuotaExceededError(error) {
                showQuotaExceeded = true
            } else {
                store.handleAPIError(error)
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
                        adRewardResultType = .success(rewardQuota: store.dailyQuota?.adRewardPerWatch ?? adConfig.placement(for: .rewardVideo)?.rewardQuota ?? 1)
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

#Preview {
    MainTabView()
        .environmentObject(AppStore())
        .environmentObject(AppSettingsStore.shared)
}
