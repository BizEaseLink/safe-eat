import SwiftUI
import UIKit

struct FeedbackView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let recognition: RecognitionRecord
    let historyItem: LocalHistoryItem

    @State private var proposedName = ""
    @State private var comment = ""
    @State private var selectedFeedbackType: FeedbackType?
    @State private var replacementImage: UIImage?
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showSourceDialog = false
    @State private var showImagePicker = false
    @State private var submitting = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var searchResults: [FoodSearchItem] = []
    @State private var isSearching = false
    @State private var showSuccess = false
    @State private var submitError: String?
    @State private var nutritionRows: [NutritionEditRow] = []
    @State private var feedbackMeta: SafeEatAPI.FeedbackMeta?

    private var displayName: String {
        let rawName = recognition.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if rawName.isEmpty || rawName == "未知食物" {
            return SafeEatL10n.text(L10nKey.Common.unknownFood)
        }
        return rawName
    }

    private var currentPreviewImage: UIImage? {
        replacementImage
            ?? LocalImageLoader.loadStickerImage(for: historyItem)
            ?? LocalImageLoader.loadDisplayImage(for: historyItem)
    }

    private var trimmedProposedName: String {
        proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSubmit: Bool {
        !submitting && !trimmedProposedName.isEmpty
    }

    private var suggestionCandidates: [String] {
        // 食物库搜索结果，排除当前名称和输入值，最多3个
        let filtered = searchResults.map(\.name).filter { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmed.isEmpty
                && trimmed != displayName
                && trimmed != trimmedProposedName
                && trimmed != SafeEatL10n.text(L10nKey.Common.unknownFood)
        }
        return Array(filtered.prefix(3))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                pageBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        SafeEatGlobalScrollOffsetReader(
                            scrollOffset: $scrollOffset
                        )
                        .id(recognition.id)

                        Color.clear
                            .frame(height: proxy.safeAreaInsets.top + 74)

                        statusTag

                        heroSection

                        feedbackTypeSection

                        correctionZone

                        commentSection

                        auditNoteCard

                        submitButton

                        if let submitError {
                            Text(submitError)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote))
                                .foregroundStyle(SafeEatTheme.danger)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .transition(.opacity)
                        }

                        thanksFootnote

                        Color.clear
                            .frame(height: keyboardBottomSpacing(bottomInset: proxy.safeAreaInsets.bottom))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }

                SafeEatTopBackChrome(
                    title: SafeEatL10n.text(L10nKey.Feedback.title),
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top,
                    onBack: { dismiss() }
                )

                if showSuccess {
                    successOverlay
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            
            .ignoresSafeArea()
            .onTapGesture {
                isCommentFocused = false
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if proposedName.isEmpty {
                let initial = recognition.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
                proposedName = initial == "未知食物" ? "" : initial
            }
            // 拉取过敏原/饮食标签可选项（后台规则表，前后端一致）
            if feedbackMeta == nil {
                Task {
                    do {
                        let meta = try await store.authorizedRequest { token in
                            try await store.api.getFeedbackMeta(accessToken: token)
                        }
                        await MainActor.run { feedbackMeta = meta }
                    } catch {
                        // 拉取失败不阻断：过敏原/饮食标签区为空
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            updateKeyboardHeight(with: notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                keyboardHeight = 0
            }
        }
        .onChange(of: comment) { _, newValue in
            if newValue.count > 200 {
                comment = String(newValue.prefix(200))
            }
        }
        .confirmationDialog(SafeEatL10n.text(L10nKey.Feedback.replaceEvidenceTitle), isPresented: $showSourceDialog, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button(SafeEatL10n.text(L10nKey.Feedback.sourceCamera)) {
                    pickerSource = .camera
                    showImagePicker = true
                }
            }

            Button(SafeEatL10n.text(L10nKey.Feedback.sourceLibrary)) {
                pickerSource = .photoLibrary
                showImagePicker = true
            }

            Button(SafeEatL10n.text(L10nKey.Common.cancel), role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSource) { image in
                replacementImage = image
            }
        }
    }

    private var pageBackground: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.12, green: 0.13, blue: 0.15),
                        Color(red: 0.09, green: 0.10, blue: 0.12),
                    ]
                    : [
                        Color(red: 0.99, green: 0.995, blue: 0.99),
                        Color(red: 0.965, green: 0.978, blue: 0.968),
                    ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.15 : 0.52),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 18,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.91, blue: 0.78).opacity(colorScheme == .dark ? 0.08 : 0.30),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 280
            )
        }
    }

    private var statusTag: some View {
        Text(SafeEatL10n.text(L10nKey.Feedback.status))
            .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
            .foregroundStyle(SafeEatTheme.warning)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.18 : 0.12))
            )
            .overlay(
                Capsule()
                    .stroke(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.26 : 0.18), lineWidth: 1)
            )
    }

    private var feedbackTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SafeEatL10n.text(L10nKey.Feedback.typeTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FeedbackType.selectableCases) { type in
                        let isSelected = selectedFeedbackType == type
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFeedbackType = isSelected ? nil : type
                                // 切换类型时清空已选修改项（避免残留行串到新类型）
                                nutritionRows.removeAll()
                            }
                        } label: {
                            Text(type.displayName)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                                .foregroundStyle(isSelected ? .white : SafeEatTheme.primaryDeep)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected
                                             ? AnyShapeStyle(LinearGradient(
                                                colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing))
                                             : AnyShapeStyle(colorScheme == .dark
                                                ? Color.white.opacity(0.08)
                                                : SafeEatTheme.primarySoft.opacity(0.72)))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text(SafeEatL10n.text(L10nKey.Feedback.typeHint))
                .font(SafeEatFont.custom(13, relativeTo: .caption))
                .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.7))
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SafeEatL10n.text(L10nKey.Feedback.heroTitle))
                .font(SafeEatFont.custom(36, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            Text(SafeEatL10n.text(L10nKey.Feedback.heroSubtitle))
                .font(SafeEatFont.custom(34, relativeTo: .largeTitle, weight: .bold))
                .foregroundStyle(SafeEatTheme.primary)

            Text(SafeEatL10n.text(L10nKey.Feedback.heroBody))
                .font(SafeEatFont.custom(17, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textSecondary)
        }
    }

    private var correctionZone: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentRecognitionCard

            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.08)
                                  : Color.white.opacity(0.82))
                    )
                Spacer()
            }

            if selectedFeedbackType == .wrongNutrition || selectedFeedbackType == .wrongTags {
                nutritionCheckSection
            } else {
                correctionCard
            }
        }
    }

    private var nutrientCheckRows: [(key: String, label: String, current: String)] {
        let n = recognition.nutritionMetrics?.nutrients
        return [
            ("calories", "热量", n?.calories),
            ("protein", "蛋白质", n?.protein),
            ("fat", "脂肪", n?.fat),
            ("carbohydrates", "碳水化合物", n?.carbohydrates),
            ("sugars", "糖", n?.sugar),
            ("sodium", "钠", n?.sodium),
            ("dietaryFiber", "膳食纤维", n?.dietaryFiber),
        ].map { (key: $0.0, label: $0.1, current: $0.2.map { "\($0.value) \($0.unit)" } ?? "—") }
    }

    /// 一条待修正的营养/标签项（选中后生成，含修改前当前值）
    struct NutritionEditRow: Identifiable {
        let id: String
        let path: [String]
        let label: String
        let beforeText: String
        var afterText: String
        let kind: Kind
        /// 原值单位（数值项：右侧只读显示，用户只输数字）
        let unit: String?

        enum Kind { case number, boolean, text }
    }

    /// 营养项中文标签（L10n，双语）
    private func localizedLabel(for key: String) -> String {
        let L = L10nKey.Feedback.self
        switch key {
        case "calories": return SafeEatL10n.text(L.nutritionCalories)
        case "protein": return SafeEatL10n.text(L.nutritionProtein)
        case "fat": return SafeEatL10n.text(L.nutritionFat)
        case "saturatedFat": return SafeEatL10n.text(L.nutritionSaturatedFat)
        case "transFat": return SafeEatL10n.text(L.nutritionTransFat)
        case "carbohydrates": return SafeEatL10n.text(L.nutritionCarbohydrates)
        case "dietaryFiber": return SafeEatL10n.text(L.nutritionDietaryFiber)
        case "cholesterol": return SafeEatL10n.text(L.nutritionCholesterol)
        case "sodium": return SafeEatL10n.text(L.nutritionSodium)
        case "vitaminA": return SafeEatL10n.text(L.nutritionVitaminA)
        case "thiamin": return SafeEatL10n.text(L.nutritionThiamin)
        case "riboflavin": return SafeEatL10n.text(L.nutritionRiboflavin)
        case "niacin": return SafeEatL10n.text(L.nutritionNiacin)
        case "pantothenicAcid": return SafeEatL10n.text(L.nutritionPantothenicAcid)
        case "vitaminB6": return SafeEatL10n.text(L.nutritionVitaminB6)
        case "vitaminB12": return SafeEatL10n.text(L.nutritionVitaminB12)
        case "vitaminC": return SafeEatL10n.text(L.nutritionVitaminC)
        case "vitaminD": return SafeEatL10n.text(L.nutritionVitaminD)
        case "vitaminE": return SafeEatL10n.text(L.nutritionVitaminE)
        case "vitaminK": return SafeEatL10n.text(L.nutritionVitaminK)
        case "folate": return SafeEatL10n.text(L.nutritionFolate)
        case "biotin": return SafeEatL10n.text(L.nutritionBiotin)
        case "choline": return SafeEatL10n.text(L.nutritionCholine)
        case "calcium": return SafeEatL10n.text(L.nutritionCalcium)
        case "iron": return SafeEatL10n.text(L.nutritionIron)
        case "magnesium": return SafeEatL10n.text(L.nutritionMagnesium)
        case "phosphorus": return SafeEatL10n.text(L.nutritionPhosphorus)
        case "potassium": return SafeEatL10n.text(L.nutritionPotassium)
        case "zinc": return SafeEatL10n.text(L.nutritionZinc)
        case "selenium": return SafeEatL10n.text(L.nutritionSelenium)
        case "iodine": return SafeEatL10n.text(L.nutritionIodine)
        case "copper": return SafeEatL10n.text(L.nutritionCopper)
        case "manganese": return SafeEatL10n.text(L.nutritionManganese)
        case "glycemicIndex": return SafeEatL10n.text(L.nutritionGlycemicIndex)
        case "glycemicLoad": return SafeEatL10n.text(L.nutritionGlycemicLoad)
        case "contains": return SafeEatL10n.text(L.nutritionAllergens)
        default: return key
        }
    }

    /// 分区标题（与结果页 S 分区一致，L10n 双语）
    private func sectionTitle(for section: String) -> String {
        let R = L10nKey.Result.self
        switch section {
        case "s1": return SafeEatL10n.text(R.sectionMacronutrients)
        case "s2": return SafeEatL10n.text(R.sectionDetailedNutrients)
        case "s3": return SafeEatL10n.text(R.sectionVitamins)
        case "s4": return SafeEatL10n.text(R.sectionMinerals)
        case "s6": return SafeEatL10n.text(R.sectionGlycemic)
        case "s7": return SafeEatL10n.text(R.allergenTitle)
        case "s8": return SafeEatL10n.text(R.sectionDietary)
        default: return section
        }
    }

    /// 当前营养 JSON 树（NutritionMetrics 编码回后端形态：amount/sugars 等键名）
    private var metricsTree: [String: Any]? {
        guard let metrics = recognition.nutritionMetrics,
              let data = try? JSONEncoder().encode(metrics)
        else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    struct NutritionFieldItem {
        let section: String
        let path: [String]
        let label: String
        let before: String
        let kind: NutritionEditRow.Kind
        let unit: String?
    }

    /// 展示标签：叶子是 amount（值字段）时用父级营养键，否则用叶子键
    private func displayLabel(forPath path: [String], leafKey: String) -> String {
        if leafKey == "amount" && path.count >= 2 {
            return localizedLabel(for: path[path.count - 2])
        }
        return localizedLabel(for: leafKey)
    }

    /// S 分区（与结果页一致）：s1 基础营养素 / s2 详细 / s3 维生素 / s4 矿物质 / s6 血糖
    private func sectionKey(forPath path: [String]) -> String {
        let head = path.first ?? "other"
        switch head {
        case "nutrients":
            let key = path.count >= 2 ? path[1] : ""
            switch key {
            case "calories", "protein", "fat", "carbohydrates", "sodium", "dietaryFiber":
                return "s1"
            case "saturatedFat", "transFat", "cholesterol", "addedSugars":
                return "s2"
            default:
                return "s1"
            }
        case "vitamins": return "s3"
        case "minerals": return "s4"
        case "glycemicInfo": return "s6"
        case "dietaryInfo": return "s8"
        case "allergens": return "s7"
        default: return "other"
        }
    }

    /// 可选择的营养字段（wrong_nutrition）：S1-S4/S6，与结果页同分区；跳过嵌套 vitamins/minerals（防重叠）
    private var selectableNutritionItems: [NutritionFieldItem] {
        let tree = metricsTree ?? [:]
        var out: [NutritionFieldItem] = []
        func walk(_ obj: [String: Any], _ path: [String]) {
            for (key, value) in obj {
                if ["source", "unit", "nrv", "nrvPercent", "cookingMethod", "sugars", "dietaryInfo", "allergens"].contains(key) { continue }
                // 重叠修复：nutrients 下的嵌套 vitamins/minerals（v3 兼容）跳过，只走顶层
                if path.first == "nutrients" && (key == "vitamins" || key == "minerals") { continue }
                let newPath = path + [key]
                if let dict = value as? [String: Any] {
                    walk(dict, newPath)
                } else if let arr = value as? [Any] {
                    let joined = arr.map { "\($0)" }.joined(separator: "、")
                    out.append(NutritionFieldItem(section: sectionKey(forPath: newPath), path: newPath, label: displayLabel(forPath: newPath, leafKey: key), before: joined, kind: .text, unit: nil))
                } else if let flag = value as? Bool {
                    out.append(NutritionFieldItem(section: sectionKey(forPath: newPath), path: newPath, label: displayLabel(forPath: newPath, leafKey: key), before: flag ? SafeEatL10n.text(L10nKey.Feedback.nutritionYes) : SafeEatL10n.text(L10nKey.Feedback.nutritionNo), kind: .boolean, unit: nil))
                } else if let num = value as? Double {
                    // 值字段：带单位（读兄弟 unit）
                    let unit = obj["unit"] as? String ?? ""
                    let beforeText = unit.isEmpty ? formatNumber(num) : "\(formatNumber(num)) \(unit)"
                    out.append(NutritionFieldItem(section: sectionKey(forPath: newPath), path: newPath, label: displayLabel(forPath: newPath, leafKey: key), before: beforeText, kind: .number, unit: unit.isEmpty ? nil : unit))
                } else if let str = value as? String {
                    out.append(NutritionFieldItem(section: sectionKey(forPath: newPath), path: newPath, label: displayLabel(forPath: newPath, leafKey: key), before: str, kind: .text, unit: nil))
                }
            }
        }
        walk(tree, [])
        return out
    }

    /// 可选择的标签字段（wrong_tags）：饮食标签（meta 驱动，反显当前值）+ 过敏原（一条 contains）
    private var selectableTagItems: [NutritionFieldItem] {
        let tree = metricsTree ?? [:]
        let dietaryTags = feedbackMeta?.dietaryTags ?? fallbackDietaryTags
        let allergenItems = feedbackMeta?.allergens ?? fallbackAllergens
        var out: [NutritionFieldItem] = []
        if !dietaryTags.isEmpty {
            let dietaryInfo = tree["dietaryInfo"] as? [String: Any] ?? [:]
            for item in dietaryTags {
                let cur = dietaryInfo[item.key] as? Bool
                let beforeText = cur.map { $0 ? SafeEatL10n.text(L10nKey.Feedback.nutritionYes) : SafeEatL10n.text(L10nKey.Feedback.nutritionNo) } ?? "—"
                out.append(NutritionFieldItem(section: "s8", path: ["dietaryInfo", item.key], label: metaLabel(item), before: beforeText, kind: .boolean, unit: nil))
            }
        }
        if !allergenItems.isEmpty {
            let contains = (tree["allergens"] as? [String: Any])?["contains"] as? [Any] ?? []
            let beforeJoined = contains.map { "\($0)" }.joined(separator: "、")
            out.append(NutritionFieldItem(section: "s7", path: ["allergens", "contains"], label: SafeEatL10n.text(L10nKey.Feedback.nutritionAllergens), before: beforeJoined, kind: .text, unit: nil))
        }
        return out
    }

    /// meta 项的双语标签（zh/en 按当前语言）
    private func metaLabel(_ item: SafeEatAPI.FeedbackMetaItem) -> String {
        let storedLang = UserDefaults.standard.string(forKey: "safeeat.settings.language")
        switch storedLang {
        case "en": return item.en
        default: return item.zh
        }
    }

    /// 过敏原 key → 双语标签（后台 meta，前后端一致）
    private func allergenLabel(for key: String) -> String {
        if let item = feedbackMeta?.allergens.first(where: { $0.key == key }) {
            return metaLabel(item)
        }
        return key
    }

    private func formatNumber(_ v: Double) -> String {
        v == v.rounded() && abs(v) < 1_000_000 ? String(Int(v)) : String(format: "%.2f", v)
    }

    private func addNutritionRow(_ item: NutritionFieldItem) {
        let id = item.path.joined(separator: ".")
        guard !nutritionRows.contains(where: { $0.id == id }) else { return }
        nutritionRows.append(NutritionEditRow(
            id: id, path: item.path, label: item.label,
            beforeText: item.before, afterText: item.before, kind: item.kind, unit: item.unit
        ))
    }

    /// 过敏原可选项（后台 meta；未加载时兜底列表，key 与后台规则表一致）
    private var allergenOptions: [String] {
        (feedbackMeta?.allergens ?? fallbackAllergens).map(\.key)
    }

    /// 兜底过敏原（与 ingredient_allergen_rules 标准 key 一致；双语标签）
    private var fallbackAllergens: [SafeEatAPI.FeedbackMetaItem] {
        let pairs: [(String, String, String)] = [
            ("milk", "Milk", "牛奶"), ("eggs", "Eggs", "鸡蛋"), ("fish", "Fish", "鱼"),
            ("crustaceans", "Crustaceans", "甲壳类"), ("molluscs", "Molluscs", "贝类"),
            ("peanuts", "Peanuts", "花生"), ("tree_nuts", "Tree Nuts", "坚果"),
            ("soybeans", "Soybeans", "大豆"), ("wheat", "Wheat/Gluten", "含小麦/麸质"),
            ("gluten", "Gluten", "麸质"), ("sesame", "Sesame", "芝麻"),
        ]
        return pairs.map { SafeEatAPI.FeedbackMetaItem(key: $0.0, en: $0.1, zh: $0.2) }
    }

    /// 兜底饮食标签（与 ingredient_dietary_rules 标准 key 一致；双语标签）
    private var fallbackDietaryTags: [SafeEatAPI.FeedbackMetaItem] {
        let L = L10nKey.Feedback.self
        let keys: [(String, String, String)] = [
            ("isVegetarian", "Vegetarian", SafeEatL10n.text(L.nutritionDietVegetarian)),
            ("isVegan", "Vegan", SafeEatL10n.text(L.nutritionDietVegan)),
            ("isGlutenFree", "Gluten-Free", SafeEatL10n.text(L.nutritionDietGlutenFree)),
            ("isLactoseFree", "Lactose-Free", SafeEatL10n.text(L.nutritionDietLactoseFree)),
            ("isHalal", "Halal", SafeEatL10n.text(L.nutritionDietHalal)),
            ("isBuddhistStrict", "Buddhist", SafeEatL10n.text(L.nutritionDietBuddhist)),
            ("isDairyFree", "Dairy-Free", SafeEatL10n.text(L.nutritionDietDairyFree)),
            ("isNutFree", "Nut-Free", SafeEatL10n.text(L.nutritionDietNutFree)),
            ("isLowFodmap", "Low-FODMAP", SafeEatL10n.text(L.nutritionDietLowFodmap)),
        ]
        return keys.map { SafeEatAPI.FeedbackMetaItem(key: $0.0, en: $0.1, zh: $0.2) }
    }

    private func isAllergenEditRow(_ row: NutritionEditRow) -> Bool {
        row.path == ["allergens", "contains"] || row.path == ["allergens", "mayContain"]
    }

    /// 过敏原多选 chips：选中集合存放在 afterText（、分隔），提交时还原为数组
    private func toggleAllergen(_ row: Binding<NutritionEditRow>, key: String) {
        let selected = Set(row.wrappedValue.afterText.split(separator: "、").map(String.init))
        var next = selected
        if next.contains(key) { next.remove(key) } else { next.insert(key) }
        row.wrappedValue.afterText = allergenOptions.filter { next.contains($0) }.joined(separator: "、")
    }

    private var nutritionMenuGroups: [(title: String, items: [NutritionFieldItem])] {
        let source = selectedFeedbackType == .wrongTags ? selectableTagItems : selectableNutritionItems
        let order = ["s1", "s2", "s3", "s4", "s6", "s7", "s8"]
        return order.compactMap { key in
            let grouped = source.filter { $0.section == key }
            return grouped.isEmpty ? nil : (title: sectionTitle(for: key), items: grouped)
        }
    }

    private func setPath(_ path: [String], _ value: Any, in tree: inout [String: Any]) {
        guard let head = path.first else { return }
        if path.count == 1 {
            tree[head] = value
            return
        }
        var child = tree[head] as? [String: Any] ?? [:]
        setPath(Array(path.dropFirst()), value, in: &child)
        tree[head] = child
    }

    /// 营养核对区：先选择要修改的项，选中后在下方生成 修改前/修改后 行（可多选一起提交）
    private var nutritionCheckSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Menu {
                ForEach(nutritionMenuGroups, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.items, id: \.path) { item in
                            Button(item.label) { addNutritionRow(item) }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("选择要修改的营养项")
                }
                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                .foregroundStyle(SafeEatTheme.primaryDeep)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                )
            }

            if nutritionRows.isEmpty {
                Text("尚未选择修改项；选择后在下方填写修改后内容，可多选一起提交。")
                    .font(SafeEatFont.custom(14, relativeTo: .footnote))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.75))
            }

            ForEach($nutritionRows) { $row in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(row.label)
                            .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                            .foregroundStyle(SafeEatTheme.textPrimary)
                        Spacer()
                        Button {
                            nutritionRows.removeAll { $0.id == row.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }

                    // 左右两套逻辑：改前（只读胶囊）+ 改后（输入胶囊，参考编辑资料圆角样式）
                    HStack(alignment: .top, spacing: 10) {
                        // 改前胶囊（只读，删除线原值）
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SafeEatL10n.text(L10nKey.Feedback.nutritionBefore))
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            Text(isAllergenEditRow(row)
                                 ? row.beforeText.split(separator: "、").map { allergenLabel(for: String($0)) }.joined(separator: "、")
                                 : row.beforeText)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .semibold))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                                .lineLimit(2)
                                .strikethrough(true, color: SafeEatTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 56)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : SafeEatTheme.primarySoft.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SafeEatTheme.line, lineWidth: 1)
                        )

                        // 改后胶囊（可输入）
                        VStack(alignment: .leading, spacing: 4) {
                            Text(SafeEatL10n.text(L10nKey.Feedback.nutritionAfter))
                                .font(SafeEatFont.custom(11, relativeTo: .caption2))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                            if row.kind == .boolean {
                                Picker("", selection: $row.afterText) {
                                    Text(SafeEatL10n.text(L10nKey.Feedback.nutritionYes)).tag("true")
                                    Text(SafeEatL10n.text(L10nKey.Feedback.nutritionNo)).tag("false")
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: .infinity)
                            } else if isAllergenEditRow(row) {
                                // 过敏原：多选 chips
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 6)], alignment: .leading, spacing: 6) {
                                    ForEach(allergenOptions, id: \.self) { key in
                                        let isSelected = row.afterText.split(separator: "、").map(String.init).contains(key)
                                        Button {
                                            toggleAllergen($row, key: key)
                                        } label: {
                                            Text(allergenLabel(for: key))
                                                .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .semibold))
                                                .lineLimit(1)
                                                .foregroundStyle(isSelected ? .white : SafeEatTheme.primaryDeep)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .frame(maxWidth: .infinity)
                                                .background(
                                                    Capsule()
                                                        .fill(isSelected
                                                              ? AnyShapeStyle(SafeEatTheme.primary)
                                                              : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72)))
                                                )
                                                .overlay(
                                                    Capsule()
                                                        .stroke(isSelected ? AnyShapeStyle(SafeEatTheme.primary) : AnyShapeStyle(SafeEatTheme.line), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else if row.kind == .number {
                                // 数值项：只输数字，单位固定右侧只读（跟随原值）
                                HStack(spacing: 6) {
                                    TextField(SafeEatL10n.text(L10nKey.Feedback.nutritionAfterNumberPlaceholder), text: $row.afterText)
                                        .keyboardType(.decimalPad)
                                        .font(SafeEatFont.custom(16, relativeTo: .body, weight: .semibold))
                                        .foregroundStyle(SafeEatTheme.textPrimary)
                                    if let unit = row.unit, !unit.isEmpty {
                                        Text(unit)
                                            .font(SafeEatFont.custom(13, relativeTo: .footnote))
                                            .foregroundStyle(SafeEatTheme.textSecondary)
                                            .fixedSize()
                                    }
                                }
                            } else {
                                TextField(SafeEatL10n.text(L10nKey.Feedback.nutritionAfterTextPlaceholder), text: $row.afterText)
                                    .font(SafeEatFont.custom(16, relativeTo: .body, weight: .semibold))
                                    .foregroundStyle(SafeEatTheme.textPrimary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 56)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.85))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(SafeEatTheme.line, lineWidth: 1)
                        )
                    }
                }
                .padding(14)
                .background(fieldFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(16)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }


    private var currentRecognitionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                badge(title: SafeEatL10n.text(L10nKey.Feedback.badgeCurrent), emphasized: false)
                Spacer()

                Button {
                    showSourceDialog = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.78))
                        )
                }
                .buttonStyle(.plain)
            }

            Group {
                if let image = currentPreviewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 6)
                } else {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 26))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)

            Text(displayName)
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    /// 名称/别名输入：wrong_name 支持搜索回填；别名（add/remove）只能手动输入
    private var showNameSearch: Bool {
        let t = selectedFeedbackType
        return t != .addAlias && t != .removeAlias
    }

    private var correctionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            badge(title: SafeEatL10n.text(L10nKey.Feedback.badgeCorrect), emphasized: true)

            HStack(spacing: 10) {
                // 当前识别名称（固定位第一个，可点选回填）
                Button {
                    proposedName = displayName
                    searchResults = []
                    isNameFieldFocused = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13, weight: .semibold))
                        Text(displayName)
                            .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(SafeEatTheme.primaryDeep)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                    )
                }
                .buttonStyle(.plain)

                Spacer()

                // 搜索按钮（别名类型不显示：只能手动输入）
                if showNameSearch {
                    Button {
                        isNameFieldFocused = false
                        searchFoods()
                    } label: {
                        Group {
                            if isSearching {
                                ProgressView()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSearching || trimmedProposedName.isEmpty)
                    .opacity(trimmedProposedName.isEmpty ? 0.4 : 1)
                }
            }

            HStack(spacing: 10) {
                TextField(SafeEatL10n.text(L10nKey.Feedback.inputPlaceholder), text: $proposedName)
                    .focused($isNameFieldFocused)
                    .font(SafeEatFont.custom(18, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: proposedName) { _, _ in
                        searchResults = []
                    }

                if !trimmedProposedName.isEmpty {
                    Button {
                        proposedName = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(fieldFill)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // 搜索结果（别名类型不显示：只能手动输入）
            if showNameSearch && !suggestionCandidates.isEmpty {
                Text(SafeEatL10n.text(L10nKey.Feedback.suggestionsTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 10) {
                    ForEach(suggestionCandidates, id: \.self) { suggestion in
                        Button {
                            proposedName = suggestion
                            searchResults = []
                            isNameFieldFocused = false
                        } label: {
                            Text(suggestion)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote, weight: .bold))
                                .foregroundStyle(SafeEatTheme.primaryDeep)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 26))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func searchFoods() {
        guard !trimmedProposedName.isEmpty else { return }
        isSearching = true
        Task {
            do {
                let response = try await store.authorizedRequest { token in
                    try await store.api.searchFoods(accessToken: token, query: trimmedProposedName)
                }
                searchResults = response.items
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    @FocusState private var isCommentFocused: Bool
    @FocusState private var isNameFieldFocused: Bool

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(SafeEatL10n.text(L10nKey.Feedback.noteTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(SafeEatTheme.textSecondary)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(fieldFill)
                    .overlay(cardStroke(cornerRadius: 24))

                if comment.isEmpty {
                    Text(SafeEatL10n.text(L10nKey.Feedback.notePlaceholder))
                        .font(SafeEatFont.custom(16, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $comment)
                    .focused($isCommentFocused)
                    .font(SafeEatFont.custom(18, relativeTo: .body))
                    .foregroundColor(SafeEatTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 132)
                    .padding(.horizontal, 10)
                    .padding(.top, 8)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(comment.count)/200")
                            .font(SafeEatFont.custom(12, relativeTo: .caption))
                            .foregroundStyle(SafeEatTheme.textSecondary)
                            .padding(.trailing, 16)
                            .padding(.bottom, 14)
                    }
                }
            }
            .frame(minHeight: 156)
        }
    }

    private var auditNoteCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.checkmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(SafeEatTheme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(SafeEatL10n.text(L10nKey.Feedback.auditTitle))
                    .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                Text(SafeEatL10n.text(L10nKey.Feedback.auditBody))
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(correctionCardFill)
        .overlay(cardStroke(cornerRadius: 18))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var submitButton: some View {
        Button {
            Task {
                await submit()
            }
        } label: {
            Group {
                if submitting {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(SafeEatL10n.text(L10nKey.Feedback.submit))
                        .font(SafeEatFont.custom(22, relativeTo: .headline, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: SafeEatTheme.primaryDeep.opacity(0.16), radius: 16, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1 : 0.58)
    }

    private var thanksFootnote: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 18, weight: .semibold))
            Text(SafeEatL10n.text(L10nKey.Feedback.thanks))
                .font(SafeEatFont.custom(16, relativeTo: .footnote))
        }
        .foregroundStyle(colorScheme == .dark ? Color(red: 0.73, green: 0.90, blue: 0.78) : SafeEatTheme.primary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 2)
    }

    private func badge(title: String, emphasized: Bool) -> some View {
        Text(title)
            .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .bold))
            .foregroundStyle(emphasized ? Color.white : SafeEatTheme.primaryDeep)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        emphasized
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                              : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.primarySoft.opacity(0.72))
                    )
            )
    }

    private var fieldFill: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(Color.white.opacity(0.78))
    }

    private var correctionCardFill: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.06)) : AnyShapeStyle(Color.white)
    }

    private func cardStroke(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line, lineWidth: 1)
    }

    private func keyboardBottomSpacing(bottomInset: CGFloat) -> CGFloat {
        max(32, keyboardHeight - bottomInset + 52)
    }

    private func updateKeyboardHeight(with notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        let overlap = max(0, UIScreen.main.bounds.height - frame.minY)
        withAnimation(.easeInOut(duration: 0.22)) {
            keyboardHeight = overlap
        }
    }


    /// 结构化修改内容：按反馈类型生成（路径级明细，后端可溯源）
    private var proposedChangesJson: String? {
        guard let type = selectedFeedbackType, !trimmedProposedName.isEmpty else { return nil }
        var items: [[String: Any]] = []
        func append(_ item: [String: Any]) { items.append(item) }
        switch type {
        case .wrongName:
            append(["itemType": "field_change", "payload": ["changes": ["canonicalName": trimmedProposedName]], "before": ["canonicalName": displayName]])
        case .wrongTags:
            // 标签/过敏原：每条 = 一个路径明细（可溯源）
            if !nutritionRows.isEmpty {
                let tagTree = metricsTree ?? [:]
                for row in nutritionRows {
                    if row.path.first == "dietaryInfo", let v = Bool(row.afterText) {
                        let p = "nutritionMetrics." + row.path.joined(separator: ".")
                        let before = Self.readPathValue(tagTree, row.path)
                        append(["itemType": "field_change", "payload": ["path": p, "after": v], "before": ["value": before ?? NSNull()]])
                    } else if row.path == ["allergens", "contains"] {
                        let parts = row.afterText.split(separator: "、").map(String.init)
                        let p = "nutritionMetrics.allergens.contains"
                        let before = Self.readPathValue(tagTree, row.path)
                        append(["itemType": "field_change", "payload": ["path": p, "after": parts], "before": ["value": before ?? NSNull()]])
                    }
                }
            }
        case .wrongNutrition:
            // 营养：每条 = 一个路径明细（可溯源）
            if !nutritionRows.isEmpty {
                let nutTree = metricsTree ?? [:]
                for row in nutritionRows {
                    let p = "nutritionMetrics." + row.path.joined(separator: ".")
                    let before = Self.readPathValue(nutTree, row.path)
                    switch row.kind {
                    case .number:
                        if let v = Double(row.afterText) {
                            append(["itemType": "field_change", "payload": ["path": p, "after": v], "before": ["value": before ?? NSNull()]])
                        }
                    case .boolean:
                        if let v = Bool(row.afterText) {
                            append(["itemType": "field_change", "payload": ["path": p, "after": v], "before": ["value": before ?? NSNull()]])
                        }
                    case .text:
                        let parts = row.afterText.split(separator: "、").map(String.init)
                        if !row.afterText.isEmpty {
                            let afterVal: Any = parts.count == 1 ? parts[0] : parts
                            append(["itemType": "field_change", "payload": ["path": p, "after": afterVal], "before": ["value": before ?? NSNull()]])
                        }
                    }
                }
            }
        case .addAlias:
            append(["itemType": "alias_add", "payload": ["name": trimmedProposedName]])
        case .removeAlias:
            append(["itemType": "alias_remove", "payload": ["name": trimmedProposedName]])
        default:
            break
        }
        guard !items.isEmpty else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: items, options: [.prettyPrinted]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 从树按路径读原始值（before 溯源用）
    private static func readPathValue(_ obj: [String: Any], _ path: [String]) -> Any? {
        var cur: Any = obj
        for seg in path {
            if let dict = cur as? [String: Any], let next = dict[seg] {
                cur = next
            } else {
                return nil
            }
        }
        return cur
    }

    /// 提交成功页：大对勾 + 文案，停留片刻自动关闭
    private var successOverlay: some View {
        ZStack {
            (colorScheme == .dark ? Color.black.opacity(0.82) : Color.white.opacity(0.92))
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(SafeEatTheme.success.opacity(colorScheme == .dark ? 0.22 : 0.14))
                        .frame(width: 108, height: 108)
                    Circle()
                        .fill(SafeEatTheme.success)
                        .frame(width: 78, height: 78)
                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(SafeEatL10n.text(L10nKey.Feedback.successTitle))
                    .font(SafeEatFont.custom(24, relativeTo: .title2, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                Text(SafeEatL10n.text(L10nKey.Feedback.successSubtitle))
                    .font(SafeEatFont.custom(15, relativeTo: .callout))
                    .foregroundStyle(SafeEatTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    private func submit() async {
        submitting = true
        submitError = nil
        defer { submitting = false }

        do {
            let records = try await store.authorizedRequest { token in
                try await store.api.submitFeedback(
                    accessToken: token,
                    recognitionId: recognition.id,
                    proposedName: trimmedProposedName,
                    comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
                    feedbackType: selectedFeedbackType,
                    proposedChanges: proposedChangesJson
                )
            }

            if let updatedRecord = records.first {
                // 知识库有匹配：全量替换本地数据
                store.replaceRecognitionData(for: historyItem.id, with: updatedRecord)
            } else {
                // 知识库无匹配：只加待审核标记，不改数据
                store.setFeedbackPending(for: historyItem.id, pending: true)
            }

            // 成功提示页停留片刻再关闭（用户能看到提交成功）
            withAnimation(.easeOut(duration: 0.22)) { showSuccess = true }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        } catch {
            #if DEBUG
            print("[Feedback] 后端请求失败: \(error)")
            #endif
            // 提交失败留在本页并给内联错误，用户可直接重试
            submitError = SafeEatL10n.text(L10nKey.Feedback.submitFailed)
        }
    }
}
