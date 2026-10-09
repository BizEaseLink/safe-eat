import SwiftUI

// MARK: - HugeIcons 图标（字体子集 98 字形，全 app SF Symbols → HugeIcons 统一）
// 字体经 SafeMealFont.bootstrap 运行时注册；映射字典 132 条，未收录回退 question
enum HugeIconGlyph {
    case arrowRight01 // EA21
    case alert02 // E999
    case cancelCircle // EC13
    case cancel01 // EC10
    case image01 // F10F
    case image02 // F110
    case album02 // E995
    case search01 // F6BB
    case arrowLeft01 // EA11
    case arrowDown01 // EA00
    case checkmarkCircle01 // ECB2
    case tick01 // F959
    case lockPassword // F259
    case hourglass // F0F0
    case gift // F019
    case restaurant02 // F620
    case crown03 // EDCB
    case circleArrowUp01 // ECF4
    case circleArrowDown01 // ECD8
    case star // F82D
    case addCircle // E926
    case minusSignCircle // F359
    case userAdd01 // FA31
    case alertCircle // E99A
    case mail01 // F289
    case fileSearch // EF69
    case clock03 // ED19
    case focusPoint // EFBB
    case camera01 // EBF8
    case notificationOff01 // F44A
    case notification01 // F442
    case inboxCheck // F12B
    case ticket01 // F961
    case tag01 // F8DF
    case securityCheck // F6CD
    case helpCircle // F0A9
    case playCircle // F526
    case analytics01 // E9C7
    case medal01 // F2E7
    case idea01 // F10B
    case leaf01 // F1F7
    case informationCircle // F13D
    case globe02 // F02E
    case fire03 // EF93
    case creditCard // EDC4
    case refresh01 // F5F8
    case sun03 // F87A
    case calendar03 // EBAA
    case flash // EFA3
    case flashOff // EFA2
    case record // F5EB
    case circleArrowReload01 // ECEC
    case arrowUp01 // EA2F
    case notification03 // F444
    case userCircle // FA3A
    case shieldKey // F719
    case shield02 // F716
    case favourite // EF41
    case quoteDown // F5C4
    case droplet // EED7
    case file01 // EF4A
    case copy01 // ED9E
    case cameraRotated01 // EC08
    case clipboard // ED16
    case dumbbell01 // EEDB
    case checkmarkBadge01 // ECAE
    case analyticsDown // E9CA
    case barChart // EA88
    case pieChart01 // F4FC
    case grid02 // F060
    case preferenceHorizontal // F573
    case pill // F50B
    case telephone // F90A
    case home01 // F0C9
    case hexagon // F0AC
    case stop // F840
    case walking // FAA6
    case runningShoes // F677
    case child // ECC8
    case messageNotification01 // F329
    case book01 // EB17
    case barcodeScan // EA8B
    case arrowUpRight01 // EA39
    case thumbsUp // F957
    case starCircle // F828
    case smile // F797
    case tongueWinkRight // F98B
    case neutral // F417
    case sad01 // F67C
    case question // F5B7
    case delete01 // EE33
    case aiBrain01 // E941
    case userRemove01 // FA4E
    case userRemove02 // FA4F
    case megaphone01 // F2FC
    case hardDrive // F090
    case task01 // F8F5
    case menu01 // F302

