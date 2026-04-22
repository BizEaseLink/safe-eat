import SwiftUI
import UIKit

private struct ResultRoute: Identifiable, Hashable {
    let id: String
    let itemId: LocalHistoryItem.ID

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ScanHomeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var showCamera = false
    @State private var isRecognizing = false
    @State private var resultRoute: ResultRoute?
    @State private var scrollOffset: CGFloat = 0
    @State private var recognizingPreviewImage: UIImage?

    private let scrollCoordinateSpace = "safeeat.home.scroll"

    private var latestRecord: LocalHistoryItem? {
        store.localHistory.first
    }

    private var brandLabelColor: Color {
        colorScheme == .dark ? Color(red: 0.67, green: 0.86, blue: 0.73) : SafeEatTheme.primaryDeep
    }

    private var secondaryButtonTextColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : SafeEatTheme.primaryDeep
    }

    private var topPillFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.97, green: 0.98, blue: 0.97).opacity(0.96)
    }

    private var topPillStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.10)
            : Color(red: 0.83, green: 0.89, blue: 0.85).opacity(0.92)
    }

    private var heroPillFill: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.975, green: 0.982, blue: 0.975).opacity(0.96)
    }

    private var heroPillStroke: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color(red: 0.84, green: 0.90, blue: 0.86).opacity(0.94)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                homeBackground

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        SafeEatScrollOffsetReader(coordinateSpaceName: scrollCoordinateSpace)

                        topMetaBar

                        SafeEatPageHeader(title: "首页")

                        heroSection

                        recentRecordSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 44)
                }
                .coordinateSpace(name: scrollCoordinateSpace)
                .onPreferenceChange(SafeEatScrollOffsetKey.self) { value in
                    scrollOffset = value
                }

                SafeEatScrollNavChrome(
                    title: "首页",
                    scrollOffset: scrollOffset,
                    topInset: proxy.safeAreaInsets.top
                )

                if isRecognizing {
                    SafeEatLoadingOverlay(
                        title: "正在识别",
                        subtitle: "Safe-Eat 正在分析白框内的主体，请稍候。",
                        previewImage: recognizingPreviewImage
                    )
                    .transition(.opacity)
                    .zIndex(30)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView { payload in
                recognizingPreviewImage = BackgroundRemovalService.makePendingPreview(from: payload.croppedImage)
                Task {
                    await recognize(croppedImage: payload.croppedImage, rawImage: payload.rawImage)
                }
            }
        }
        .navigationDestination(item: $resultRoute) { route in
            ResultView(itemId: route.itemId)
        }
    }

    private var homeBackground: some View {
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
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.16 : 0.55),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 14,
                endRadius: 360
            )

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.12 : 0.42),
                    Color.clear,
                ],
                center: .bottomTrailing,
                startRadius: 16,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }

    private var topMetaBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Circle()
                    .fill(SafeEatTheme.primary.opacity(0.22))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .fill(SafeEatTheme.primary)
                            .frame(width: 8, height: 8)
                    )

                Text("SAFE-EAT")
                    .font(SafeEatFont.custom(16, relativeTo: .headline))
                    .foregroundStyle(brandLabelColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(topPillFill)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(topPillStroke, lineWidth: 1)
            )

            Spacer(minLength: 12)

            Button {
                store.selectedRootTab = .profile
            } label: {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("新用户专享")
                        .font(SafeEatFont.custom(12, relativeTo: .caption))
                    Text("29 元立减至 20 元")
                        .font(SafeEatFont.custom(16, relativeTo: .headline))
                }
                .foregroundStyle(colorScheme == .dark ? Color(red: 0.95, green: 0.84, blue: 0.67) : Color(red: 0.62, green: 0.46, blue: 0.18))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(colorScheme == .dark ? Color(red: 0.25, green: 0.22, blue: 0.18) : Color(red: 1.0, green: 0.95, blue: 0.89))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(colorScheme == .dark ? Color(red: 0.48, green: 0.40, blue: 0.29) : Color(red: 0.96, green: 0.88, blue: 0.76), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                heroPill("控糖友好")
                heroPill("本地历史")
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("今天这道菜，适不适合你继续吃？")
                    .font(SafeEatFont.custom(36, relativeTo: .largeTitle))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .lineSpacing(-2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Group {
                        if isRecognizing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("开始扫描")
                                .font(SafeEatFont.custom(21, relativeTo: .headline))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: SafeEatTheme.primaryDeep.opacity(0.18), radius: 16, y: 10)
                }
                .buttonStyle(.plain)
                .disabled(isRecognizing)

                Button {
                    store.selectedRootTab = .profile
                } label: {
                    Text("看会员")
                        .font(SafeEatFont.custom(21, relativeTo: .headline))
                        .foregroundStyle(secondaryButtonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var recentRecordSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text("最近记录")
                    .font(SafeEatFont.textStyle(.headline))
                    .foregroundStyle(SafeEatTheme.textPrimary)

                LinearGradient(
                    colors: [
                        SafeEatTheme.textPrimary.opacity(colorScheme == .dark ? 0.16 : 0.12),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }

            if let latestRecord {
                HomeRecentRecordCard(
                    item: latestRecord,
                    onOpenDetail: {
                        resultRoute = ResultRoute(id: latestRecord.id, itemId: latestRecord.id)
                    }
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("还没有本地记录")
                        .font(SafeEatFont.textStyle(.headline))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    Text("先开始一次扫描，识别结果会自动保存在本地菜单历史里。")
                        .font(SafeEatFont.textStyle(.subheadline))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: SafeEatTheme.primaryDeep.opacity(0.08), radius: 20, y: 12)
            }
        }
    }

    private func heroPill(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.custom(15, relativeTo: .subheadline))
            .foregroundStyle(brandLabelColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(heroPillFill)
            )
            .overlay(
                Capsule()
                    .stroke(heroPillStroke, lineWidth: 1)
            )
    }

    @MainActor
    private func recognize(croppedImage: UIImage, rawImage: UIImage) async {
        isRecognizing = true
        defer {
            isRecognizing = false
            recognizingPreviewImage = nil
        }

        guard let uploadData = croppedImage.jpegDataForUpload() else {
            store.errorMessage = "图片处理失败，请重试。"
            return
        }

        do {
            let created = try await store.authorizedRequest { token in
                try await store.api.createRecognition(
                    accessToken: token,
                    imageData: uploadData,
                    fileName: "capture.jpg"
                )
            }
            let detailed = try await store.authorizedRequest { token in
                try await store.api.getRecognition(accessToken: token, recognitionId: created.id)
            }
            let previewImage = await BackgroundRemovalService.makePreviewImage(
                from: croppedImage,
                adviceLevel: detailed.adviceLevel
            )
            let item = try store.recordRecognition(
                detailed,
                originalImage: croppedImage,
                previewImage: previewImage,
                rawImage: rawImage
            )

            resultRoute = ResultRoute(id: item.id, itemId: item.id)
        } catch {
            store.handleAPIError(error)
        }
    }
}

