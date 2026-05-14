import SwiftUI

struct SafeEatSurfaceCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let cornerRadius: CGFloat
    private let contentPadding: EdgeInsets
    private let shadowRadius: CGFloat
    private let shadowYOffset: CGFloat
    private let onTap: (() -> Void)?
    private let content: Content

    init(
        cornerRadius: CGFloat = 30,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        shadowRadius: CGFloat = 22,
        shadowYOffset: CGFloat = 14,
        onTap: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.contentPadding = padding
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                shape.fill(.ultraThinMaterial)
            }
            .background {
                shape.fill(surfaceFill)
            }
            .overlay {
                shape.stroke(surfaceStroke, lineWidth: 1)
            }
            .shadow(color: surfaceShadow, radius: shadowRadius, y: shadowYOffset)
            .contentShape(shape)
            .onTapGesture {
                onTap?()
            }
    }

    private var surfaceFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
    }

    private var surfaceStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.76)
    }

    private var surfaceShadow: Color {
        SafeEatTheme.primaryDeep.opacity(0.10)
    }
}
