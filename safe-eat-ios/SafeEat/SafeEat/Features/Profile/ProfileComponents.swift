import SwiftUI
import UIKit

func profileSurfaceFill(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
}

func profileControlFill(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.72)
}

func profileStrokeColor(for colorScheme: ColorScheme) -> Color {
    colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
}

struct ProfileSurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(profileSurfaceFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.10), radius: 22, y: 14)
    }
}

struct ProfileSectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SafeEatSectionHeader(title: title)
            ProfileSurfaceCard {
                content
            }
        }
    }
}

struct ProfileNavigationRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var trailingText: String? = nil
    var tint: Color = SafeEatTheme.primary

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(SafeEatFont.textStyle(.footnote))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }

            Spacer()

            if let trailingText, !trailingText.isEmpty {
                Text(trailingText)
                    .font(SafeEatFont.textStyle(.footnote))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.75))
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }
}

struct ProfileChoiceChip: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(isSelected ? Color.white : SafeEatTheme.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(isSelected ? SafeEatTheme.primary : profileControlFill(for: colorScheme))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? SafeEatTheme.primary : profileStrokeColor(for: colorScheme), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileSelectionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.primary)
                } else {
                    Circle()
                        .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1.5)
                        .frame(width: 18, height: 18)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(profileControlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? SafeEatTheme.primary.opacity(0.28) : profileStrokeColor(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileAvatarView: View {
    @Environment(\.colorScheme) private var colorScheme
    let profile: UserProfile?
    var previewImage: UIImage? = nil
    var size: CGFloat = 88

    var body: some View {
        Group {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFill()
            } else if let url = profile?.avatarRemoteURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(profileStrokeColor(for: colorScheme), lineWidth: 2)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.16), radius: 12, y: 8)
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(gradientForGender)

            Image(systemName: iconForGender)
                .font(.system(size: size * 0.38, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    /// 根据性别返回不同的 SF Symbol
    private var iconForGender: String {
        switch profile?.gender {
        case "male": return "person.fill"
        case "female": return "person.fill"
        default: return "person.fill"
        }
    }

    /// 根据性别返回不同的渐变色
    private var gradientForGender: LinearGradient {
        switch profile?.gender {
        case "male":
            LinearGradient(
                colors: [Color(red: 0.18, green: 0.49, blue: 0.56), Color(red: 0.11, green: 0.36, blue: 0.42)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "female":
            LinearGradient(
                colors: [Color(red: 0.72, green: 0.36, blue: 0.46), Color(red: 0.58, green: 0.24, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            LinearGradient(
                colors: [SafeEatTheme.primary, SafeEatTheme.primaryDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var initials: String {
        if let profile {
            if let displayName = profile.displayName, let first = displayName.trimmingCharacters(in: .whitespacesAndNewlines).first {
                return String(first)
            }
            if let phone = profile.phone, !phone.isEmpty {
                return String(phone.suffix(2))
            }
            return String(SafeEatL10n.text(L10nKey.Brand.appName).prefix(1))
        }
        return String(SafeEatL10n.text(L10nKey.Brand.appName).prefix(1))
    }
}

struct ProfileStaticRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(label)
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textPrimary)
            Spacer()
            Text(value)
                .font(SafeEatFont.textStyle(.body))
                .foregroundStyle(SafeEatTheme.textSecondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ProfilePrimaryActionButton: View {
    let title: String
    var isLoading = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(title)
                        .frame(maxWidth: .infinity)
                }
            }
            .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
            .foregroundStyle(.white)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

struct ProfileSecondaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .font(SafeEatFont.custom(16, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(SafeEatTheme.primary)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SafeEatTheme.primarySoft)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SafeEatTheme.primary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileFieldBlock<Content: View>: View {
    let label: String
    var hint: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label)
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                if let hint, !hint.isEmpty {
                    Text(hint)
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }

            content
        }
    }
}

struct ProfileTextField: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(title, text: $text)
            .keyboardType(keyboardType)
            .font(SafeEatFont.custom(16, relativeTo: .body))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(profileControlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
            )
    }
}

struct ProfileSecureField: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .textInputAutocapitalization(.never)
            .font(SafeEatFont.custom(16, relativeTo: .body))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(profileControlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
            )
    }
}

struct ProfileMenuField: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    let options: [(id: String, title: String)]
    let onSelect: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.id) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    if option.id == value {
                        Label(option.title, systemImage: "checkmark")
                    } else {
                        Text(option.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text(options.first(where: { $0.id == value })?.title ?? SafeEatL10n.text(L10nKey.Common.notSet))
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(profileControlFill(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileSecondaryChrome: View {
    let title: String
    let scrollOffset: CGFloat
    let topInset: CGFloat
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var progress: CGFloat {
        min(max((-scrollOffset) / 28, 0), 1)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.98), location: 0),
                            .init(color: .black.opacity(0.84), location: 0.58),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(progress)

            HStack(spacing: 0) {
                backButton

                Spacer(minLength: 0)

                Text(title)
                    .font(SafeEatFont.custom(22, relativeTo: .title3, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .lineLimit(1)
                    .opacity(progress)
                    .offset(y: progress > 0.02 ? 0 : 6)

                Spacer(minLength: 0)

                Color.clear
                    .frame(width: 48, height: 48)
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset + 8)
        }
        .ignoresSafeArea()
        .frame(height: topInset + 72, alignment: .top)
        .animation(.easeInOut(duration: 0.18), value: progress)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(profileControlFill(for: colorScheme))
                )
                .overlay(
                    Circle()
                        .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ProfileSecondaryPage<Content: View, Footer: View>: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder let content: Content
    @ViewBuilder let footer: Footer

    @State private var scrollOffset: CGFloat = 0
    private let scrollCoordinateSpace = "safeeat.profile.secondary.scroll"

    init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.content = content()
        self.footer = footer()
    }

    init(
        title: String,
        subtitle: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) where Footer == EmptyView {
        self.init(title: title, subtitle: subtitle, onBack: onBack, content: content, footer: { EmptyView() })
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = SafeEatSafeArea.resolvedTopInset(fallback: proxy.safeAreaInsets.top)

            ZStack(alignment: .topLeading) {
                SafeEatMainGradientBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                        Color.clear
                            .frame(height: topInset + 54)

                        header

                        content

                        footer
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .onPreferenceChange(SafeEatScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                ProfileSecondaryChrome(
                    title: title,
                    scrollOffset: scrollOffset,
                    topInset: topInset,
                    onBack: { onBack?() ?? dismiss() }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
    }
}
