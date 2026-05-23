import StoreKit
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var plans: [MembershipPlan] = []
    @State private var scrollOffset: CGFloat = 0
    @State private var isLoggingOut = false
    @State private var activeSheet: ProfileSheet?
    @State private var didWarmProfileData = false
    @State private var showRedeemCodeSheet = false
    @State private var showHealthGoal = false

    private let scrollCoordinateSpace = "safeeat.profile.scroll"

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                SafeEatMainGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                        Color.clear.frame(height: 8)

                        SafeEatPageHeader(title: SafeEatL10n.text(L10nKey.Profile.title))

                        if store.session == nil {
                            notLoggedInView
                            systemSettingsSection
                            serviceSection
                        } else {
                            heroSection
                            healthProfileSection
                            membershipEntry
                            accountSection
                            systemSettingsSection
                            serviceSection
                            logoutButton
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
                    title: SafeEatL10n.text(L10nKey.Profile.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .reminder:
                    SafeEatReminderSettingsSheet()
                        .presentationDetents([.height(600)])
                case .language:
                    LanguageSettingsView()
                        .presentationDetents([.height(430)])
                }
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(.clear)
        }
        .navigationDestination(for: ProfileRoute.self, destination: destination)
        .sheet(isPresented: $showRedeemCodeSheet) {
            RedeemCodeSheet(store: store)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHealthGoal) {
            HealthGoalSelectionView()
                .presentationDragIndicator(.visible)
        }
        .task {
            await warmProfileDataIfNeeded()
        }
    }

    @ViewBuilder
    private func destination(for route: ProfileRoute) -> some View {
        switch route {
        case .membership:
            MembershipPurchaseView()
        case .orderHistory:
            OrderHistoryView()
        case .editProfile:
            EditProfileView()
        case .preferences:
            PreferenceSettingsView()
        case .security:
            SecuritySettingsView()
        case .cache:
            CacheSettingsView()
        case .feedback:
            FeedbackProblemView()
        case .updates:
            UpdateSettingsView()
        case .about:
            AboutSafeEatView()
        case .changePhone:
            ChangePhoneView()
        case .changePassword:
            ChangePasswordView()
        case .restorePurchases:
            RestorePurchasesView()
        case .deleteAccount:
            DeleteAccountView()
        case .userAgreement:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.userAgreement),
                category: "用户协议"
            )
        case .privacyPolicy:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy),
                category: "隐私政策"
            )
        case .valueAdded:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.valueAdded),
                category: "增值服务协议"
            )
        case .certificate:
            CertificateGalleryView()
        }
    }

    private var heroSection: some View {
        ProfileSurfaceCard {
            HStack(alignment: .center, spacing: 16) {
                ProfileAvatarView(profile: store.profile, size: 86)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(store.profile?.displayNameOrFallback ?? SafeEatL10n.text(L10nKey.Profile.heroDefaultName))
                            .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        HStack(spacing: 8) {
                        Text(PlanTierMapper.shortTitle(store.profile?.currentPlanTier))
                            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(SafeEatTheme.primarySoft)
                            )

                        // 试用状态标签
                        if let status = store.membershipStatus, status.isTrial == true {
                            Text(SafeEatL10n.text(L10nKey.Membership.trialActive))
                                .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                .foregroundStyle(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.orange.opacity(0.14))
                                )
                        }

                        // 首购奖励已领取标签
                        if store.hasFirstPurchaseBonusClaimed {
                            Text(SafeEatL10n.text(L10nKey.Membership.firstPurchaseClaimed))
                                .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(.green.opacity(0.14))
                                )
                        }
                    }
                    }

                    Text(store.profile?.phone ?? "--")
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)

                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 13, weight: .semibold))
                        Text(settings.languageSummary)
                            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                    }
                    .foregroundStyle(SafeEatTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(SafeEatTheme.primary.opacity(0.12))
                    )
                }

                Spacer()
            }
        }
    }

    // MARK: - 健康画像摘要区（参照 html-prototype impact-chip）

    private var healthProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(SafeEatL10n.text(L10nKey.Profile.healthProfileTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                Spacer()
                Button {
                    showHealthGoal = true
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Profile.healthProfileEdit))
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.primary)
                }
            }

            let tags = healthImpactTags
            if tags.isEmpty {
                Text(SafeEatL10n.text(L10nKey.Profile.healthProfileEmpty))
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textPrimary.opacity(0.5))
            } else {
                WrappingHStack(tags: tags, foregroundColor: healthChipForeground, backgroundColor: healthChipBackground, borderColor: healthChipBorder)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SafeEatTheme.primarySoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(SafeEatTheme.line.opacity(0.12), lineWidth: 1)
        )
    }

    private var healthImpactTags: [String] {
        var tags: [String] = []
        if let profile = store.profile {
            if profile.healthTags?.contains("high_blood_sugar") == true {
                tags.append(SafeEatL10n.text(L10nKey.Profile.healthTagHighBloodSugar))
            }
            if profile.healthTags?.contains("high_blood_pressure") == true {
                tags.append(SafeEatL10n.text(L10nKey.Profile.healthTagHighBloodPressure))
            }
            if profile.healthTags?.contains("fat_loss") == true {
                tags.append(SafeEatL10n.text(L10nKey.Profile.healthTagFatLoss))
            }
            if let avoid = profile.avoidIngredients, !avoid.isEmpty {
                tags.append(SafeEatL10n.text(L10nKey.Profile.healthTagAvoid))
            }
        }
        return tags
    }

    private var healthChipForeground: Color {
        colorScheme == .dark ? Color(red: 0.85, green: 0.72, blue: 0.55) : Color(red: 0.55, green: 0.40, blue: 0.15)
    }

    private var healthChipBackground: Color {
        colorScheme == .dark ? Color(red: 0.22, green: 0.18, blue: 0.14) : Color(red: 1.0, green: 0.96, blue: 0.90)
    }

    private var healthChipBorder: Color {
        colorScheme == .dark ? Color(red: 0.42, green: 0.35, blue: 0.25) : Color(red: 0.92, green: 0.84, blue: 0.72)
    }

    private var membershipEntry: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.memberEntryTitle)) {
            NavigationLink(value: ProfileRoute.membership) {
                if let highlightedPlan = highlightedPlan {
                    ProfileNavigationRow(
                        icon: "crown.fill",
                        title: highlightedPlan.localizedDisplayName,
                        subtitle: SafeEatL10n.format(
                            L10nKey.Profile.memberEntryFormat,
                            SafeEatTheme.priceText(highlightedPlan.priceFen),
                            highlightedPlan.localizedDisplayName
                        )
                    )
                } else {
                    ProfileNavigationRow(
                        icon: "crown.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.memberEntryTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.memberEntrySubtitle)
                    )
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 账号与偏好（含兑换码、订单历史）

    private var accountSection: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.editGroupTitle)) {
            NavigationLink(value: ProfileRoute.editProfile) {
                ProfileNavigationRow(
                    icon: "person.crop.circle.badge.plus",
                    title: SafeEatL10n.text(L10nKey.Profile.editTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.editSubtitle),
                    trailingText: store.profile == nil ? nil : "\(SafeEatL10n.text(L10nKey.Profile.bmiLabel)) \(bmiText)"
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink(value: ProfileRoute.preferences) {
                ProfileNavigationRow(
                    icon: "slider.horizontal.3",
                    title: SafeEatL10n.text(L10nKey.Profile.preferenceTitle),
                    subtitle: preferenceSummary
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            if store.session != nil {
                NavigationLink(value: ProfileRoute.security) {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: SafeEatL10n.text(L10nKey.Profile.securityTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.securitySubtitle)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Profile.securityTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: SafeEatL10n.text(L10nKey.Profile.securityTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.securitySubtitle)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(SafeEatTheme.line)

            NavigationLink(value: ProfileRoute.orderHistory) {
                ProfileNavigationRow(
                    icon: "receipt",
                    title: SafeEatL10n.text(L10nKey.Order.title),
                    subtitle: SafeEatL10n.text(L10nKey.Order.subtitle)
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            Button {
                showRedeemCodeSheet = true
            } label: {
                ProfileNavigationRow(
                    icon: "ticket",
                    title: SafeEatL10n.text(L10nKey.Membership.redeemCodeEntryTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Membership.redeemCodeEntrySubtitle)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var systemSettingsSection: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.systemSectionTitle)) {
            Button {
                activeSheet = .reminder
            } label: {
                ProfileNavigationRow(
                    icon: "bell.badge",
                    title: SafeEatL10n.text(L10nKey.Profile.reminderTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Reminder.entrySubtitle),
                    trailingText: settings.reminderSummary
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            Button {
                activeSheet = .language
            } label: {
                ProfileNavigationRow(
                    icon: "globe",
                    title: SafeEatL10n.text(L10nKey.Profile.languageTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.languageSubtitle),
                    trailingText: settings.languageSummary
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink(value: ProfileRoute.cache) {
                ProfileNavigationRow(
                    icon: "internaldrive",
                    title: SafeEatL10n.text(L10nKey.Profile.cacheTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.cacheSubtitle),
                    trailingText: store.localCacheSizeText
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink(value: ProfileRoute.feedback) {
                ProfileNavigationRow(
                    icon: "exclamationmark.bubble",
                    title: SafeEatL10n.text(L10nKey.Profile.feedbackTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.feedbackSubtitle)
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink(value: ProfileRoute.updates) {
                ProfileNavigationRow(
                    icon: "arrow.triangle.2.circlepath.circle",
                    title: SafeEatL10n.text(L10nKey.Profile.updatesTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.updatesSubtitle)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var serviceSection: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.serviceGroupTitle)) {
            NavigationLink(value: ProfileRoute.about) {
                ProfileNavigationRow(
                    icon: "leaf.circle",
                    title: SafeEatL10n.text(L10nKey.Profile.aboutTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.aboutSubtitle)
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            Button {
                requestAppReview()
            } label: {
                ProfileNavigationRow(
                    icon: "star.bubble",
                    title: SafeEatL10n.text(L10nKey.Profile.rateTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.rateSubtitle)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            // 头像区域：点击触发登录
            Button {
                store.goToLogin()
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(SafeEatTheme.primarySoft)
                            .frame(width: 86, height: 86)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(SafeEatTheme.primary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(SafeEatL10n.text(L10nKey.Profile.notLoggedInTitle))
                            .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)

                        Text(SafeEatL10n.text(L10nKey.Profile.notLoggedInMessage))
                            .font(SafeEatFont.custom(14, relativeTo: .body))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // 需要登录的功能入口
            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.memberEntryTitle)) {
                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Profile.memberEntryTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "crown.fill",
                        title: SafeEatL10n.text(L10nKey.Profile.memberEntryTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.memberEntrySubtitle)
                    )
                }
                .buttonStyle(.plain)
            }

            ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.editGroupTitle)) {
                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Profile.editTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "person.crop.circle.badge.plus",
                        title: SafeEatL10n.text(L10nKey.Profile.editTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.editSubtitle)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Profile.preferenceTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "slider.horizontal.3",
                        title: SafeEatL10n.text(L10nKey.Profile.preferenceTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.preferenceSubtitleDefault)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Profile.securityTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: SafeEatL10n.text(L10nKey.Profile.securityTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.securitySubtitle)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Order.title))
                } label: {
                    ProfileNavigationRow(
                        icon: "receipt",
                        title: SafeEatL10n.text(L10nKey.Order.title),
                        subtitle: SafeEatL10n.text(L10nKey.Order.subtitle)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)

                Button {
                    store.requireLogin(featureHint: SafeEatL10n.text(L10nKey.Membership.redeemCodeEntryTitle))
                } label: {
                    ProfileNavigationRow(
                        icon: "ticket",
                        title: SafeEatL10n.text(L10nKey.Membership.redeemCodeEntryTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Membership.redeemCodeEntrySubtitle)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var logoutButton: some View {
        Button {
            Task {
                isLoggingOut = true
                await store.performLogout()
                isLoggingOut = false
            }
        } label: {
            Group {
                if isLoggingOut {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(SafeEatL10n.text(L10nKey.Profile.logout))
                        .frame(maxWidth: .infinity)
                }
            }
            .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
            .foregroundStyle(SafeEatTheme.danger)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(SafeEatTheme.danger.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoggingOut)
    }

    private var highlightedPlan: MembershipPlan? {
        plans
            .filter { $0.tier != "free" }
            .min(by: { $0.priceFen < $1.priceFen })
    }

    private var bmiText: String {
        if let bmi = store.profile?.bmi {
            return String(format: "%.1f", bmi)
        }
        return "--"
    }

    private var preferenceSummary: String {
        var pieces: [String] = []
        if let healthTags = store.profile?.healthTags, !healthTags.isEmpty {
            let separator = settings.language == .en ? ", " : "、"
            pieces.append(healthTags.prefix(2).map { HealthTagMapper.title($0) }.joined(separator: separator))
        }
        if let fitnessGoal = store.profile?.fitnessGoal {
            pieces.append(FitnessGoalMapper.title(fitnessGoal))
        }
        return pieces.isEmpty ? SafeEatL10n.text(L10nKey.Profile.preferenceSubtitleDefault) : pieces.joined(separator: " · ")
    }

    private func warmProfileDataIfNeeded() async {
        guard !didWarmProfileData else { return }
        didWarmProfileData = true

        await settings.refreshNotificationStatus()

        guard store.session != nil else { return }
        await store.refreshProfile()
        await loadPlansIfNeeded()
    }

    private func loadPlansIfNeeded() async {
        guard plans.isEmpty else { return }

        do {
            let result = try await store.api.getPlans()
            plans = result.items
        } catch {
            store.handleAPIError(error)
        }
    }

    private func requestAppReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}

enum ProfileRoute: Hashable {
    case membership
    case orderHistory
    case editProfile
    case preferences
    case security
    case cache
    case feedback
    case updates
    case about
    case changePhone
    case changePassword
    case restorePurchases
    case deleteAccount
    case userAgreement
    case privacyPolicy
    case valueAdded
    case certificate
}

private enum ProfileSheet: String, Identifiable {
    case reminder
    case language

    var id: String { rawValue }
}

private struct WrappingHStack: View {
    let tags: [String]
    let foregroundColor: Color
    let backgroundColor: Color
    let borderColor: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(SafeEatFont.custom(12, relativeTo: .caption))
                    .foregroundStyle(foregroundColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(backgroundColor)
                    )
                    .overlay(
                        Capsule()
                            .stroke(borderColor, lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppStore())
            .environmentObject(AppSettingsStore.shared)
    }
}
