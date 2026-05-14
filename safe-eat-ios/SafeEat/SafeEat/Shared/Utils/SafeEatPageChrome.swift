import SwiftUI
import UIKit

enum SafeEatSafeArea {
    static func resolvedTopInset(fallback: CGFloat) -> CGFloat {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        else {
            return fallback
        }

        let windowInset = scene.windows.first(where: \.isKeyWindow)?.safeAreaInsets.top
            ?? scene.windows.first?.safeAreaInsets.top
            ?? 0

        return max(fallback, windowInset)
    }
}

struct SafeEatPageHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle))
                .foregroundStyle(SafeEatTheme.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(SafeEatFont.textStyle(.subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SafeEatScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SafeEatScrollOffsetReader: View {
    let coordinateSpaceName: String

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: SafeEatScrollOffsetKey.self,
                    value: proxy.frame(in: .named(coordinateSpaceName)).minY
                )
        }
        .frame(height: 1)
    }
}

struct SafeEatGlobalScrollOffsetReader: View {
    @Binding var scrollOffset: CGFloat
    @State private var initialMinY: CGFloat = 0
    @State private var hasInitialized = false

    var body: some View {
        GeometryReader { proxy in
            let currentMinY = proxy.frame(in: .global).minY

            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: currentMinY)
                .onAppear {
                    resetTracking(to: currentMinY)
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { newMinY in
                    if !hasInitialized {
                        resetTracking(to: newMinY)
                        return
                    }
                    scrollOffset = newMinY - initialMinY
                }
        }
        .frame(height: 1)
    }

    private func resetTracking(to minY: CGFloat) {
        initialMinY = minY
        hasInitialized = true
        scrollOffset = 0
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SafeEatScrollNavChrome: View {
    let title: String
    let scrollOffset: CGFloat
    let topInset: CGFloat

    private var revealedScroll: CGFloat {
        max(-scrollOffset, 0)
    }

    private var progress: CGFloat {
        min(max((-scrollOffset) / 24, 0), 1)
    }

    private var showsChrome: Bool {
        progress > 0.02
    }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.98), location: 0),
                            .init(color: .black.opacity(0.86), location: 0.55),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(progress)

            Text(title)
                .font(SafeEatFont.custom(24, relativeTo: .title3))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .lineLimit(1)
                .padding(.top, topInset + 10)
                .padding(.horizontal, 64)
                .opacity(progress)
                .scaleEffect(0.94 + (progress * 0.06))
        }
        .ignoresSafeArea()
        .frame(height: topInset + 70, alignment: .top)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.18), value: progress)
    }
}

struct SafeEatTopBackChrome: View {
    let title: String
    let scrollOffset: CGFloat
    let topInset: CGFloat
    var contentTopSpacing: CGFloat = 8
    var reservedHeight: CGFloat = 98
    var minimumBackdropOpacity: CGFloat = 0
    var emphasizesSafeAreaFill: Bool = false
    var usesSolidBackdrop: Bool = false
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var revealedScroll: CGFloat {
        max(-scrollOffset, 0)
    }

    private var appearanceThreshold: CGFloat {
        1.5
    }

    private var showsChrome: Bool {
        revealedScroll > 0.02
    }

    private var backdropOpacity: CGFloat {
        guard showsChrome else { return 0 }
        let animatedOpacity = min(max((revealedScroll - appearanceThreshold) / 18, 0), 1)
        return max(minimumBackdropOpacity, animatedOpacity)
    }

    /// 内容行顶部padding（相对于组件顶部）
    private var rowTopPadding: CGFloat {
        topInset + contentTopSpacing
    }

    /// 整个 sticky header 的高度（从屏幕顶部算起）
    private var chromeHeight: CGFloat {
        topInset + reservedHeight
    }

    /// 按钮大小
    private var buttonSize: CGFloat { 50 }

    private var safeAreaFillColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.54)
            : Color.white.opacity(0.92)
    }

    private var chromeContent: some View {
        HStack(spacing: 0) {
            backButton

            Spacer(minLength: 0)

            Text(title)
                .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .lineLimit(1)
                .opacity(showsChrome ? 1 : 0)
                .offset(y: showsChrome ? 0 : 6)

            Spacer(minLength: 0)

            Color.clear
                .frame(width: buttonSize, height: buttonSize)
        }
        .padding(.horizontal, 20)
        .padding(.top, rowTopPadding)
        .frame(height: reservedHeight, alignment: .top)
    }

    var body: some View {
        ZStack(alignment: .top) {
            backdropLayer
                .opacity(backdropOpacity)
                .allowsHitTesting(false)
            chromeContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity)
        .frame(height: chromeHeight, alignment: .top)
        .zIndex(10)
        .animation(.easeInOut(duration: 0.18), value: backdropOpacity)
        .animation(.easeInOut(duration: 0.14), value: showsChrome)
    }

    private var backdropLayer: some View {
        legacyGradientBackdrop
    }

    private var legacyGradientBackdrop: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: colorScheme == .dark
                            ? [
                                .init(color: Color.black.opacity(0.54), location: 0.0),
                                .init(color: Color.black.opacity(0.34), location: 0.28),
                                .init(color: Color.black.opacity(0.16), location: 0.58),
                                .init(color: Color.clear, location: 1.0),
                            ]
                            : [
                                .init(color: Color.white.opacity(0.92), location: 0.0),
                                .init(color: Color.white.opacity(0.58), location: 0.24),
                                .init(color: Color(red: 0.96, green: 0.985, blue: 0.97).opacity(0.24), location: 0.58),
                                .init(color: Color.clear, location: 1.0),
                            ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            if emphasizesSafeAreaFill {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: colorScheme == .dark
                                    ? [
                                        .init(color: Color.black.opacity(0.54), location: 0.0),
                                    ]
                                    : [
                                        .init(color: Color.white.opacity(0.92), location: 0.0),
                                    ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Spacer(minLength: 0)
                }
            }
        }
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0.0),
                    .init(color: .black.opacity(0.96), location: 0.26),
                    .init(color: .black.opacity(0.62), location: 0.62),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.76))
                )
                .overlay(
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}


struct SafeEatDateTitle: View {
    let date: Date
    var showsMonth = true
    var showsDay = true
    var color: Color = SafeEatTheme.textPrimary
    var largeSize: CGFloat = 34
    var smallSize: CGFloat = 18

    private var monthText: String {
        String(format: "%02d", Calendar.current.component(.month, from: date))
    }

    private var dayText: String {
        String(format: "%02d", Calendar.current.component(.day, from: date))
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            if showsMonth {
                Text(monthText)
                    .font(SafeEatFont.custom(largeSize, relativeTo: .largeTitle))
                    .foregroundStyle(color)
                Text("月")
                    .font(SafeEatFont.custom(smallSize, relativeTo: .headline))
                    .foregroundStyle(color)
            }

            if showsMonth && showsDay {
                Color.clear
                    .frame(width: 4, height: 1)
            }

            if showsDay {
                Text(dayText)
                    .font(SafeEatFont.custom(largeSize, relativeTo: .largeTitle))
                    .foregroundStyle(color)
                Text("日")
                    .font(SafeEatFont.custom(smallSize, relativeTo: .headline))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SafeEatSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(SafeEatFont.textStyle(.headline))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .textCase(nil)
    }
}

struct SafeEatEmptyState: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(SafeEatTheme.textSecondary)

            VStack(spacing: 6) {
                Text(title)
                    .font(SafeEatFont.textStyle(.headline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(message)
                    .font(SafeEatFont.textStyle(.subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}
