import SwiftUI

// MARK: - 健康画像模板模型（本地 mock，后端 API 就绪后替换）

struct HealthProfileTemplate: Identifiable, Hashable {
    let id: String
    let code: String
    let displayNameKey: String
    let icon: String
    let group: HealthProfileGroup
    var isHighlighted: Bool

    var displayName: String {
        SafeEatL10n.text(displayNameKey)
    }

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
        // 健康风险组（HealthTag）
        HealthProfileTemplate(id: "1", code: "high_blood_pressure", displayNameKey: L10nKey.HealthGoal.templateHypertension, icon: "heart.fill", group: .healthRisk, isHighlighted: true),
        HealthProfileTemplate(id: "2", code: "high_blood_sugar", displayNameKey: L10nKey.HealthGoal.templateHyperglycemia, icon: "drop.fill", group: .healthRisk, isHighlighted: true),
        HealthProfileTemplate(id: "3", code: "high_blood_lipids", displayNameKey: L10nKey.HealthGoal.templateHyperlipidemia, icon: "flame.fill", group: .healthRisk, isHighlighted: false),
        HealthProfileTemplate(id: "4", code: "general_wellness", displayNameKey: L10nKey.HealthGoal.templateGeneralWellness, icon: "heart.circle.fill", group: .healthRisk, isHighlighted: false),
        // 生活目标组（FitnessGoal）
        HealthProfileTemplate(id: "5", code: "fat_loss", displayNameKey: L10nKey.HealthGoal.templateWeightLoss, icon: "arrow.down.circle.fill", group: .lifeGoal, isHighlighted: true),
        HealthProfileTemplate(id: "6", code: "muscle_gain", displayNameKey: L10nKey.HealthGoal.templateMuscleGain, icon: "dumbbell.fill", group: .lifeGoal, isHighlighted: false),
        HealthProfileTemplate(id: "7", code: "blood_sugar_control", displayNameKey: L10nKey.HealthGoal.templateBloodSugarControl, icon: "chart.line.downtrend.xyaxis", group: .lifeGoal, isHighlighted: false),
        HealthProfileTemplate(id: "8", code: "balanced", displayNameKey: L10nKey.HealthGoal.templateBalanced, icon: "leaf.fill", group: .lifeGoal, isHighlighted: true),
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
        ProfileSecondaryPage(
            title: SafeEatL10n.text(L10nKey.HealthGoal.navTitle),
            subtitle: SafeEatL10n.format(L10nKey.HealthGoal.limitHintFormat, maxSelection)
        ) {
            ForEach(HealthProfileTemplate.HealthProfileGroup.allCases, id: \.self) { group in
                templateGroupSection(group: group)
            }
        } footer: {
            ProfilePrimaryActionButton(
                title: SafeEatL10n.text(L10nKey.HealthGoal.saveAction),
                isDisabled: selectedIds.isEmpty
            ) {
                saveSelection()
            }
        }
        .sheet(isPresented: $showMembership) {
            MembershipPurchaseView()
        }
        .onAppear {
            loadCurrentSelection()
        }
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
        let config = HealthTagConfig.forCode(template.code)
        let tagColor = config?.color ?? SafeEatTheme.primary

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if isSelected {
                    selectedIds.remove(template.id)
                    if isPrimary {
                        // 取消 primary 时，自动从剩余选中标签中晋升第一个
                        primaryId = selectedIds.first
                    }
                } else if canSelect {
                    selectedIds.insert(template.id)
                    if primaryId == nil || !selectedIds.contains(primaryId!) {
                        primaryId = template.id
                    }
                } else {
                    showMembership = true
                }
            }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tagColor.opacity(colorScheme == .dark ? 0.22 : 0.12) : (colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.92)))
                        .frame(width: 48, height: 48)

                    Image(systemName: template.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(isSelected ? tagColor : SafeEatTheme.textSecondary)
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
                        .background(tagColor)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? tagColor.opacity(colorScheme == .dark ? 0.08 : 0.06) : (colorScheme == .dark ? Color.white.opacity(0.04) : Color.white.opacity(0.72)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? tagColor.opacity(0.35) : (colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line), lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if isSelected {
                if isPrimary {
                    Button {
                        primaryId = selectedIds.first(where: { $0 != template.id })
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
                        if isPrimary {
                            primaryId = selectedIds.first
                        }
                    }
                } label: {
                    Label(SafeEatL10n.text(L10nKey.HealthGoal.removeAction), systemImage: "minus.circle")
                }
            }
        }
    }

    // MARK: - 操作

    private func loadCurrentSelection() {
        guard let healthTags = store.profile?.healthTags else { return }
        for tag in healthTags {
            if let match = templates.first(where: { $0.code == tag }) {
                selectedIds.insert(match.id)
            }
        }
        // 使用 healthTags 数组顺序的第一个作为重点
        if let firstCode = healthTags.first,
           let match = templates.first(where: { $0.code == firstCode }) {
            primaryId = match.id
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
            do {
                _ = try await store.updateUserHealthProfile(payload)
                dismiss()
            } catch {
                store.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    HealthGoalSelectionView()
        .environmentObject(AppStore())
}
