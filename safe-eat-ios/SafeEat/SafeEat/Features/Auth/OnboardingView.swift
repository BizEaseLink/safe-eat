import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore

    @State private var currentPage = 0
    @State private var showsFinalButton = false

    private let pages: [(artwork: String, titleKey: String, bodyKey: String)] = [
        ("OnboardingPage1", L10nKey.Onboarding.page1Title, L10nKey.Onboarding.page1Body),
        ("OnboardingPage2", L10nKey.Onboarding.page2Title, L10nKey.Onboarding.page2Body),
        ("OnboardingPage3", L10nKey.Onboarding.page3Title, L10nKey.Onboarding.page3Body),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                onboardingBackground

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        skipButton
                    }
                    .padding(.top, SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top) + 12)
                    .padding(.horizontal, 22)

                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            onboardingPage(page: page, proxy: proxy)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onChange(of: currentPage) { _, newValue in
                        handlePageChange(newValue)
                    }

                    VStack(spacing: showsFinalButton ? 22 : 0) {
                        pageIndicator
                        if showsFinalButton {
                            startButton
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 16) + 24)
                }
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }

    private var onboardingBackground: some View {
        Color.white
    }

    private var skipButton: some View {
        Button {
            store.completeOnboarding(allowsGuestHome: true)
        } label: {
            Text(SafeEatL10n.text(L10nKey.Onboarding.skip))
                .font(SafeEatFont.custom(14, relativeTo: .body, weight: .semibold))
                .foregroundStyle(SafeEatTheme.primaryDeep)
                .frame(minWidth: 72)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.82))
                )
                .overlay(
                    Capsule()
                        .stroke(SafeEatTheme.line.opacity(0.95), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func onboardingPage(page: (artwork: String, titleKey: String, bodyKey: String), proxy: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 28)

                Image(page.artwork)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: proxy.size.width * 1.28,
                        height: min(proxy.size.height * 0.58, 660),
                        alignment: .center
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: 80)

                Spacer(minLength: 0)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)

            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0.30),
                    .init(color: Color.white.opacity(0.18), location: 0.52),
                    .init(color: Color.white.opacity(0.95), location: 0.73),
                    .init(color: Color.white, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 14) {
                Text(SafeEatL10n.text(page.titleKey))
                    .font(SafeEatFont.custom(28, relativeTo: .largeTitle, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primaryDeep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)

                Text(SafeEatL10n.text(page.bodyKey))
                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 34)
            }
            .padding(.bottom, currentPage == pages.count - 1 ? 122 : 82)
        }
        .frame(width: proxy.size.width, height: proxy.size.height)
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? SafeEatTheme.primary : SafeEatTheme.textSecondary.opacity(0.18))
                    .frame(width: currentPage == index ? 30 : 10, height: 10)
            }
        }
    }

    private var startButton: some View {
        Button {
            store.completeOnboarding(allowsGuestHome: true)
        } label: {
            Text(SafeEatL10n.text(L10nKey.Onboarding.start))
                .font(SafeEatFont.custom(19, relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .shadow(color: SafeEatTheme.primaryDeep.opacity(0.20), radius: 22, y: 12)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.52), value: currentPage)
    }

    private func handlePageChange(_ newValue: Int) {
        withAnimation(.easeOut(duration: 0.32)) {
            showsFinalButton = newValue == pages.count - 1
        }
        if newValue == pages.count - 1 {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(160))
                guard currentPage == pages.count - 1 else { return }
                withAnimation(.easeOut(duration: 0.32)) {
                    showsFinalButton = true
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppStore())
}