import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ScanHomeView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    private var adConfig: AdConfigStore { AdConfigStore.shared }
    @Environment(\.colorScheme) private var colorScheme

    @State private var scrollOffset: CGFloat = 0
    @Binding var showNotificationCenter: Bool

    var onShowMembership: (() -> Void)?
    var onOpenResult: ((String) -> Void)?

    let scrollCoordinateSpace = "safeeat.home.scroll"

    private var isPaidMember: Bool {
        guard let tier = store.profile?.currentPlanTier else { return false }
        return tier != "free"
    }

    private var latestRecord: LocalHistoryItem? {
        store.localHistory.first
    }

    private var brandLabelColor: Color {
        colorScheme == .dark ? Color(red: 0.67, green: 0.86, blue: 0.73) : SafeEatTheme.primaryDeep
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

    // privilege-bar 样式
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
                    .padding(.bottom, 120)
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
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showNotificationCenter) {
            MessageCenterView()
        }
        .task {
            await store.refreshDailyQuota()
        }
    }

    private func showMembership() {
        onShowMembership?()
    }

    private var homeBackground: some View {
        SafeEatMainGradientBackground()
    }

    private var homeHeaderBar: some View {
        HStack(alignment: .center, spacing: 8) {
            // 左侧空白占位
            Color.clear.frame(width: 1)

            Spacer()

            // 促销标签（v1.1.0 启用）
            // promoTagButton

            // 消息按钮
            Button {
                if store.session != nil {
                    showNotificationCenter = true
                } else {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Message.centerTitle))
                }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        )
                        .overlay(
                            Circle()
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                        )

                    // 未读小圆点
                    if store.notificationUnreadCount > 0 {
                        Circle()
                            .fill(SafeEatTheme.danger)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: 2)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                heroPill(SafeEatL10n.text(L10nKey.Home.heroTagHistory))
                heroPill(SafeEatL10n.text(L10nKey.Home.heroTagHealth))
                heroPill(SafeEatL10n.text(L10nKey.Home.heroTagKnow))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(SafeEatL10n.text(L10nKey.Home.heroTitle))
                    .font(SafeEatFont.custom(36, relativeTo: .largeTitle))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isLoggedIn, let snapshot = store.dailyQuota {
                QuotaStatusBar(snapshot: snapshot, onShowMembership: { showMembership() })
            }
        }
    }

    @ViewBuilder
    private var recentRecordSection: some View {
        if let latestRecord {
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

                HomeRecentRecordCard(
                    item: latestRecord,
                    onOpenDetail: {
                        onOpenResult?(latestRecord.id)
                    }
                )
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
        case "moderate":
            return [(SafeEatL10n.text(L10nKey.Home.chipModerate), SafeEatTheme.primary)]
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
        case "moderate":
            return SafeEatL10n.text(L10nKey.Home.summaryModerate)
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
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(chip.1.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
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
        ScanHomeView(showNotificationCenter: .constant(false))
            .environmentObject(AppStore())
    }
}
