import SwiftUI

// MARK: - 单位偏好

enum HeightUnit: String, CaseIterable {
    case cm, ft
}

enum WeightUnit: String, CaseIterable {
    case kg, lbs
}

// MARK: - 编辑资料页

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var gender = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var ageText = ""
    @State private var activityLevel = ""
    @State private var isSaving = false
    @State private var bmiCache: String?
    @State private var tdeeCache: String?
    @State private var showBmiInfo = false
    @State private var showTdeeInfo = false

    // ft 模式下的独立字段
    @State private var feetText = ""
    @State private var inchesText = ""

    @AppStorage("editProfile.heightUnit") private var heightUnit: HeightUnit = .cm
    @AppStorage("editProfile.weightUnit") private var weightUnit: WeightUnit = .kg

    // 内部始终用 cm/kg 计算，切换单位只改显示
    @State private var heightCmInternal: Double?
    @State private var weightKgInternal: Double?

    private let genderOptions = ["", "male", "female"]
    private let activityOptions = ["", "sedentary", "light", "moderate", "heavy", "athlete"]

    var body: some View {
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.Profile.editTitle),
            subtitle: SafeEatL10n.text(L10nKey.Profile.Edit.subtitle)
        ) {
            // 基本信息
            ProfileSurfaceCard {
                Text(SafeEatL10n.text(L10nKey.Profile.Edit.basicSection))
                    .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.displayName)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.Edit.displayName),
                        text: $displayName
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.gender)) {
                    ProfileMenuField(
                        value: gender,
                        options: genderOptions.map { option in
                            (
                                id: option,
                                title: UserGenderMapper.title(option.isEmpty ? nil : option)
                            )
                        },
                        onSelect: { gender = $0 }
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.age)) {
                    ProfileTextField(
                        title: SafeEatL10n.text(L10nKey.Profile.Edit.agePlaceholder),
                        text: $ageText,
                        keyboardType: .numberPad
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.height)) {
                    heightInputArea
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.weight)) {
                    inputWithUnitToggle(
                        text: $weightText,
                        placeholder: weightUnit == .kg ? "70" : "154",
                        keyboardType: .decimalPad,
                        unit: weightUnit.rawValue,
                        units: WeightUnit.allCases.map { $0.rawValue },
                        onUnitChange: { switchWeightUnit(to: WeightUnit(rawValue: $0) ?? .kg) }
                    )
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(label: SafeEatL10n.text(L10nKey.Profile.Edit.activityLevel)) {
                    ProfileMenuField(
                        value: activityLevel,
                        options: activityOptions.map { option in
                            (
                                id: option,
                                title: activityLevelTitle(option)
                            )
                        },
                        onSelect: { activityLevel = $0 }
                    )
                }
            }

            // BMI + TDEE 结果
            ProfileSurfaceCard {
                ProfileFieldBlock(
                    label: SafeEatL10n.text(L10nKey.Profile.bmiLabel),
                    onInfo: { showBmiInfo = true }
                ) {
                    resultRow(value: bmiCache, icon: "figure.walk.circle.fill")
                }

                Divider().overlay(SafeEatTheme.line)

                ProfileFieldBlock(
                    label: SafeEatL10n.text(L10nKey.Profile.Edit.tdeeLabel),
                    onInfo: { showTdeeInfo = true }
                ) {
                    resultRow(value: tdeeCache, icon: "flame.fill", suffix: SafeEatL10n.text(L10nKey.Profile.Edit.tdeeUnit))
                }
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.Common.save),
                isLoading: isSaving
            ) {
                Task {
                    await saveProfile()
                }
            }
        }
        .sheet(isPresented: $showBmiInfo) {
            bmiInfoSheet
        }
        .sheet(isPresented: $showTdeeInfo) {
            tdeeInfoSheet
        }
        .task {
            loadFromProfile()
        }
        .onChange(of: heightText) { _ in syncHeightInternal(); updateCalculations() }
        .onChange(of: weightText) { _ in syncWeightInternal(); updateCalculations() }
        .onChange(of: feetText) { _ in syncHeightInternalFromFt(); updateCalculations() }
        .onChange(of: inchesText) { _ in syncHeightInternalFromFt(); updateCalculations() }
        .onChange(of: ageText) { _ in updateCalculations() }
        .onChange(of: gender) { _ in updateCalculations() }
        .onChange(of: activityLevel) { _ in updateCalculations() }
    }

    // MARK: - 身高输入区域（cm 模式：单输入框，ft 模式：ft + in 两个输入框）

    private var heightInputArea: some View {
        HStack(spacing: 8) {
            if heightUnit == .cm {
                TextField("175", text: $heightText)
                    .keyboardType(.decimalPad)
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            } else {
                // ft 输入框
                TextField("5", text: $feetText)
                    .keyboardType(.numberPad)
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .frame(width: 48)

                Text("′")
                    .font(SafeEatFont.custom(18, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textSecondary)

                // in 输入框
                TextField("9", text: $inchesText)
                    .keyboardType(.numberPad)
                    .font(SafeEatFont.custom(16, relativeTo: .body))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .frame(width: 48)

                Text("″")
                    .font(SafeEatFont.custom(18, relativeTo: .body, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            Spacer(minLength: 4)

            // 单位切换胶囊
            unitToggleCapsule(
                unit: heightUnit.rawValue,
                units: HeightUnit.allCases.map { $0.rawValue },
                onUnitChange: { switchHeightUnit(to: HeightUnit(rawValue: $0) ?? .cm) }
            )
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(profileControlFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - 单位切换胶囊（可复用）

    private func unitToggleCapsule(
        unit: String,
        units: [String],
        onUnitChange: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(units, id: \.self) { u in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        onUnitChange(u)
                    }
                } label: {
                    Text(u)
                        .font(SafeEatFont.custom(12, relativeTo: .caption2, weight: .bold))
                        .foregroundStyle(unit == u ? .white : SafeEatTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            unit == u
                                ? RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(SafeEatTheme.primary)
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.5))
        )
    }

    // MARK: - 输入框 + 单位切换组件（体重用）

    private func inputWithUnitToggle(
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType,
        unit: String,
        units: [String],
        onUnitChange: @escaping (String) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(SafeEatFont.custom(16, relativeTo: .body))
                .foregroundStyle(SafeEatTheme.textPrimary)

            unitToggleCapsule(unit: unit, units: units, onUnitChange: onUnitChange)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(profileControlFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(profileStrokeColor(for: colorScheme), lineWidth: 1)
        )
    }

    // MARK: - 单位切换逻辑

    private func switchHeightUnit(to newUnit: HeightUnit) {
        guard newUnit != heightUnit else { return }
        let oldUnit = heightUnit
        heightUnit = newUnit

        if oldUnit == .cm && newUnit == .ft {
            // cm → ft+in：拆分为两个独立字段
            guard let cmValue = Double(heightText), cmValue > 0 else {
                feetText = ""
                inchesText = ""
                return
            }
            let totalInches = cmValue / 2.54
            var feet = Int(totalInches / 12)
            var inches = Int((totalInches.truncatingRemainder(dividingBy: 12)).rounded())
            // rounded() 可能得到 12，此时进位到下一英尺
            if inches >= 12 {
                feet += inches / 12
                inches = inches % 12
            }
            feetText = String(feet)
            inchesText = String(inches)
        } else if oldUnit == .ft && newUnit == .cm {
            // ft+in → cm：合并为一个字段
            let feet = Double(feetText) ?? 0
            let inches = min(Double(inchesText) ?? 0, 11)
            let cm = feet * 30.48 + inches * 2.54
            if cm > 0 {
                let rounded = abs(cm.rounded() - cm) < 0.01
                heightText = rounded ? String(Int(cm.rounded())) : String(format: "%.1f", cm)
            } else {
                heightText = ""
            }
            feetText = ""
            inchesText = ""
        }
    }

    private func switchWeightUnit(to newUnit: WeightUnit) {
        guard newUnit != weightUnit else { return }
        let oldUnit = weightUnit
        weightUnit = newUnit

        guard let value = Double(weightText), value > 0 else {
            weightText = ""
            return
        }

        if oldUnit == .kg && newUnit == .lbs {
            weightText = String(format: "%.1f", value * 2.20462)
        } else if oldUnit == .lbs && newUnit == .kg {
            weightText = String(format: "%.1f", value / 2.20462)
        }
    }

    // MARK: - 同步内部值（始终 cm/kg）

    private func syncHeightInternal() {
        guard heightUnit == .cm else { return }
        heightCmInternal = Double(heightText)
    }

    private func syncHeightInternalFromFt() {
        guard heightUnit == .ft else { return }
        let feetStr = feetText.trimmingCharacters(in: .whitespaces)
        let inchesStr = inchesText.trimmingCharacters(in: .whitespaces)
        guard !feetStr.isEmpty || !inchesStr.isEmpty else {
            heightCmInternal = nil
            return
        }
        let feet = Double(feetStr) ?? 0
        let inches = min(Double(inchesStr) ?? 0, 11)
        let cm = feet * 30.48 + inches * 2.54
        heightCmInternal = cm > 0 ? cm : nil
    }

    private func syncWeightInternal() {
        if weightUnit == .kg {
            weightKgInternal = Double(weightText)
        } else {
            let lbs = Double(weightText) ?? 0
            weightKgInternal = lbs / 2.20462
        }
    }

    // MARK: - 结果行

    private func resultRow(value: String?, icon: String, suffix: String? = nil) -> some View {
        HStack {
            Text(value ?? SafeEatL10n.text(L10nKey.Common.notSet))
                .font(SafeEatFont.custom(20, relativeTo: .title3, weight: .bold))
                .foregroundStyle(SafeEatTheme.primaryDeep)

            if let suffix, value != nil {
                Text(suffix)
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(SafeEatTheme.textSecondary)
            }

            Spacer()

            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(SafeEatTheme.primary.opacity(0.7))
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

    // MARK: - 活动等级标题

    private func activityLevelTitle(_ code: String) -> String {
        switch code {
        case "sedentary": return SafeEatL10n.text(L10nKey.Profile.Edit.activitySedentary)
        case "light": return SafeEatL10n.text(L10nKey.Profile.Edit.activityLight)
        case "moderate": return SafeEatL10n.text(L10nKey.Profile.Edit.activityModerate)
        case "heavy": return SafeEatL10n.text(L10nKey.Profile.Edit.activityHeavy)
        case "athlete": return SafeEatL10n.text(L10nKey.Profile.Edit.activityAthlete)
        default: return SafeEatL10n.text(L10nKey.Common.notSet)
        }
    }

    // MARK: - 计算逻辑（用内部 cm/kg）

    private func updateCalculations() {
        updateBmiCache()
        updateTdeeCache()
    }

    private func updateBmiCache() {
        guard let height = heightCmInternal, let weight = weightKgInternal, height > 0, weight > 0 else {
            bmiCache = SafeEatL10n.text(L10nKey.Common.notSet)
            return
        }
        let bmi = weight / pow(height / 100, 2)
        bmiCache = String(format: "%.1f", bmi)
    }

    private func updateTdeeCache() {
        guard
            let height = heightCmInternal,
            let weight = weightKgInternal,
            let age = Int(ageText),
            height > 0, weight > 0, age > 0,
            !gender.isEmpty,
            !activityLevel.isEmpty
        else {
            tdeeCache = SafeEatL10n.text(L10nKey.Common.notSet)
            return
        }

        var bmr: Double
        if gender == "male" {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }

        let factor: Double
        switch activityLevel {
        case "sedentary": factor = 1.2
        case "light": factor = 1.375
        case "moderate": factor = 1.55
        case "heavy": factor = 1.725
        case "athlete": factor = 1.9
        default: tdeeCache = SafeEatL10n.text(L10nKey.Common.notSet); return
        }

        tdeeCache = String(format: "%.0f", bmr * factor)
    }

    // MARK: - 问号弹窗（SafeEatSettingsSheetContainer）

    private var isZh: Bool {
        SafeEatL10n.isZh
    }

    private var bmiInfoSheet: some View {
        SafeEatSettingsSheetContainer(
            title: "BMI",
            subtitle: isZh ? "身体质量指数" : "Body Mass Index",
            contentHeight: nil,
            primaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.ok)) { showBmiInfo = false }
        ) {
            ScrollView(showsIndicators: false) {
                if isZh {
                    bmiInfoContentZh
                } else {
                    bmiInfoContentEn
                }
            }
        }
    }

    private var tdeeInfoSheet: some View {
        SafeEatSettingsSheetContainer(
            title: "TDEE",
            subtitle: isZh ? "每日总能量消耗" : "Total Daily Energy Expenditure",
            contentHeight: nil,
            primaryButton: SheetButton(title: SafeEatL10n.text(L10nKey.Common.ok)) { showTdeeInfo = false }
        ) {
            ScrollView(showsIndicators: false) {
                if isZh {
                    tdeeInfoContentZh
                } else {
                    tdeeInfoContentEn
                }
            }
        }
    }

    // MARK: - BMI 信息内容（结构化排版 - 中文）

    private var bmiInfoContentZh: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoHeading("什么是 BMI")
            infoBody("BMI（身体质量指数）用于评估体重是否在健康范围。它通过身高和体重的比值来衡量，是世界卫生组织推荐的常用指标。")

            infoHeading("计算公式")
            formulaBlock("BMI = 体重(kg) ÷ 身高(m)²")

            infoHeading("参考范围")
            infoTable(headers: ["分类", "BMI 范围"], rows: [
                ("体重过轻", "< 18.5"),
                ("正常范围", "18.5 ~ 24.9"),
                ("超重", "25 ~ 29.9"),
                ("肥胖", "≥ 30"),
            ])

            infoHeading("注意事项")
            infoBody("BMI 仅基于身高和体重计算，不考虑肌肉量、骨骼密度、体脂分布等因素，仅供参考。运动员或孕妇等特殊人群的 BMI 可能不完全适用。")
        }
    }

    // MARK: - BMI 信息内容（结构化排版 - 英文）

    private var bmiInfoContentEn: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoHeading("What is BMI")
            infoBody("BMI (Body Mass Index) is used to assess whether your weight is in a healthy range. It is a widely recommended indicator by the World Health Organization.")

            infoHeading("Formula")
            formulaBlock("BMI = Weight(kg) ÷ Height(m)²")

            infoHeading("Reference Ranges")
            infoTable(headers: ["Category", "BMI Range"], rows: [
                ("Underweight", "< 18.5"),
                ("Normal", "18.5 ~ 24.9"),
                ("Overweight", "25 ~ 29.9"),
                ("Obese", "≥ 30"),
            ])

            infoHeading("Note")
            infoBody("BMI is based solely on height and weight. It does not account for muscle mass, bone density, or body fat distribution. It may not be fully applicable for athletes, pregnant women, or other special populations.")
        }
    }

    // MARK: - TDEE 信息内容（结构化排版 - 中文）

    private var tdeeInfoContentZh: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoHeading("什么是 TDEE")
            infoBody("每日总能量消耗（TDEE）是你的身体一天中燃烧的总热量。它将基础代谢率（BMR）——即完全静息状态下所需的能量——与通过身体活动、消化和日常运动消耗的热量相结合。了解你的 TDEE 是制定有效营养计划的基础，无论你是想减脂、增肌还是维持体重。")

            infoHeading("计算公式：Mifflin-St Jeor 方程")
            formulaBlock("TDEE = BMR × 活动系数")

            infoHeading("BMR 公式")
            formulaBlock("男性：BMR = 10 × 体重(kg) + 6.25 × 身高(cm) − 5 × 年龄 + 5")
            formulaBlock("女性：BMR = 10 × 体重(kg) + 6.25 × 身高(cm) − 5 × 年龄 − 161")

            infoHeading("活动系数参考表")
            infoTable(headers: ["活动等级", "系数", "说明"], rows: [
                ("久坐不动", "1.2", "很少或不运动，办公室工作"),
                ("轻度活动", "1.375", "每周1-3天轻度运动"),
                ("中等活动", "1.55", "每周3-5天中等强度运动"),
                ("高强度活动", "1.725", "每周6-7天高强度运动"),
                ("运动员级别", "1.9", "每天两次训练或体力劳动"),
            ])
        }
    }

    // MARK: - TDEE 信息内容（结构化排版 - 英文）

    private var tdeeInfoContentEn: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoHeading("What is TDEE")
            infoBody("Total Daily Energy Expenditure (TDEE) is the total number of calories your body burns in a day. It combines your Basal Metabolic Rate (BMR) — the energy needed at complete rest — with calories burned through physical activity, digestion, and daily movement. Understanding your TDEE is the foundation for creating an effective nutrition plan.")

            infoHeading("Formula: Mifflin-St Jeor Equation")
            formulaBlock("TDEE = BMR × Activity Factor")

            infoHeading("BMR Formula")
            formulaBlock("Male: BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age + 5")
            formulaBlock("Female: BMR = 10 × weight(kg) + 6.25 × height(cm) − 5 × age − 161")

            infoHeading("Activity Factor Reference")
            infoTable(headers: ["Level", "Factor", "Description"], rows: [
                ("Sedentary", "1.2", "Little or no exercise, desk job"),
                ("Lightly Active", "1.375", "Light exercise 1-3 days/week"),
                ("Moderately Active", "1.55", "Moderate exercise 3-5 days/week"),
                ("Very Active", "1.725", "Hard exercise 6-7 days/week"),
                ("Athlete", "1.9", "Very hard exercise or physical labor"),
            ])
        }
    }

    // MARK: - 信息排版组件

    private func infoHeading(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.custom(15, relativeTo: .body, weight: .bold))
            .foregroundStyle(SafeEatTheme.textPrimary)
            .padding(.top, 4)
    }

    private func infoBody(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.custom(14, relativeTo: .body))
            .foregroundStyle(SafeEatTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func formulaBlock(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .semibold))
            .foregroundStyle(SafeEatTheme.primaryDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(SafeEatTheme.primarySoft.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(SafeEatTheme.primary.opacity(0.15), lineWidth: 1)
            )
    }

    // 2列表格
    private func infoTable(headers: [String], rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(SafeEatTheme.primarySoft.opacity(0.3))
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    Text(row.0)
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)

                    Text(row.1)
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.primaryDeep)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .background(rowIndex % 2 == 0 ? Color.clear : SafeEatTheme.primarySoft.opacity(0.15))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(SafeEatTheme.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // 3列表格
    private func infoTable(headers: [String], rows: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(headers.enumerated()), id: \.offset) { _, header in
                    Text(header)
                        .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(SafeEatTheme.primarySoft.opacity(0.3))
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10))

            ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, row in
                HStack(spacing: 0) {
                    Text(row.0)
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .semibold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)

                    Text(row.1)
                        .font(SafeEatFont.custom(13, relativeTo: .caption, weight: .bold))
                        .foregroundStyle(SafeEatTheme.primaryDeep)
                        .frame(width: 48, alignment: .center)
                        .padding(.vertical, 8)

                    Text(row.2)
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                }
                .background(rowIndex % 2 == 0 ? Color.clear : SafeEatTheme.primarySoft.opacity(0.15))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(SafeEatTheme.primary.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - 数据加载与保存

    private func loadFromProfile() {
        guard let profile = store.profile else { return }
        displayName = profile.displayName ?? ""
        gender = genderOptions.contains(profile.gender ?? "") ? (profile.gender ?? "") : ""
        if let heightCm = profile.heightCm {
            heightCmInternal = heightCm
            if heightUnit == .cm {
                let rounded = abs(heightCm.rounded() - heightCm) < 0.01
                heightText = rounded ? String(Int(heightCm.rounded())) : String(format: "%.1f", heightCm)
            } else {
                let totalInches = heightCm / 2.54
                let feet = Int(totalInches / 12)
                let inches = Int((totalInches.truncatingRemainder(dividingBy: 12)).rounded())
                feetText = String(feet)
                inchesText = String(min(inches, 11))
            }
        }
        if let weightKg = profile.weightKg {
            weightKgInternal = weightKg
            if weightUnit == .kg {
                let rounded = abs(weightKg.rounded() - weightKg) < 0.01
                weightText = rounded ? String(Int(weightKg.rounded())) : String(format: "%.1f", weightKg)
            } else {
                let lbs = weightKg * 2.20462
                let rounded = abs(lbs.rounded() - lbs) < 0.01
                weightText = rounded ? String(Int(lbs.rounded())) : String(format: "%.1f", lbs)
            }
        }
        if let age = profile.age {
            ageText = String(age)
        }
        activityLevel = activityOptions.contains(profile.activityLevel ?? "") ? (profile.activityLevel ?? "") : ""
        updateCalculations()
    }

    private func saveProfile() async {
        isSaving = true
        defer { isSaving = false }

        // heightCm/weightKg 后端分别允许1位小数，ft 转换可能产生小数需四舍五入到1位
        let heightCm: Double? = {
            guard let v = heightCmInternal, v >= 50, v <= 260 else { return nil }
            return (v * 10).rounded() / 10
        }()
        let weightKg: Double? = {
            guard let v = weightKgInternal, v >= 20, v <= 300 else { return nil }
            return (v * 10).rounded() / 10
        }()

        do {
            _ = try await store.updateUserProfile(
                UserProfileUpdatePayload(
                    displayName: trimmedOrNil(displayName),
                    gender: gender.isEmpty ? nil : gender,
                    heightCm: heightCm,
                    weightKg: weightKg,
                    age: Int(ageText),
                    activityLevel: activityLevel.isEmpty ? nil : activityLevel,
                    healthTags: nil,
                    fitnessGoal: nil,
                    avoidIngredients: nil,
                    dietaryPreferences: nil
                )
            )

            dismiss()
        } catch {
            store.errorMessage = error.localizedDescription
        }
    }

    private func trimmedOrNil(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
