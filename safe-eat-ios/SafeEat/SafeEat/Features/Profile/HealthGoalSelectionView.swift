import SwiftUI

// MARK: - 健康画像模板模型（本地 mock，后端 API 就绪后替换）

struct HealthProfileTemplate: Identifiable, Hashable {
    let id: String
    let code: String
    let displayName: String
    let icon: String
    let group: HealthProfileGroup
    var isHighlighted: Bool

    enum HealthProfileGroup: String, CaseIterable {
        case healthRisk = "health_risk"
        case lifeGoal = "life_goal"

        var title: String {
            switch self {
            case .healthRisk:
                return SafeEatL10n.text(L10nKey.HealthGoal.groupHealthRisk)
            case .lifeGoal:
                return SafeEatL10n.text(L10nKey.HealthGoal.groupLifeGoal)
            }
        }

        var icon: String {
            switch self {
            case .healthRisk: return "heart.text.square.fill"
            case .lifeGoal: return "figure.run.fill"
            }
        }
    }
}

// MARK: - 本地 mock 数据

enum HealthProfileTemplateMock {
    static let templates: [HealthProfileTemplate] = [
        // 健康风险组
        HealthProfileTemplate(id: "1", code: "hypertension", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateHypertension), icon: "heart.fill", group: .healthRisk, isHighlighted: true),
        HealthProfileTemplate(id: "2", code: "hyperglycemia", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateHyperglycemia), icon: "drop.fill", group: .healthRisk, isHighlighted: true),
        HealthProfileTemplate(id: "3", code: "hyperlipidemia", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateHyperlipidemia), icon: "waveform.path.ecg.fill", group: .healthRisk, isHighlighted: false),
        HealthProfileTemplate(id: "4", code: "gout", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateGout), icon: "bone.fill", group: .healthRisk, isHighlighted: false),
        HealthProfileTemplate(id: "5", code: "kidney_disease", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateKidney), icon: "kidney.fill", group: .healthRisk, isHighlighted: false),
        // 生活目标组
        HealthProfileTemplate(id: "6", code: "weight_loss", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateWeightLoss), icon: "arrow.down.circle.fill", group: .lifeGoal, isHighlighted: true),
        HealthProfileTemplate(id: "7", code: "muscle_gain", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateMuscleGain), icon: "dumbbell.fill", group: .lifeGoal, isHighlighted: false),
        HealthProfileTemplate(id: "8", code: "balanced", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateBalanced), icon: "leaf.fill", group: .lifeGoal, isHighlighted: true),
        HealthProfileTemplate(id: "9", code: "cardiovascular", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateCardiovascular), icon: "heart.circle.fill", group: .lifeGoal, isHighlighted: false),
        HealthProfileTemplate(id: "10", code: "blood_sugar_control", displayName: SafeEatL10n.text(L10nKey.HealthGoal.templateBloodSugarControl), icon: "chart.line.downtrend.xyaxis", group: .lifeGoal, isHighlighted: false),
    ]
}

// MARK: - 健康目标选择页面

