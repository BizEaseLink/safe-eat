import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AdRewardResultType {
    case claimFailed
    case loadFailed
    case success(rewardQuota: Int)
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

struct ScanHomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    private var adConfig: AdConfigStore { AdConfigStore.shared }
    @Environment(\.colorScheme) private var colorScheme

    @State private var showCamera = false
    @State private var isRecognizing = false
    @State private var resultRoute: ResultRoute?
    @State private var scrollOffset: CGFloat = 0
    @State private var recognizingPreviewImage: UIImage?
    @State private var showMembership = false
    @State private var showQuotaExceeded = false
    @State private var showAdRewardResult = false
    @State private var adRewardResultType: AdRewardResultType = .claimFailed
    @State private var showSignupBonus = false

    let scrollCoordinateSpace = "safeeat.home.scroll"

    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    private var latestRecord: LocalHistoryItem? {
        store.localHistory.first
    }

    private var isFreeQuotaExceeded: Bool {
        guard store.profile?.currentPlanTier == nil || store.profile?.currentPlanTier == "free" else { return false }
        // dailyQuota 为 nil 时（未登录或未获取到远程数据），不判定为已用完
        guard let quota = store.dailyQuota else { return false }
        return quota.remainingQuota <= 0
    }

    private var remainingFreeQuota: Int {
        guard store.profile?.currentPlanTier == nil || store.profile?.currentPlanTier == "free" else { return -1 }
        // dailyQuota 为 nil 时返回 -1，表示数据未就绪，不显示剩余次数
        guard store.dailyQuota != nil else { return -1 }
        return store.dailyQuota?.remainingQuota ?? 0
    }

    private var brandLabelColor: Color {
        colorScheme == .dark ? Color(red: 0.67, green: 0.86, blue: 0.73) : SafeEatTheme.primaryDeep
    }

    private var secondaryButtonTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : SafeEatTheme.primaryDeep
    }

    private var heroPillFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.975, green: 0.982, blue: 0.975).opacity(0.96)
    }

    private var heroPillStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.84, green: 0.90, blue: 0.86).opacity(0.94)
    }

    // privilege-bar 样式（参照原型 CSS .privilege-bar）
    private var privilegeBarForeground: Color {
        colorScheme == .dark
            ? Color(red: 0.95, green: 0.84, blue: 0.67)
            : Color(red: 0.54, green: 0.39, blue: 0.20)
    }

    private var privilegeBarFill: some ShapeStyle {
        LinearGradient(
            stops: [
                .init(color: Color(red: 1.0, green: 0.96, blue: 0.90).opacity(colorScheme == .dark ? 0.20 : 0.96), location: 0),
                .init(color: Color(red: 0.98, green: 0.93, blue: 0.84).opacity(colorScheme == .dark ? 0.16 : 0.92), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var privilegeBarStroke: Color {
        colorScheme == .dark
            ? Color(red: 0.48, green: 0.40, blue: 0.29).opacity(0.30)
            : Color(red: 0.89, green: 0.74, blue: 0.54).opacity(0.24)
    }

    private var privilegeBarShadow: Color {
        colorScheme == .dark
            ? Color(red: 0.65, green: 0.50, blue: 0.25).opacity(0.06)
            : Color(red: 0.65, green: 0.50, blue: 0.25).opacity(0.08)
    }

    private var isLoggedIn: Bool {
        guard store.hasBootstrapped else { return true }
        return store.session != nil
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                homeBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                        homeHeaderBar

                        heroSection

                        if isLoggedIn {
                            recentRecordSection
                        }

                        if !isPaidMember && adConfig.bannerEnabled {
                            BannerAdView()
                                .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 50, maxHeight: 50)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 44)
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .onPreferenceChange(SafeEatScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                SafeEatScrollNavChrome(
                    title: SafeEatL10n.text(L10nKey.Home.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top
                )

                if isRecognizing {
                    SafeEatLoadingOverlay(
                        title: SafeEatL10n.text(L10nKey.Home.loadingTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Home.loadingSubtitle),
                        previewImage: recognizingPreviewImage
                    )
                    .transition(.opacity)
                    .zIndex(30)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
        .navigationDestination(item: $resultRoute) { route in
            ResultView(itemId: route.itemId)
        }
        .navigationDestination(isPresented: $showMembership) {
            MembershipPurchaseView()
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

    private var homeBackground: some View {
        SafeEatMainGradientBackground()
    }

    private var homeHeaderBar: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(SafeEatL10n.text(L10nKey.Home.title))
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Spacer()

            Button {
                guard isLoggedIn else {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Home.memberAction))
                    return
                }
                showMembership = true
            } label: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(SafeEatL10n.text(L10nKey.Home.promoTag))
                        .font(SafeEatFont.custom(11, relativeTo: .caption))
                    Text(SafeEatL10n.text(L10nKey.Home.promoValue))
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                }
                .foregroundStyle(privilegeBarForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(privilegeBarFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(privilegeBarStroke, lineWidth: 1)
                )
                .shadow(color: privilegeBarShadow, radius: 8, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                heroPill(SafeEatL10n.text(L10nKey.Home.heroTagHealth))
                heroPill(SafeEatL10n.text(L10nKey.Home.heroTagHistory))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(SafeEatL10n.text(L10nKey.Home.heroTitle))
                    .font(SafeEatFont.custom(36, relativeTo: .largeTitle))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button {
                    startScan()
                } label: {
                    Group {
                        if isRecognizing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(SafeEatL10n.text(L10nKey.Home.scanAction))
                                .font(SafeEatFont.custom(21, relativeTo: .headline))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: SafeEatTheme.primaryDeep.opacity(0.18), radius: 16, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(isRecognizing)

                Button {
                    guard isLoggedIn else {
                        store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Home.memberAction))
                        return
                    }
                    showMembership = true
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Home.memberAction))
                        .font(SafeEatFont.custom(21, relativeTo: .headline))
                        .foregroundStyle(secondaryButtonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            if let snapshot = store.dailyQuota {
                QuotaStatusBar(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var recentRecordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(SafeEatL10n.text(L10nKey.Home.recentTitle))
                    .font(SafeEatFont.textStyle(.headline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                LinearGradient(
                    colors: [
                        SafeEatTheme.textPrimary.opacity(colorScheme == .dark ? 0.16 : 0.12),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }

            if let latestRecord {
                HomeRecentRecordCard(
                    item: latestRecord,
                    onOpenDetail: {
                        resultRoute = ResultRoute(id: latestRecord.id, itemId: latestRecord.id)
                    }
                )
            } else {
                SafeEatSurfaceCard(
                    padding: EdgeInsets(top: 22, leading: 22, bottom: 22, trailing: 22)
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(SafeEatL10n.text(L10nKey.Home.emptyTitle))
                            .font(SafeEatFont.textStyle(.headline))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                        Text(SafeEatL10n.text(L10nKey.Home.emptyMessage))
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func heroPill(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.custom(15, relativeTo: .subheadline))
            .foregroundStyle(brandLabelColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(heroPillFill)
            )
            .overlay(
                Capsule()
                    .stroke(heroPillStroke, lineWidth: 1)
            )
    }

    private func startScan() {
        guard !isRecognizing else { return }

        // 未登录时弹出登录引导
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
        // 后端额度耗尽返回 400 + 特定消息
        // localizedMessage 已将原始消息转为本地化文本，这里匹配本地化后的文本
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
                // 看完广告，先向后端领取奖励，再刷新额度
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

private struct HomeRecentRecordCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: LocalHistoryItem
    let onOpenDetail: () -> Void

    private var statusColor: Color {
        AdviceLevelMapper.color(item.adviceLevel)
    }

    private var nutritionPrimaryColor: Color {
        colorScheme == .dark ? Color(red: 0.85, green: 0.93, blue: 0.88) : SafeEatTheme.primaryDeep
    }

    private var impactItems: [HealthImpact] {
        Array((item.cachedRecognition?.healthImpacts ?? []).prefix(2))
    }

    private var summaryChips: [(String, Color)] {
        if !impactItems.isEmpty {
            return impactItems.map { impact in
                (impact.label, chipColor(level: impact.level))
            }
        }

        if let nutrition = item.cachedRecognition?.effectiveNutrition {
            let nutrients = nutrition.nutrients
            var chips: [(String, Color)] = []
            if let calories = nutrients?.calories.value {
                chips.append((SafeEatL10n.format(L10nKey.Home.caloriesFormat, Int(calories)), nutritionPrimaryColor))
            }
            if let protein = nutrients?.protein.value {
                chips.append((SafeEatL10n.format(L10nKey.Home.proteinFormat, protein), SafeEatTheme.success))
            }
            if let carbs = nutrients?.carbohydrates.value, chips.count < 2 {
                chips.append((SafeEatL10n.format(L10nKey.Home.carbsFormat, carbs), SafeEatTheme.warning))
            }
            if !chips.isEmpty {
                return Array(chips.prefix(2))
            }
        }

        switch item.adviceLevel {
        case "recommended":
            return [(SafeEatL10n.text(L10nKey.Home.chipFriendly), SafeEatTheme.success)]
        case "caution":
            return [(SafeEatL10n.text(L10nKey.Home.chipPortion), SafeEatTheme.warning)]
        case "avoid":
            return [(SafeEatL10n.text(L10nKey.Home.chipSwitch), SafeEatTheme.danger)]
        default:
            return [(SafeEatL10n.text(L10nKey.Home.chipCheck), SafeEatTheme.textSecondary)]
        }
    }

    private var displayName: String {
        let trimmed = item.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let unknownFoodNames = ["未知食物", "Unrecognized food", SafeEatL10n.text(L10nKey.Common.unknownFood)]
        if trimmed.isEmpty || unknownFoodNames.contains(trimmed) {
            return SafeEatL10n.text(L10nKey.Home.unknownFood)
        }
        return trimmed
    }

    private var summaryText: String {
        if let advice = item.cachedRecognition?.adviceText,
           !advice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return advice
        }

        switch item.adviceLevel {
        case "recommended":
            return SafeEatL10n.text(L10nKey.Home.summaryRecommended)
        case "caution":
            return SafeEatL10n.text(L10nKey.Home.summaryCaution)
        case "avoid":
            return SafeEatL10n.text(L10nKey.Home.summaryAvoid)
        default:
            return SafeEatL10n.text(L10nKey.Home.summaryUnknown)
        }
    }

    var body: some View {
        SafeEatSurfaceCard(onTap: onOpenDetail) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    imagePreview

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(displayName)
                                    .font(SafeEatFont.custom(28, relativeTo: .title2))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                                    .lineLimit(2)

                                Text(
                                    SafeEatL10n.format(
                                        L10nKey.Home.localImageFormat,
                                        SafeEatL10n.text(L10nKey.Home.localImagePrefix),
                                        item.createdAt.homeTimeText
                                    )
                                )
                                    .font(SafeEatFont.custom(15, relativeTo: .body))
                                    .foregroundStyle(SafeEatTheme.textSecondary)
                            }

                            Spacer(minLength: 8)

                            Text(AdviceLevelMapper.title(item.adviceLevel))
                                .font(SafeEatFont.custom(13, relativeTo: .subheadline))
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(statusColor.opacity(0.14))
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 8) {
                            Text(SafeEatL10n.format(L10nKey.Home.scoreFormat, item.foodScore))
                                .font(SafeEatFont.custom(14, relativeTo: .footnote))
                                .foregroundStyle(SafeEatTheme.warning)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(SafeEatTheme.warning.opacity(0.12))
                                .clipShape(Capsule())

                            ForEach(Array(summaryChips.prefix(1).enumerated()), id: \.offset) { _, chip in
                                Text(chip.0)
                                    .font(SafeEatFont.custom(14, relativeTo: .footnote))
                                    .foregroundStyle(chip.1)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(chip.1.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(summaryText)
                            .font(SafeEatFont.custom(14, relativeTo: .body))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .lineLimit(2)
                    }
                }

                Button(action: onOpenDetail) {
                    Text(SafeEatL10n.text(L10nKey.Home.detailAction))
                        .font(SafeEatFont.custom(20, relativeTo: .headline))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.16), radius: 16, y: 10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = LocalImageLoader.loadStickerImage(for: item)
            ?? LocalImageLoader.loadDisplayImage(for: item) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.34))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.45), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.34))
                .frame(width: 84, height: 84)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
        }
    }

    private func chipColor(level: String) -> Color {
        switch level {
        case "positive":
            return SafeEatTheme.success
        case "risk":
            return SafeEatTheme.danger
        case "caution":
            return SafeEatTheme.warning
        default:
            return SafeEatTheme.textSecondary
        }
    }
}

private extension Date {
    var homeTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

#Preview {
    NavigationStack {
        ScanHomeView()
            .environmentObject(AppStore())
    }
}
