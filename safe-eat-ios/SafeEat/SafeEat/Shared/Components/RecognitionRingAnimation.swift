import SwiftUI

/// 识别阶段枚举
enum RecognitionPhase: Equatable {
    case identifying
    case selecting(candidates: [IdentifyCandidate], dbMatches: [DbMatch], sessionId: String)
    case evaluating
    case nonFood

    static func == (lhs: RecognitionPhase, rhs: RecognitionPhase) -> Bool {
        switch (lhs, rhs) {
        case (.identifying, .identifying): return true
        case (.evaluating, .evaluating): return true
        case (.selecting, .selecting): return true
        case (.nonFood, .nonFood): return true
        default: return false
        }
    }
}

/// 环形加载动画 — 正在智评阶段的核心视觉
struct RecognitionRingAnimation: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0
    @State private var breathScale: CGFloat = 1.0
    @State private var glowPosition: CGFloat = 0

    private let ringSize: CGFloat = 200
    private let logoSize: CGFloat = 68
    private let lineLength: CGFloat = 22

    var body: some View {
        ZStack {
            // 内圈：呼吸效果 + 缓慢逆时针旋转
            Circle()
                .stroke(
                    SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.18 : 0.22),
                    lineWidth: 2
                )
                .frame(width: ringSize - 20, height: ringSize - 20)
                .scaleEffect(breathScale)
                .rotationEffect(.degrees(innerRotation))

            // 外圈：旋转弧线 + 发光圆点
            outerRingWithDot

            // 连线：3 条线从圆环边缘延伸到标签
            tagLine(angle: 210)
            tagLine(angle: 330)
            tagLine(angle: 90)

            // 中心 Logo
            LottieLoadingView(size: logoSize)
                .frame(width: logoSize + 8, height: logoSize + 8)
                .shadow(color: SafeEatTheme.primaryDeep.opacity(0.3), radius: 8, y: 4)

            // 3 个功能标签
            tagLabel(
                icon: "square.grid.2x2",
                title: SafeEatL10n.text(L10nKey.RecognitionPhase.tagIdentify),
                detail: SafeEatL10n.text(L10nKey.RecognitionPhase.tagIdentifyDetail)
            )
            .position(tagPosition(angle: 210))

            tagLabel(
                icon: "chart.pie",
                title: SafeEatL10n.text(L10nKey.RecognitionPhase.tagNutrition),
                detail: SafeEatL10n.text(L10nKey.RecognitionPhase.tagNutritionDetail)
            )
            .position(tagPosition(angle: 330))

            tagLabel(
                icon: "shield.checkmark",
                title: SafeEatL10n.text(L10nKey.RecognitionPhase.tagSafety),
                detail: SafeEatL10n.text(L10nKey.RecognitionPhase.tagSafetyDetail)
            )
            .position(tagPosition(angle: 90))
        }
        .frame(width: ringSize + 140, height: ringSize + 140)
        .onAppear { startAnimations() }
    }

    // MARK: - 外圈弧线 + 发光圆点

    private var outerRingWithDot: some View {
        ZStack {
            // 底层轨道
            Circle()
                .stroke(
                    SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.08 : 0.12),
                    lineWidth: 4
                )
                .frame(width: ringSize, height: ringSize)

            // 旋转弧线
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [
                            SafeEatTheme.primary.opacity(0.1),
                            SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.6 : 0.8),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(outerRotation))

            // 发光圆点（弧线末端）
            Circle()
                .fill(SafeEatTheme.primary)
                .frame(width: 8, height: 8)
                .shadow(color: SafeEatTheme.primary.opacity(0.6), radius: 6)
                .offset(y: -ringSize / 2)
                .rotationEffect(.degrees(outerRotation + 252)) // 0.7 * 360 ≈ 252
        }
    }

    // MARK: - 连线

    private func tagLine(angle: CGFloat) -> some View {
        let center = CGPoint(x: (ringSize + 140) / 2, y: (ringSize + 140) / 2)
        let ringRadius = ringSize / 2
        let rad = angle * .pi / 180

        let start = CGPoint(
            x: center.x + ringRadius * cos(rad),
            y: center.y + ringRadius * sin(rad)
        )
        let end = CGPoint(
            x: center.x + (ringRadius + lineLength) * cos(rad),
            y: center.y + (ringRadius + lineLength) * sin(rad)
        )

        return Path { path in
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.25 : 0.35),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
        )
    }

    // MARK: - 功能标签

    private func tagLabel(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SafeEatTheme.primary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                    .foregroundStyle(SafeEatTheme.primary)
                Text(detail)
                    .font(SafeEatFont.custom(10, relativeTo: .caption2))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(SafeEatTheme.line.opacity(0.5), lineWidth: 0.5)
        )
    }

    // MARK: - 标签位置

    private func tagPosition(angle: CGFloat) -> CGPoint {
        let center = CGPoint(x: (ringSize + 140) / 2, y: (ringSize + 140) / 2)
        let radius: CGFloat = (ringSize / 2) + lineLength + 8
        let rad = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(rad),
            y: center.y + radius * sin(rad)
        )
    }

    // MARK: - 动画

    private func startAnimations() {
        // 外圈顺时针旋转
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            outerRotation = 360
        }
        // 内圈逆时针慢速旋转
        withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }
        // 呼吸效果
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathScale = 1.06
        }
    }
}