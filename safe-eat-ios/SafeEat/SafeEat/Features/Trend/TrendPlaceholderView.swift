import SwiftUI

struct TrendPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "monitoring")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SafeEatTheme.textSecondary)

            Text(SafeEatL10n.text(L10nKey.Tab.trend))
                .font(SafeEatFont.custom(28, relativeTo: .title2))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text("健康趋势与报告功能即将上线")
                .font(SafeEatFont.textStyle(.subheadline))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SafeEatMainGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(SafeEatL10n.text(L10nKey.Tab.trend))
    }
}

#Preview {
    NavigationStack {
        TrendPlaceholderView()
    }
}