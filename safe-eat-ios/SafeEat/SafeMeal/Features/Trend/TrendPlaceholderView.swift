import SwiftUI

struct TrendPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "monitoring")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SafeMealTheme.textSecondary)

            Text(SafeMealL10n.text(L10nKey.Tab.trend))
                .font(SafeMealFont.custom(28, relativeTo: .title2))
                .foregroundStyle(SafeMealTheme.textPrimary)

            Text("健康趋势与报告功能即将上线")
                .font(SafeMealFont.textStyle(.subheadline))
                .foregroundStyle(SafeMealTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SafeMealMainGradientBackground())
        .toolbar(.hidden, for: .navigationBar)
        .navigationTitle(SafeMealL10n.text(L10nKey.Tab.trend))
    }
}

#Preview {
    NavigationStack {
        TrendPlaceholderView()
    }
}