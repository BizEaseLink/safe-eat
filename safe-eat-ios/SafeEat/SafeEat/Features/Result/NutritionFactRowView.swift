import SwiftUI

// MARK: - 营养素行视图（两行布局）

/// 有分量的营养素行：
/// ```
/// 蛋白质                  23g
///                       38% NRV
/// ████████░░░░░░░░░░░░░░░░░░
/// ```

struct NutritionFactRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let name: String
    let value: Double?
    let unit: String?
    let nrvPercent: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text(name)
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    if let value, let unit {
                        HStack(spacing: 2) {
                            Text(String(format: "%.1f", value))
                                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                                .foregroundStyle(SafeEatTheme.textPrimary)
                            Text(unit)
                                .font(SafeEatFont.custom(12, relativeTo: .caption))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                    } else {
                        Text("--")
                            .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }

                    if let nrv = nrvPercent {
                        Text(String(format: "%.0f%% NRV", nrv))
                            .font(SafeEatFont.custom(11, relativeTo: .caption2))
                            .foregroundStyle(nrvColor(nrv))
                    } else {
                        Text("- NRV")
                            .font(SafeEatFont.custom(11, relativeTo: .caption2))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                }
            }

            nrvProgressBar(nrvPercent ?? 0)
                .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    private func nrvProgressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5))
                if value > 0 {
                    Capsule()
                        .fill(nrvColor(value))
                        .frame(width: geo.size.width * max(0, min(CGFloat(value) / 100.0, 1.0)))
                }
            }
        }
    }
}

// MARK: - NRV 颜色映射

extension NutritionFactRowView {
    func nrvColor(_ value: Double) -> Color {
        if value <= 5 { return SafeEatTheme.textSecondary }
        if value <= 20 { return SafeEatTheme.primary }
        if value <= 50 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }
}

// MARK: - 只有 NRV 的营养素行（维生素/矿物质从 NutrientValue.dailyValuePercent 读取）

struct NRVOnlyRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let name: String
    let nrvPercent: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Spacer()

                if let nrv = nrvPercent {
                    Text(String(format: "%.0f%% NRV", nrv))
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(nrvColor(nrv))
                } else {
                    Text("- NRV")
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
            }

            nrvProgressBar(nrvPercent ?? 0)
                .frame(height: 6)
        }
        .padding(.vertical, 4)
    }

    private func nrvProgressBar(_ value: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color(.systemGray5))
                if value > 0 {
                    Capsule()
                        .fill(nrvColor(value))
                        .frame(width: geo.size.width * max(0, min(CGFloat(value) / 100.0, 1.0)))
                }
            }
        }
    }

    private func nrvColor(_ value: Double) -> Color {
        if value <= 5 { return SafeEatTheme.textSecondary }
        if value <= 20 { return SafeEatTheme.primary }
        if value <= 50 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }
}

// MARK: - 过敏原翻译映射

let AllergenNameMap: [String: (zh: String, en: String)] = [
    // 后端 ALLERGEN_I18N 标准 key（Codex/EU 命名）
    "milk":        ("牛奶", "Milk"),
    "eggs":        ("鸡蛋", "Eggs"),
    "egg":         ("鸡蛋", "Egg"),
    "fish":        ("鱼", "Fish"),
    "crustaceans": ("甲壳类", "Crustaceans"),
    "crustacean":  ("甲壳类", "Crustacean"),
    "molluscs":    ("贝类", "Molluscs"),
    "shellfish":   ("贝类", "Shellfish"),
    "peanuts":     ("花生", "Peanuts"),
    "peanut":      ("花生", "Peanut"),
    "tree_nuts":   ("坚果", "Tree Nuts"),
    "treeNut":     ("坚果", "Tree Nut"),
    "soybeans":    ("大豆", "Soybeans"),
    "soy":         ("大豆", "Soy"),
    "wheat":       ("含小麦/麸质", "Wheat/Gluten"),
    "gluten":      ("麸质", "Gluten"),
    "sesame":      ("芝麻", "Sesame"),
    // 后端种子数据和规则推导中使用的额外 key
    "pork":        ("猪肉", "Pork"),
    "beef":        ("牛肉", "Beef"),
    "chicken":     ("鸡肉", "Chicken"),
    "lamb":        ("羊肉", "Lamb"),
    "lactose":     ("乳糖", "Lactose"),
    "mustard":     ("芥末", "Mustard"),
    "celery":      ("芹菜", "Celery"),
    "sulfite":     ("亚硫酸盐", "Sulfite"),
    "nitrite":     ("亚硝酸盐", "Nitrite"),
]

