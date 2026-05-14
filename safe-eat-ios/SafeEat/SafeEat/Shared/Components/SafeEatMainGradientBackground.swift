import SwiftUI

struct SafeEatMainGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.12, green: 0.13, blue: 0.15),
                        Color(red: 0.09, green: 0.10, blue: 0.12),
                    ]
                    : [
                        Color(red: 0.99, green: 0.995, blue: 0.99),
                        Color(red: 0.965, green: 0.978, blue: 0.968),
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.16 : 0.55),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 14,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.12 : 0.42),
                    Color.clear,
                ],
                center: .bottomTrailing,
                startRadius: 16,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}