    var scalar: Character {
        switch self {
        case .arrowRight01: return "\u{EA21}"
        case .alert02: return "\u{E999}"
        case .cancelCircle: return "\u{EC13}"
        case .cancel01: return "\u{EC10}"
        case .image01: return "\u{F10F}"
        case .image02: return "\u{F110}"
        case .album02: return "\u{E995}"
        case .search01: return "\u{F6BB}"
        case .arrowLeft01: return "\u{EA11}"
        case .arrowDown01: return "\u{EA00}"
        case .checkmarkCircle01: return "\u{ECB2}"
        case .tick01: return "\u{F959}"
        case .lockPassword: return "\u{F259}"
        case .hourglass: return "\u{F0F0}"
        case .gift: return "\u{F019}"
        case .restaurant02: return "\u{F620}"
        case .crown03: return "\u{EDCB}"
        case .circleArrowUp01: return "\u{ECF4}"
        case .circleArrowDown01: return "\u{ECD8}"
        case .star: return "\u{F82D}"
        case .addCircle: return "\u{E926}"
        case .minusSignCircle: return "\u{F359}"
        case .userAdd01: return "\u{FA31}"
        case .alertCircle: return "\u{E99A}"
        case .mail01: return "\u{F289}"
        case .fileSearch: return "\u{EF69}"
        case .clock03: return "\u{ED19}"
        case .focusPoint: return "\u{EFBB}"
        case .camera01: return "\u{EBF8}"
        case .notificationOff01: return "\u{F44A}"
        case .notification01: return "\u{F442}"
        case .inboxCheck: return "\u{F12B}"
        case .ticket01: return "\u{F961}"
        case .tag01: return "\u{F8DF}"
        case .securityCheck: return "\u{F6CD}"
        case .helpCircle: return "\u{F0A9}"
        case .playCircle: return "\u{F526}"
        case .analytics01: return "\u{E9C7}"
        case .medal01: return "\u{F2E7}"
        case .idea01: return "\u{F10B}"
        case .leaf01: return "\u{F1F7}"
        case .informationCircle: return "\u{F13D}"
        case .globe02: return "\u{F02E}"
        case .fire03: return "\u{EF93}"
        case .creditCard: return "\u{EDC4}"
        case .refresh01: return "\u{F5F8}"
        case .sun03: return "\u{F87A}"
        case .calendar03: return "\u{EBAA}"
        case .flash: return "\u{EFA3}"
        case .flashOff: return "\u{EFA2}"
        case .record: return "\u{F5EB}"
        case .circleArrowReload01: return "\u{ECEC}"
        case .arrowUp01: return "\u{EA2F}"
        case .notification03: return "\u{F444}"
        case .userCircle: return "\u{FA3A}"
        case .shieldKey: return "\u{F719}"
        case .shield02: return "\u{F716}"
        case .favourite: return "\u{EF41}"
        case .quoteDown: return "\u{F5C4}"
        case .droplet: return "\u{EED7}"
        case .file01: return "\u{EF4A}"
        case .copy01: return "\u{ED9E}"
        case .cameraRotated01: return "\u{EC08}"
        case .clipboard: return "\u{ED16}"
        case .dumbbell01: return "\u{EEDB}"
        case .checkmarkBadge01: return "\u{ECAE}"
        case .analyticsDown: return "\u{E9CA}"
        case .barChart: return "\u{EA88}"
        case .pieChart01: return "\u{F4FC}"
        case .grid02: return "\u{F060}"
        case .preferenceHorizontal: return "\u{F573}"
        case .pill: return "\u{F50B}"
        case .telephone: return "\u{F90A}"
        case .home01: return "\u{F0C9}"
        case .hexagon: return "\u{F0AC}"
        case .stop: return "\u{F840}"
        case .walking: return "\u{FAA6}"
        case .runningShoes: return "\u{F677}"
        case .child: return "\u{ECC8}"
        case .messageNotification01: return "\u{F329}"
        case .book01: return "\u{EB17}"
        case .barcodeScan: return "\u{EA8B}"
        case .arrowUpRight01: return "\u{EA39}"
        case .thumbsUp: return "\u{F957}"
        case .starCircle: return "\u{F828}"
        case .smile: return "\u{F797}"
        case .tongueWinkRight: return "\u{F98B}"
        case .neutral: return "\u{F417}"
        case .sad01: return "\u{F67C}"
        case .question: return "\u{F5B7}"
        case .delete01: return "\u{EE33}"
        case .aiBrain01: return "\u{E941}"
        case .userRemove01: return "\u{FA4E}"
        case .userRemove02: return "\u{FA4F}"
        case .megaphone01: return "\u{F2FC}"
        case .hardDrive: return "\u{F090}"
        case .task01: return "\u{F8F5}"
        case .menu01: return "\u{F302}"
        }
    }

    static func fromSF(_ name: String?) -> HugeIconGlyph {
        guard let name, let glyph = sfMap[name] else { return .question }
        return glyph
    }