func localizedAllergenName(_ key: String) -> String {
    if let mapping = AllergenNameMap[key.lowercased()] {
        let storedLang = UserDefaults.standard.string(forKey: "safeeat.settings.language")
        switch storedLang {
        case "zh-Hans": return mapping.zh
        case "en": return mapping.en
        default: return Locale.preferredLanguages.first?.hasPrefix("zh") == true ? mapping.zh : mapping.en
        }
    }
    return key.capitalized
}

// MARK: - C3: NRV key 分类常量

enum NRVKeyClassification {
    static let macroKeys: Set<String> = [
        "calories", "protein",
        "fat",
        "carbohydrates",
        "sodium", "cholesterol",
        "saturatedFat", "transFat",
        "dietaryFiber",
        "sugars", "addedSugars",
    ]

    static let vitaminKeys: Set<String> = [
        "vitaminA", "vitaminC", "vitaminD", "vitaminE", "vitaminK",
        "vitaminB1", "thiamin",
        "vitaminB2", "riboflavin",
        "vitaminB3", "niacin",
        "vitaminB5", "pantothenicAcid",
        "vitaminB6",
        "vitaminB9", "folate",
        "vitaminB12",
        "biotin", "choline",
    ]

    static let mineralKeys: Set<String> = [
        "calcium", "iron", "magnesium", "phosphorus", "potassium",
        "zinc", "copper", "manganese", "selenium", "chromium",
        "molybdenum", "fluoride", "iodine",
    ]

    static let vitaminNameMap: [String: String] = [
        "vitaminA": "result.vit.a",
        "vitaminC": "result.vit.c",
        "vitaminD": "result.vit.d",
        "vitaminE": "result.vit.e",
        "vitaminK": "result.vit.k",
        "vitaminB1": "result.vit.b1",
        "thiamin": "result.vit.b1",
        "vitaminB2": "result.vit.b2",
        "riboflavin": "result.vit.b2",
        "vitaminB3": "result.vit.b3",
        "niacin": "result.vit.b3",
        "vitaminB5": "result.vit.b5",
        "pantothenicAcid": "result.vit.b5",
        "vitaminB6": "result.vit.b6",
        "vitaminB9": "result.vit.b9",
        "folate": "result.vit.b9",
        "vitaminB12": "result.vit.b12",
        "biotin": "result.vit.biotin",
        "choline": "result.vit.choline",
    ]

    static let mineralNameMap: [String: String] = [
        "calcium": "result.mineral.calcium",
        "iron": "result.mineral.iron",
        "magnesium": "result.mineral.magnesium",
        "phosphorus": "result.mineral.phosphorus",
        "potassium": "result.mineral.potassium",
        "zinc": "result.mineral.zinc",
        "copper": "result.mineral.copper",
        "manganese": "result.mineral.manganese",
        "selenium": "result.mineral.selenium",
        "chromium": "result.mineral.chromium",
        "molybdenum": "result.mineral.molybdenum",
        "fluoride": "result.mineral.fluoride",
        "iodine": "result.mineral.iodine",
    ]

    static let allClassifiedKeys: Set<String> = macroKeys.union(vitaminKeys).union(mineralKeys)
}
