import SwiftUI

struct UpdateAvailableSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    private let store = AppVersionStore.shared

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(dragIndicatorColor)
                .frame(width: 42, height: 6)
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(spacing: 16) {
                iconView

                VStack(spacing: 7) {
                    Text("发现新版本")
                        .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    if let notes = store.updateInfo?.releaseNotes {
                        Text(notes)
                            .font(SafeEatFont.custom(14, relativeTo: .subheadline))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        store.skipCurrentVersion()
                    } label: {
                        Text("稍后")
                            .font(SafeEatFont.custom(16, relativeTo: .body, weight: .semibold))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        store.openAppStore()
                    } label: {
                        Text("立即更新")
                            .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(buttonGradient)
                            )
                            .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.18 : 0.20), radius: 18, y: 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(sheetFill)
        .background(.ultraThinMaterial)
        .shadow(color: sheetShadow, radius: 28, y: -8)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
        .presentationCornerRadius(36)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.16 : 0.14))
                .frame(width: 58, height: 58)

            Image(systemName: "sparkles")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)
                .symbolRenderingMode(.hierarchical)
        }
        .shadow(color: SafeEatTheme.primary.opacity(0.14), radius: 18, y: 8)
    }

    private var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var sheetFill: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.12, blue: 0.11).opacity(0.72)
            : Color.white.opacity(0.78)
    }

    private var sheetShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.32) : SafeEatTheme.primaryDeep.opacity(0.12)
    }

    private var dragIndicatorColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.24)
    }
}