    private static let sfMap: [String: HugeIconGlyph] = [
        "chevron.right": .arrowRight01,
        "exclamationmark.triangle.fill": .alert02,
        "exclamationmark.triangle": .alert02,
        "xmark.circle.fill": .cancelCircle,
        "xmark.circle": .cancelCircle,
        "xmark": .cancel01,
        "photo": .image01,
        "photo.on.rectangle": .image02,
        "photo.on.rectangle.angled": .album02,
        "magnifyingglass": .search01,
        "chevron.left": .arrowLeft01,
        "chevron.down": .arrowDown01,
        "checkmark.circle.fill": .checkmarkCircle01,
        "checkmark.circle": .checkmarkCircle01,
        "checkmark": .tick01,
        "lock.fill": .lockPassword,
        "hourglass": .hourglass,
        "hourglass.circle.fill": .hourglass,
        "gift.fill": .gift,
        "gift": .gift,
        "fork.knife": .restaurant02,
        "crown.fill": .crown03,
        "arrow.up.circle.fill": .circleArrowUp01,
        "arrow.down.circle.fill": .circleArrowDown01,
        "star.fill": .star,
        "plus.circle.fill": .addCircle,
        "minus.circle.fill": .minusSignCircle,
        "person.crop.circle.badge.plus": .userAdd01,
        "exclamationmark.circle.fill": .alertCircle,
        "exclamationmark.circle": .alertCircle,
        "envelope.fill": .mail01,
        "envelope.circle.fill": .mail01,
        "doc.text.magnifyingglass": .fileSearch,
        "clock.arrow.circlepath": .clock03,
        "camera.viewfinder": .focusPoint,
        "camera.fill": .camera01,
        "bell.slash": .notificationOff01,
        "bell": .notification01,
        "tray": .inboxCheck,
        "ticket.fill": .ticket01,
        "tag.fill": .tag01,
        "shield.checkmark": .securityCheck,
        "questionmark.folder": .image01,
        "questionmark.circle.fill": .helpCircle,
        "questionmark.circle": .helpCircle,
        "play.circle.fill": .playCircle,
        "monitoring": .analytics01,
        "military_tech": .medal01,
        "lightbulb.fill": .idea01,
        "leaf.fill": .leaf01,
        "info.circle.fill": .informationCircle,
        "globe": .globe02,
        "flame.fill": .fire03,
        "creditcard.and.123": .creditCard,
        "arrow.triangle.2.circlepath.circle.fill": .refresh01,
        "arrow.triangle.2.circlepath": .refresh01,
        "arrow.forward": .arrowRight01,
        "arrow.down": .arrowDown01,
        "sun.max.fill": .sun03,
        "calendar.badge.clock": .calendar03,
        "calendar.badge.exclamationmark": .calendar03,
        "bolt.fill": .flash,
        "bolt.slash.fill": .flashOff,
        "circle": .record,
        "arrow.counterclockwise.circle": .circleArrowReload01,
        "chevron.up": .arrowUp01,
        "chevron.up.circle.fill": .circleArrowUp01,
        "chevron.down.circle.fill": .circleArrowDown01,
        "bell.fill": .notification01,
        "bell.badge": .notification03,
        "info.circle": .informationCircle,
        "person.fill": .userCircle,
        "person.crop.circle": .userCircle,
        "user.unnamed": .userCircle,
        "lock.shield": .shieldKey,
        "xmark.shield.fill": .shield02,
        "shield02": .shield02,
        "hand.raised.fill": .stop,
        "exclamationmark.shield.fill": .shield02,
        "heart.fill": .favourite,
        "heart.circle.fill": .favourite,
        "heart.text.square.fill": .favourite,
        "text.quote": .quoteDown,
        "leaf.circle": .leaf01,
        "drop.fill": .droplet,
        "doc.text.fill": .file01,
        "doc.text": .file01,
        "doc.on.doc": .copy01,
        "camera.rotate": .cameraRotated01,
        "minus.circle": .minusSignCircle,
        "list.bullet.clipboard.fill": .clipboard,
        "frying.pan.fill": .restaurant02,
        "dumbbell.fill": .dumbbell01,
        "checkmark.seal.fill": .checkmarkBadge01,
        "chart.line.downtrend.xyaxis": .analyticsDown,
        "chart.line.uptrend.xyaxis": .analytics01,
        "chart.bar.fill": .barChart,
        "chart.bar": .barChart,
        "chart.pie": .pieChart01,
        "square.grid.2x2": .grid02,
        "slider.horizontal.3": .preferenceHorizontal,
        "pill.fill": .pill,
        "phone.fill": .telephone,
        "house.fill": .home01,
        "hexagon.fill": .hexagon,
        "hand.raised": .stop,
        "figure.walk.circle.fill": .walking,
        "figure.run.fill": .runningShoes,
        "figure.child.circle": .child,
        "exclamationmark.bubble": .messageNotification01,
        "book.closed.fill": .book01,
        "barcode.viewfinder": .barcodeScan,
        "arrow.up.right.square": .arrowUpRight01,
        "arrow.clockwise.icloud.fill": .refresh01,
        "arrow.clockwise": .refresh01,
        "thumbsup.fill": .thumbsUp,
        "star.circle": .starCircle,
        "star.bubble": .star,
        "star": .star,
        "trash": .delete01,
        "brain.head.profile": .aiBrain01,
        "creditcard": .creditCard,
        "lightbulb": .idea01,
        "list.bullet": .menu01,
        "list.number": .task01,
        "arrow.triangle.2.circlepath.circle": .circleArrowReload01,
        "internaldrive": .hardDrive,
        "megaphone": .megaphone01,
        "person.crop.circle.badge.minus": .userRemove01,
        "person.crop.circle.badge.xmark": .userRemove02,
        "receipt": .file01,
        "ticket": .ticket01,
        "square.stack.3d.up.slash": .file01,
    ]
}

