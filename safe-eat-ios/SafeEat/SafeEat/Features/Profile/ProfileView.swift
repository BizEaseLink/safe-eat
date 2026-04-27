import StoreKit
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var settings: AppSettingsStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var plans: [MembershipPlan] = []
    @State private var loadingPlans = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isLoggingOut = false
    @State private var activeSheet: ProfileSheet?

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
                        } else {
                            heroSection
                            healthProfileSection
                            membershipEntry
                            infoEntrySection
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
        .task {
            await settings.refreshNotificationStatus()
            await store.refreshProfile()
            await loadPlansIfNeeded()
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

                        Text(PlanTierMapper.shortTitle(store.profile?.currentPlanTier))
                            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(SafeEatTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(SafeEatTheme.primarySoft)
                            )
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
                NavigationLink {
                    PreferenceSettingsView()
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
            NavigationLink {
                MembershipPurchaseView()
            } label: {
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

            Divider().overlay(SafeEatTheme.line)

            NavigationLink {
                OrderHistoryView()
            } label: {
                ProfileNavigationRow(
                    icon: "receipt",
                    title: SafeEatL10n.text(L10nKey.Order.title),
                    subtitle: SafeEatL10n.text(L10nKey.Order.subtitle)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var infoEntrySection: some View {
        ProfileSectionBlock(title: SafeEatL10n.text(L10nKey.Profile.editGroupTitle)) {
            NavigationLink {
                EditProfileView()
            } label: {
                ProfileNavigationRow(
                    icon: "person.crop.circle.badge.plus",
                    title: SafeEatL10n.text(L10nKey.Profile.editTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.editSubtitle),
                    trailingText: store.profile == nil ? nil : "\(SafeEatL10n.text(L10nKey.Profile.bmiLabel)) \(bmiText)"
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink {
                PreferenceSettingsView()
            } label: {
                ProfileNavigationRow(
                    icon: "slider.horizontal.3",
                    title: SafeEatL10n.text(L10nKey.Profile.preferenceTitle),
                    subtitle: preferenceSummary
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

            NavigationLink {
                SecuritySettingsView()
            } label: {
                ProfileNavigationRow(
                    icon: "lock.shield",
                    title: SafeEatL10n.text(L10nKey.Profile.securityTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.securitySubtitle)
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink {
                CacheSettingsView()
            } label: {
                ProfileNavigationRow(
                    icon: "internaldrive",
                    title: SafeEatL10n.text(L10nKey.Profile.cacheTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.cacheSubtitle),
                    trailingText: store.localCacheSizeText
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink {
                FeedbackProblemView()
            } label: {
                ProfileNavigationRow(
                    icon: "exclamationmark.bubble",
                    title: SafeEatL10n.text(L10nKey.Profile.feedbackTitle),
                    subtitle: SafeEatL10n.text(L10nKey.Profile.feedbackSubtitle)
                )
            }
            .buttonStyle(.plain)

            Divider().overlay(SafeEatTheme.line)

            NavigationLink {
                UpdateSettingsView()
            } label: {
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
            NavigationLink {
                AboutSafeEatView()
            } label: {
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
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 48))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(SafeEatL10n.text(L10nKey.Profile.notLoggedInTitle))
                .font(SafeEatFont.custom(20, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Profile.notLoggedInMessage))
                .font(SafeEatFont.custom(15, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                store.requireLogin()
            } label: {
                Text(SafeEatL10n.text(L10nKey.Auth.goLogin))
                    .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
        )
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
            pieces.append(healthTags.prefix(2).map(HealthTagMapper.title).joined(separator: separator))
        }
        if let fitnessGoal = store.profile?.fitnessGoal {
            pieces.append(FitnessGoalMapper.title(fitnessGoal))
        }
        return pieces.isEmpty ? SafeEatL10n.text(L10nKey.Profile.preferenceSubtitleDefault) : pieces.joined(separator: " · ")
    }

    private func loadPlansIfNeeded() async {
        guard plans.isEmpty else { return }

        loadingPlans = true
        defer { loadingPlans = false }

        do {
            plans = try await store.api.getPlans()
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
