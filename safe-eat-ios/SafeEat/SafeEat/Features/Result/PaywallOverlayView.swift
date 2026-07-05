import SwiftUI

// MARK: - 付费墙 Section 枚举

enum PaywallSection: Int, CaseIterable {
    case s1BasicNutrients = 1
    case s2DetailedNutrients
    case s3Vitamins
    case s4Minerals
    case s4_5TraceMinerals  // 其他微量元素，独立于 S4 矿物质
    case s6Glycemic
    case s7Allergens
    case s8Dietary
    case s9Preparation
    case s10Ingredients

    /// 返回解锁此 Section 所需的最低 tier
    var minimumTier: MembershipTier {
        switch self {
        case .s1BasicNutrients: return .free
        case .s2DetailedNutrients: return .free   // Free 部分露出，Lite+ 全可见
        case .s3Vitamins: return .lite
        case .s4Minerals: return .lite
        case .s4_5TraceMinerals: return .lite      // 与 S4 同层级可见
        case .s6Glycemic: return .lite
        case .s7Allergens: return .pro             // 后端 PRO 级别过滤，iOS 对齐
        case .s8Dietary: return .pro               // Pro 部分露出，Premium 全可见
        case .s9Preparation: return .premium       // 后端 PREMIUM 级别过滤，iOS 对齐
        case .s10Ingredients: return .premium       // 后端 PREMIUM 级别过滤，iOS 对齐
        }
    }

    /// 此 section 是否对当前 tier 采用"部分露出"效果
    /// 部分露出 = 渲染第1条数据，下方渐变模糊+锁+升级CTA
    func isPartiallyRevealed(for tier: MembershipTier) -> Bool {
        switch self {
        case .s2DetailedNutrients: return tier == .free
        case .s8Dietary: return tier == .pro
        default: return false
        }
    }

    /// 此 section 是否对当前 tier 完全不可见（直接遮罩，不部分露出）
    func isFullyBlocked(for tier: MembershipTier) -> Bool {
        tier < minimumTier && !isPartiallyRevealed(for: tier)
    }

    /// 此 section 是否对当前 tier 完全可见
    func isFullyVisible(for tier: MembershipTier) -> Bool {
        tier >= minimumTier && !isPartiallyRevealed(for: tier)
    }
}

enum MembershipTier: Int, CaseIterable, Comparable {
    case free = 0
    case lite = 1
    case pro = 2
    case premium = 3

    static func < (lhs: MembershipTier, rhs: MembershipTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    init(tierString: String?) {
        switch tierString {
        case "lite": self = .lite
        case "pro": self = .pro
        case "premium": self = .premium
        default: self = .free
        }
    }
}

// MARK: - 付费墙遮罩视图

/// 完全遮罩（无内容露出）
struct PaywallOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme
    let section: PaywallSection
    let onUpgrade: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(colorScheme == .dark
                    ? Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0.85)
                    : Color.white.opacity(0.82))
            .background(.ultraThinMaterial)

            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.primary)

                Text(SafeEatL10n.text(L10nKey.Result.paywallUpgradeHint))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Button {
                    onUpgrade()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                        Text(SafeEatL10n.text(L10nKey.Result.paywallUpgradeAction))
                            .font(SafeEatFont.custom(13, relativeTo: .footnote, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// 部分露出遮罩：内容渲染后叠加渐变模糊+锁+升级CTA
struct PaywallPartialRevealOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 渐变模糊遮罩
            LinearGradient(
                colors: [
                    colorScheme == .dark
                        ? Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0)
                        : Color.white.opacity(0),
                    colorScheme == .dark
                        ? Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0.92)
                        : Color.white.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(.ultraThinMaterial)
            .frame(height: 60)

            // 锁+升级CTA
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.primary)

                Button {
                    onUpgrade()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                        Text(SafeEatL10n.text(L10nKey.Result.paywallUpgradeAction))
                            .font(SafeEatFont.custom(12, relativeTo: .footnote, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                colorScheme == .dark
                    ? Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0.95)
                    : Color.white.opacity(0.95)
            )
            .background(.ultraThinMaterial)
        }
    }
}