extension HugeIconGlyph {
    static func forAdviceLevel(_ level: String?) -> HugeIconGlyph {
        switch level {
        // AdviceLevel 词表
        case "recommended": return .tongueWinkRight
        case "moderate": return .smile
        case "caution": return .neutral
        case "avoid": return .sad01
        // RecommendationLevel 词表（AI 评估可能原样透传）
        case "excellent": return .tongueWinkRight
        case "good", "suitable": return .smile
        default:
            #if DEBUG
            print("[HugeIcon] adviceLevel 未映射 → question: \(level ?? "nil")")
            #endif
            return .question
        }
    }
}

struct HugeIcon: View {
    let glyph: HugeIconGlyph
    var size: CGFloat = 16
    var stroke: Bool = false

    init(glyph: HugeIconGlyph, size: CGFloat = 16, stroke: Bool = false) {
        self.glyph = glyph
        self.size = size
        self.stroke = stroke
    }

    init(sf name: String?, size: CGFloat = 16, stroke: Bool = false) {
        self.glyph = HugeIconGlyph.fromSF(name)
        self.size = size
        self.stroke = stroke
    }

    var body: some View {
        Text(String(glyph.scalar))
            .font(Font.custom(
                stroke ? SafeMealFont.activeHugeIconsStrokeFontName : SafeMealFont.activeHugeIconsSolidFontName,
                size: size * 1.2
            ))
    }
}

/// 勾选圆圈：选中=描边圆+勾，未选中=空心圆（描边风格，全局统一）
struct CheckCircle: View {
    let isOn: Bool
    var size: CGFloat = 18

    var body: some View {
        // 选中=fill 实心勾圈；未选中=描边空心圆
        HugeIcon(glyph: isOn ? .checkmarkCircle01 : .record, size: size, stroke: !isOn)
    }
}

/// 关闭所在 ScrollView 的回弹（bounces=false）：挂在 ScrollView 内容上即可
/// 用于结果页顶部下拉不再露空白
struct DisableScrollBounce: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView { UIView() }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            var sv = uiView.superview
            while let v = sv {
                if let scroll = v as? UIScrollView {
                    scroll.bounces = false
                    break
                }
                sv = v.superview
            }
        }
    }
}