private struct HomeRecentRecordCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let item: LocalHistoryItem
    let onOpenDetail: () -> Void

    private var statusColor: Color {
        AdviceLevelMapper.color(item.adviceLevel)
    }

    private var nutritionPrimaryColor: Color {
        colorScheme == .dark ? Color(red: 0.85, green: 0.93, blue: 0.88) : SafeEatTheme.primaryDeep
    }

    private var impactItems: [HealthImpact] {
        Array((item.cachedRecognition?.healthImpacts ?? []).prefix(2))
    }

    private var summaryChips: [(String, Color)] {
        if !impactItems.isEmpty {
            return impactItems.map { impact in
                (impact.label, chipColor(level: impact.level))
            }
        }

        if let nutrition = item.cachedRecognition?.nutritionSnapshot {
            var chips: [(String, Color)] = []
            if let calories = nutrition.calories {
                chips.append(("约 \(Int(calories)) kcal", nutritionPrimaryColor))
            }
            if let protein = nutrition.protein {
                chips.append(("蛋白质 \(String(format: "%.1f", protein))g", SafeEatTheme.success))
            }
            if let carbs = nutrition.carbs, chips.count < 2 {
                chips.append(("碳水 \(String(format: "%.1f", carbs))g", SafeEatTheme.warning))
            }
            if !chips.isEmpty {
                return Array(chips.prefix(2))
            }
        }

        switch item.adviceLevel {
        case "recommended":
            return [("整体更友好", SafeEatTheme.success)]
        case "caution":
            return [("注意份量", SafeEatTheme.warning)]
        case "avoid":
            return [("建议换一种", SafeEatTheme.danger)]
        default:
            return [("建议再确认", SafeEatTheme.textSecondary)]
        }
    }

    private var displayName: String {
        let trimmed = item.recognizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "未知食物" {
            return "未识别食物"
        }
        return trimmed
    }

    private var summaryText: String {
        if let advice = item.cachedRecognition?.adviceText,
           !advice.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return advice
        }

        switch item.adviceLevel {
        case "recommended":
            return "当前信息更偏正向，可以打开卡片继续看更细的营养与建议。"
        case "caution":
            return "当前仍有不确定因素，建议打开卡片继续确认营养与影响细节。"
        case "avoid":
            return "当前风险提示偏高，建议打开卡片查看详细原因后再决定。"
        default:
            return "当前仍缺少明确营养基线，建议继续补拍角度或打开卡片查看详情。"
        }
    }

    private var cardFill: Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.76)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                imagePreview

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName)
                                .font(SafeEatFont.custom(28, relativeTo: .title2))
                                .foregroundStyle(SafeEatTheme.textPrimary)
                                .lineLimit(2)

                            Text("本地图片 · \(item.createdAt.homeTimeText)")
                                .font(SafeEatFont.custom(15, relativeTo: .body))
                                .foregroundStyle(SafeEatTheme.textSecondary)
                        }

                        Spacer(minLength: 8)

                        Text(AdviceLevelMapper.title(item.adviceLevel))
                            .font(SafeEatFont.custom(13, relativeTo: .subheadline))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(statusColor.opacity(0.14))
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 8) {
                        Text("衡量评分 \(item.foodScore)")
                            .font(SafeEatFont.custom(14, relativeTo: .footnote))
                            .foregroundStyle(SafeEatTheme.warning)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(SafeEatTheme.warning.opacity(0.12))
                            .clipShape(Capsule())

                        ForEach(Array(summaryChips.prefix(1).enumerated()), id: \.offset) { _, chip in
                            Text(chip.0)
                                .font(SafeEatFont.custom(14, relativeTo: .footnote))
                                .foregroundStyle(chip.1)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(chip.1.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(summaryText)
                        .font(SafeEatFont.custom(14, relativeTo: .body))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .lineLimit(2)
                }
            }

            Button(action: onOpenDetail) {
                Text("查看详情")
                    .font(SafeEatFont.custom(20, relativeTo: .headline))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
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
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(cardStroke, lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(0.10), radius: 22, y: 14)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .onTapGesture(perform: onOpenDetail)
    }

    @ViewBuilder
    private var imagePreview: some View {
        if let image = LocalImageLoader.loadStickerImage(for: item)
            ?? LocalImageLoader.loadDisplayImage(for: item) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 84, height: 84)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.34))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.45), lineWidth: 1)
                )
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.34))
                .frame(width: 84, height: 84)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(SafeEatTheme.textSecondary)
                }
        }
    }

    private func chipColor(level: String) -> Color {
        switch level {
        case "positive":
            return SafeEatTheme.success
        case "risk":
            return SafeEatTheme.danger
        case "caution":
            return SafeEatTheme.warning
        default:
            return SafeEatTheme.textSecondary
        }
    }
}

private extension Date {
    var homeTimeText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

#Preview {
    NavigationStack {
        ScanHomeView()
            .environmentObject(AppStore())
    }
}
