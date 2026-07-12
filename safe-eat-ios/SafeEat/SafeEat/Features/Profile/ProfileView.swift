import StoreKit
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var scrollOffset: CGFloat = 0
    @State private var isLoggingOut = false
    @State private var activeSheet: ProfileSheet?
    @State private var didWarmProfileData = false
    @State private var showRedeemCodeSheet = false
    /// T10：onAppear 防抖时间戳（5s 内不重复刷新）
    @State private var lastRefreshAt: Date?

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
                            footerLegalSection
                        } else {
                            heroSection
//                            healthProfileSection
                            membershipEntry
                            accountSection
                            systemSettingsSection
                            serviceSection
                            logoutButton
                            footerLegalSection
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
                // T10：下拉刷新
                .refreshable {
                    await store.refreshProfile()
                    await store.loadMembershipStatus()
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
            switch sheet {
            case .reminder:
                SafeEatReminderSettingsSheet()
            case .language:
                LanguageSettingsView()
            }
        }
        .navigationDestination(for: ProfileRoute.self, destination: destination)
        .sheet(isPresented: $showRedeemCodeSheet) {
            RedeemCodeSheet()
        }
        .task {
            await warmProfileDataIfNeeded()
        }
        // T10：每次进个人页防抖刷新 membershipStatus（5s 内不重复刷）
        .onAppear {
            Task { await refreshMembershipIfStale() }
        }
        // T10：购买完成通知触发强制刷新（跳过防抖）
        .onReceive(NotificationCenter.default.publisher(for: .membershipPurchaseDidComplete)) { _ in
            Task {
                await store.refreshProfile()
                await store.loadMembershipStatus()
                lastRefreshAt = Date()
            }
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
        case .healthGoal:
            HealthGoalSelectionView()
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
            ResetPasswordView(phoneMode: .fixed)
        case .restorePurchases:
            RestorePurchasesView()
        case .deleteAccount:
            DeleteAccountView()
        case .userAgreement:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.userAgreement),
                category: "user_agreement"
            )
        case .privacyPolicy:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy),
                category: "privacy_policy"
            )
        case .valueAdded:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.valueAdded),
                category: "value_added_service_agreement"
            )
        case .minorProtection:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.minorProtection),
                category: "minor_protection_guide"
            )
        case .autoRenewalNotice:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.autoRenewalNotice),
                category: "auto_renewal_notice"
            )
        case .permissionUsage:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.permissionUsage),
                category: "permission_usage"
            )
        case .aiDisclaimer:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.aiDisclaimer),
                category: "ai_disclaimer"
            )
        case .adServiceNotice:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.adServiceNotice),
                category: "ad_service_notice"
            )
        case .cancellationGuide:
            DisclosureDetailView(
                title: SafeEatL10n.text(L10nKey.Profile.About.cancellationGuide),
                category: "account_cancellation_guide"
            )
        case .certificate:
            CertificateGalleryView()
        case .helpCenter:
            HelpCenterView()
        }
    }

    private var heroSection: some View {
        NavigationLink(value: ProfileRoute.editProfile) {
            ProfileSurfaceCard {
                HStack(alignment: .center, spacing: 16) {
                    ProfileAvatarView(profile: store.profile, size: 86)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(store.profile?.displayNameOrFallback ?? SafeEatL10n.text(L10nKey.Profile.heroDefaultName))
                                .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)
                                .lineLimit(1)

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

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 健康画像摘要区（扁平极简图标+文字标签）

    private var healthProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(SafeEatL10n.text(L10nKey.Profile.healthProfileTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                Spacer()
                NavigationLink(value: ProfileRoute.healthGoal) {
                    Text(SafeEatL10n.text(L10nKey.Profile.healthProfileEdit))
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.primary)
                }
            }

            let selectedTags = healthSelectedTags
            if selectedTags.isEmpty {
                Text(SafeEatL10n.text(L10nKey.Profile.healthProfileEmptyHint))
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(selectedTags, id: \.code) { tag in
                        healthTagChip(tag)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line.opacity(0.12), lineWidth: 1)
        )
    }

    private func healthTagChip(_ tag: HealthTagDisplay) -> some View {
        let bgColor = tag.color.opacity(0.10)
        return HStack(spacing: 6) {
            Image(systemName: tag.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tag.color)
            Text(tag.displayName)
                .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .semibold))
                .foregroundStyle(tag.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(bgColor)
        )
    }

    /// 根据用户已选 healthTags 从模板匹配出显示用的标签，最多3个
    private var healthSelectedTags: [HealthTagDisplay] {
        guard let codes = store.profile?.healthTags, !codes.isEmpty else { return [] }
        return codes.prefix(3).compactMap { code in
            guard let template = HealthProfileTemplateMock.templates.first(where: { $0.code == code }) else { return nil }
            guard let config = HealthTagConfig.forCode(code) else { return nil }
            return HealthTagDisplay(code: code, displayName: template.displayName, icon: config.icon, color: config.color)
        }
    }

    // MARK: - 会员入口（扁平极简等级卡片，4 种背景色）

    private var membershipEntry: some View {
        VStack(spacing: 10) {
            NavigationLink(value: ProfileRoute.membership) {
                let tier = PlanTierMapper.map(store.profile?.currentPlanTier)
                MembershipTierCard(tier: tier)
            }
            .buttonStyle(.plain)

            // T7：取消订阅过期提醒（两段式，方案 B）
            cancelledRenewalReminders

            // T12：跳转系统订阅管理页（仅付费会员显示）
            if store.membershipStatus?.active == true {
                manageSubscriptionsLink
            }
        }
    }

    /// T12：跳转 Apple 系统订阅管理页
    /// 用 itms-apps 协议跳 App Store 订阅页，兼容性好，不依赖 UIWindowScene
    private var manageSubscriptionsLink: some View {
        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
            HStack(spacing: 8) {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 14))
                    .foregroundStyle(SafeEatTheme.primary)
                Text("管理订阅")
                    .font(SafeEatFont.custom(13, relativeTo: .footnote))
                    .foregroundStyle(SafeEatTheme.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SafeEatTheme.primary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }

    /// T7：根据 autoRenew + endsAt 渲染两段式提醒
    /// - 常驻轻提示：autoRenew == false 即显示
    /// - 紧迫提醒：autoRenew == false && daysLeft <= 7 叠加显示
    @ViewBuilder
    private var cancelledRenewalReminders: some View {
        if let status = store.membershipStatus,
           status.active == true,
           status.autoRenew == false,
           let endsAt = status.endsAt,
           endsAt > Date() {
            // daysLeft 按自然天计算（截断到日，防时区/夏令时，R-12）
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: endsAt).day ?? 0

            CancelledRenewalBanner(endsAt: endsAt)

            if daysLeft <= 7 {
                ExpiryUrgentReminderView(endsAt: endsAt)
            }
        }
    }

    // MARK: - 账号与安全（含兑换码、订单历史）

    private var accountSection: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.editGroupTitle)) {
            if store.session != nil {
                NavigationLink(value: ProfileRoute.security) {
                    ProfileNavigationRow(
                        icon: "lock.shield",
                        title: SafeEatL10n.text(L10nKey.Profile.securityTitle),
                        subtitle: SafeEatL10n.text(L10nKey.Profile.securitySubtitle)
                    )
                }
                .buttonStyle(.plain)

                Divider().overlay(SafeEatTheme.line)
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

            NavigationLink(value: ProfileRoute.helpCenter) {
                ProfileNavigationRow(
                    icon: "questionmark.circle",
                    title: SafeEatL10n.text(L10nKey.Profile.Help.title),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.Help.subtitle)
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

    /// 个人页底部法律信息区：用户协议 ｜ 隐私政策 + ICP 备案号
    /// 未登录和已登录状态都显示
    private var footerLegalSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                NavigationLink(value: ProfileRoute.userAgreement) {
                    Text(SafeEatL10n.text(L10nKey.Profile.About.userAgreement))
                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
                }
                .buttonStyle(.plain)

                Text("｜")
                    .font(SafeEatFont.custom(11, relativeTo: .caption2))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))

                NavigationLink(value: ProfileRoute.privacyPolicy) {
                    Text(SafeEatL10n.text(L10nKey.Profile.About.privacyPolicy))
                        .font(SafeEatFont.custom(11, relativeTo: .caption2))
                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            // ICP 备案号：中文政务信息，中英文语言下都显示中文原文，不做本地化翻译
            Text(SafeEatL10n.text(L10nKey.Profile.About.icpRecord))
                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 24)
        .padding(.bottom, 16)
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

    private func warmProfileDataIfNeeded() async {
        guard !didWarmProfileData else { return }
        didWarmProfileData = true

        await settings.refreshNotificationStatus()

        guard store.session != nil else { return }
        await store.refreshProfile()
        await store.loadMembershipStatus()
        lastRefreshAt = Date()
    }

    /// T10：进个人页防抖刷新（5s 内不重复刷）
    /// 仅刷新 membershipStatus（轻量），profile 由 warmProfileDataIfNeeded 首次预热
    private func refreshMembershipIfStale() async {
        let now = Date()
        if let last = lastRefreshAt, now.timeIntervalSince(last) < 5 {
            return  // 5s 内已刷过，跳过
        }
        lastRefreshAt = now
        await store.loadMembershipStatus()
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
    case healthGoal
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
    case minorProtection
    case autoRenewalNotice
    case permissionUsage
    case aiDisclaimer
    case adServiceNotice
    case cancellationGuide
    case certificate
    case helpCenter
}

private enum ProfileSheet: String, Identifiable {
    case reminder
    case language

    var id: String { rawValue }
}

// MARK: - 健康标签显示模型

private struct HealthTagDisplay {
    let code: String
    let displayName: String
    let icon: String
    let color: Color
}

// MARK: - 健康标签图标与颜色映射

enum HealthTagConfig {
    case high_blood_pressure
    case high_blood_sugar
    case high_blood_lipids
    case general_wellness
    case fat_loss
    case muscle_gain
    case blood_sugar_control
    case balanced

    var icon: String {
        switch self {
        case .high_blood_pressure: return "heart.fill"
        case .high_blood_sugar: return "drop.fill"
        case .high_blood_lipids: return "flame.fill"
        case .general_wellness: return "heart.circle.fill"
        case .fat_loss: return "arrow.down.circle.fill"
        case .muscle_gain: return "dumbbell.fill"
        case .blood_sugar_control: return "chart.line.downtrend.xyaxis"
        case .balanced: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .high_blood_pressure: return SafeEatTheme.danger
        case .high_blood_sugar: return SafeEatTheme.warning
        case .high_blood_lipids: return Color(red: 0.545, green: 0.412, blue: 0.078)
        case .general_wellness: return SafeEatTheme.success
        case .fat_loss: return SafeEatTheme.danger
        case .muscle_gain: return SafeEatTheme.primary
        case .blood_sugar_control: return SafeEatTheme.warning
        case .balanced: return SafeEatTheme.primary
        }
    }

    static func forCode(_ code: String) -> HealthTagConfig? {
        switch code {
        case "high_blood_pressure": return .high_blood_pressure
        case "high_blood_sugar": return .high_blood_sugar
        case "high_blood_lipids": return .high_blood_lipids
        case "general_wellness": return .general_wellness
        case "fat_loss": return .fat_loss
        case "muscle_gain": return .muscle_gain
        case "blood_sugar_control": return .blood_sugar_control
        case "balanced": return .balanced
        default: return nil
        }
    }
}

// MARK: - 会员等级卡片

private struct MembershipTierCard: View {
    let tier: PlanTierMapper.Tier
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconFgColor)
            }

            // 文字
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SafeEatFont.custom(16, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(titleColor)
                Text(subtitle)
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(subtitleColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(chevronColor)
        }
        .padding(16)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 样式属性

    private var iconName: String {
        switch tier {
        case .free: return "person.crop.circle"
        case .lite: return "star.fill"
        case .pro, .premium: return "crown.fill"
        }
    }

    private var iconBgColor: Color {
        switch tier {
        case .free: return SafeEatTheme.primarySoft
        case .lite: return SafeEatTheme.warning.opacity(0.15)
        case .pro: return Color(red: 0.83, green: 0.65, blue: 0.27).opacity(0.20)
        case .premium: return Color(red: 0.83, green: 0.65, blue: 0.27).opacity(0.20)
        }
    }

    private var iconFgColor: Color {
        switch tier {
        case .free: return SafeEatTheme.textSecondary
        case .lite: return SafeEatTheme.warning
        case .pro, .premium: return Color(red: 0.83, green: 0.65, blue: 0.27)
        }
    }

    private var title: String {
        switch tier {
        case .free: return SafeEatL10n.text(L10nKey.Profile.Member.freeTitle)
        case .lite: return SafeEatL10n.text(L10nKey.Profile.Member.liteTitle)
        case .pro: return SafeEatL10n.text(L10nKey.Profile.Member.proTitle)
        case .premium: return SafeEatL10n.text(L10nKey.Profile.Member.premiumTitle)
        }
    }

    private var subtitle: String {
        switch tier {
        case .free: return SafeEatL10n.text(L10nKey.Profile.Member.freeSubtitle)
        case .lite: return SafeEatL10n.text(L10nKey.Profile.Member.liteSubtitle)
        case .pro: return SafeEatL10n.text(L10nKey.Profile.Member.proSubtitle)
        case .premium: return SafeEatL10n.text(L10nKey.Profile.Member.premiumSubtitle)
        }
    }

    private var titleColor: Color {
        switch tier {
        case .free: return SafeEatTheme.textPrimary
        case .lite: return SafeEatTheme.textPrimary
        case .pro, .premium: return .white
        }
    }

    private var subtitleColor: Color {
        switch tier {
        case .free: return SafeEatTheme.textSecondary
        case .lite: return SafeEatTheme.textSecondary
        case .pro: return .white.opacity(0.80)
        case .premium: return .white.opacity(0.80)
        }
    }

    private var chevronColor: Color {
        switch tier {
        case .free: return SafeEatTheme.textSecondary
        case .lite: return SafeEatTheme.textSecondary
        case .pro, .premium: return .white.opacity(0.60)
        }
    }

    private var strokeColor: Color {
        switch tier {
        case .free: return colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
        case .lite: return SafeEatTheme.warning.opacity(0.25)
        case .pro, .premium: return Color.clear
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch tier {
        case .free:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.92))
        case .lite:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.10 : 0.08))
        case .pro:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SafeEatTheme.primary, SafeEatTheme.primaryDeep],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        case .premium:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SafeEatTheme.primaryDeep, Color(red: 0.06, green: 0.24, blue: 0.17)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
