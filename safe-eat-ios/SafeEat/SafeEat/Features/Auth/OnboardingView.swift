import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var currentPage = 0

    private let pages: [(icon: String, titleKey: String, bodyKey: String)] = [
        ("camera.fill", L10nKey.Onboarding.page1Title, L10nKey.Onboarding.page1Body),
        ("exclamationmark.triangle.fill", L10nKey.Onboarding.page2Title, L10nKey.Onboarding.page2Body),
        ("clock.badge.checkmark.fill", L10nKey.Onboarding.page3Title, L10nKey.Onboarding.page3Body),
    ]

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                skipButton
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .zIndex(10)

                ZStack(alignment: .bottom) {
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            onboardingPage(index: index, page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    VStack(spacing: 0) {
                        pageIndicator
                        startButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var onboardingBackground: some View {
        ZStack {
            SafeEatMainGradientBackground()

            Circle()
                .fill(SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.06 : 0.40))
                .frame(width: 320, height: 320)
                .blur(radius: 6)
                .offset(x: -80, y: -200)

            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .fill(Color(red: 0.96, green: 0.90, blue: 0.80).opacity(colorScheme == .dark ? 0.06 : 0.45))
                .frame(width: 240, height: 160)
                .rotationEffect(.degrees(-12))
                .offset(x: 140, y: -240)

            Circle()
                .fill(SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.05 : 0.18))
                .frame(width: 200, height: 200)
                .offset(x: 120, y: 280)

            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.35))
                .frame(width: 180, height: 120)
                .rotationEffect(.degrees(8))
                .offset(x: -140, y: 120)
        }
        .ignoresSafeArea()
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button {
                store.completeOnboarding()
            } label: {
                Text(SafeEatL10n.text(L10nKey.Onboarding.skip))
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52))
                    )
                    .overlay(
                        Capsule()
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func onboardingPage(index: Int, page: (icon: String, titleKey: String, bodyKey: String)) -> some View {
        VStack(spacing: 0) {
            Spacer()

            iconCircle(systemName: page.icon)
                .padding(.bottom, 40)

            Text(SafeEatL10n.text(page.titleKey))
                .font(SafeEatFont.custom(30, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .padding(.bottom, 16)

            Text(SafeEatL10n.text(page.bodyKey))
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)

            Spacer()
        }
    }

    private func iconCircle(systemName: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [SafeEatTheme.primaryDeep.opacity(0.14), SafeEatTheme.primary.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 150, height: 150)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.08 : 0.50), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)

            Image(systemName: systemName)
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 24, y: 12)
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.22))
                    .frame(width: currentPage == index ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
            }
        }
        .padding(.bottom, 28)
    }

    private var startButton: some View {
        Group {
            if currentPage == pages.count - 1 {
                Button {
                    store.completeOnboarding()
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Onboarding.start))
                        .font(SafeEatFont.custom(19, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
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
                        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.24), radius: 20, y: 10)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: currentPage)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStore())
}
