import SwiftUI

// MARK: - T8: 付费墙 Section 枚举

enum PaywallSection: Int, CaseIterable {
    case s1BasicNutrients = 1
    case s2DetailedNutrients
    case s3Vitamins
    case s4Minerals
    case s5DailyValues
    case s6Glycemic
    case s7Allergens
    case s8Dietary
    case s9Preparation
    case s10Ingredients

    /// 返回解锁此 Section 所需的最低 tier（数字越大权限越高）
    var minimumTier: MembershipTier {
        switch self {
        case .s1BasicNutrients: return .free
        case .s2DetailedNutrients: return .lite
        case .s3Vitamins: return .lite
        case .s4Minerals: return .lite
        case .s5DailyValues: return .lite
        case .s6Glycemic: return .lite
        case .s7Allergens: return .free   // FREE 可见 contains，完整需要 PRO
        case .s8Dietary: return .pro
        case .s9Preparation: return .pro
        case .s10Ingredients: return .premium
        }
    }

    /// S7 特殊逻辑：FREE 只看 contains，PRO 看完整过敏原
    var requiresProForFull: Bool { self == .s7Allergens }
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

    /// 判断某 Section 是否完全可见
    func isSectionFullyVisible(_ section: PaywallSection) -> Bool {
        self >= section.minimumTier && !(section.requiresProForFull && self < .pro)
    }

    /// 判断某 Section 是否部分可见（S7 过敏原：FREE 看 contains）
    func isSectionPartiallyVisible(_ section: PaywallSection) -> Bool {
        section == .s7Allergens && self == .free
    }
}

// MARK: - 付费墙遮罩视图

struct PaywallOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme
    let section: PaywallSection
    let onUpgrade: () -> Void

    var body: some View {
        ZStack {
            // 模糊遮罩背景
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