struct HealthGoalSelectionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedIds: Set<String> = []
    @State private var primaryId: String? = nil
    @State private var showMembership = false

    private let templates = HealthProfileTemplateMock.templates

    private var maxSelection: Int {
        // 从套餐获取 maxHealthProfiles，默认 Free = 1
        let tier = store.profile?.currentPlanTier ?? "free"
        let plan = store.membershipPlans.first(where: { $0.tier == tier })
        return plan?.maxHealthProfiles ?? 1
    }

    private var isAtLimit: Bool {
        selectedIds.count >= maxSelection
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    limitHintBanner

                    ForEach(HealthProfileTemplate.HealthProfileGroup.allCases, id: \.self) { group in
                        templateGroupSection(group: group)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle(SafeEatL10n.text(L10nKey.HealthGoal.navTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SafeEatL10n.text(L10nKey.HealthGoal.saveAction)) {
                        saveSelection()
                    }
                    .disabled(selectedIds.isEmpty)
                    .bold()
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button(SafeEatL10n.text(L10nKey.HealthGoal.cancelAction)) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showMembership) {
                MembershipPurchaseView()
            }
            .onAppear {
                loadCurrentSelection()
            }
        }
    }

    // MARK: - 限制提示

    private var limitHintBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
            Text(SafeEatL10n.format(L10nKey.HealthGoal.limitHintFormat, maxSelection))
                .font(SafeEatFont.custom(13, relativeTo: .caption))
        }
        .foregroundStyle(SafeEatTheme.primary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.18 : 0.62))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 分组 Section

    private func templateGroupSection(group: HealthProfileTemplate.HealthProfileGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: group.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(SafeEatTheme.primary)
                Text(group.title)
                    .font(SafeEatFont.custom(17, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
            }

            let groupTemplates = templates.filter { $0.group == group }
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
            ], spacing: 12) {
                ForEach(groupTemplates) { template in
                    templateCard(template)
                }
            }
        }
    }

    // MARK: - 画像模板卡片

    private func templateCard(_ template: HealthProfileTemplate) -> some View {
        let isSelected = selectedIds.contains(template.id)
        let isPrimary = primaryId == template.id
        let canSelect = isSelected || !isAtLimit

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    selectedIds.remove(template.id)
                    if isPrimary { primaryId = nil }
                } else if canSelect {
                    selectedIds.insert(template.id)
                    if primaryId == nil { primaryId = template.id }
                } else {
                    showMembership = true
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? SafeEatTheme.primary.opacity(colorScheme == .dark ? 0.22 : 0.12) : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.92)))
                        .frame(width: 48, height: 48)

                    Image(systemName: template.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? SafeEatTheme.primary : SafeEatTheme.textSecondary)
                }

                Text(template.displayName)
                    .font(SafeEatFont.custom(13, relativeTo: .caption, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? SafeEatTheme.textPrimary : SafeEatTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if isPrimary {
                    Text(SafeEatL10n.text(L10nKey.HealthGoal.primaryTag))
                        .font(SafeEatFont.custom(10, relativeTo: .caption2, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(SafeEatTheme.primary)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.14 : 0.62) : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.72)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? SafeEatTheme.primary : (colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line), lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isSelected {
                if isPrimary {
                    Button {
                        primaryId = nil
                    } label: {
                        Label(SafeEatL10n.text(L10nKey.HealthGoal.unsetPrimaryAction), systemImage: "star")
                    }
                } else {
                    Button {
                        primaryId = template.id
                    } label: {
                        Label(SafeEatL10n.text(L10nKey.HealthGoal.setPrimaryAction), systemImage: "star.fill")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedIds.remove(template.id)
                        if isPrimary { primaryId = nil }
                    }
                } label: {
                    Label(SafeEatL10n.text(L10nKey.HealthGoal.removeAction), systemImage: "minus.circle")
                }
            }
        }
    }

    // MARK: - 操作

    private func loadCurrentSelection() {
        // 从 store.profile.healthTags 恢复当前选择
        guard let healthTags = store.profile?.healthTags else { return }
        for tag in healthTags {
            if let match = templates.first(where: { $0.code == tag }) {
                selectedIds.insert(match.id)
            }
        }
        // 默认第一个选中的为重点
        if let first = selectedIds.first {
            primaryId = first
        }
    }

    private func saveSelection() {
        let selectedTemplates = templates.filter { selectedIds.contains($0.id) }
        let healthTags = selectedTemplates.map(\.code)

        Task {
            let payload = UserHealthProfileUpdatePayload(
                healthTags: healthTags,
                fitnessGoal: store.profile?.fitnessGoal,
                avoidIngredients: store.profile?.avoidIngredients,
                dietaryPreferences: store.profile?.dietaryPreferences
            )
            _ = try? await store.updateUserHealthProfile(payload)
            dismiss()
        }
    }
}

#Preview {
    HealthGoalSelectionView()
        .environmentObject(AppStore())
}
