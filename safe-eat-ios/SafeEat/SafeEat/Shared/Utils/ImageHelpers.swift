import Combine
import Foundation
import SwiftUI
import UIKit

extension UIImage {
    func renderedPixelImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func normalizedUprightImage() -> UIImage {
        guard imageOrientation != .up else { return self }
        return renderedPixelImage()
    }

    func rotated(clockwise: Bool) -> UIImage {
        let baseImage = normalizedUprightImage()
        let targetSize = CGSize(width: baseImage.size.height, height: baseImage.size.width)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = baseImage.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: targetSize.width / 2, y: targetSize.height / 2)
            cgContext.rotate(by: clockwise ? (.pi / 2) : (-.pi / 2))
            baseImage.draw(in: CGRect(
                x: -baseImage.size.width / 2,
                y: -baseImage.size.height / 2,
                width: baseImage.size.width,
                height: baseImage.size.height
            ))
        }
    }

    func rotated180Degrees() -> UIImage {
        let baseImage = normalizedUprightImage()
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = baseImage.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: baseImage.size, format: format).image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: baseImage.size.width / 2, y: baseImage.size.height / 2)
            cgContext.rotate(by: .pi)
            baseImage.draw(in: CGRect(
                x: -baseImage.size.width / 2,
                y: -baseImage.size.height / 2,
                width: baseImage.size.width,
                height: baseImage.size.height
            ))
        }
    }

    func jpegDataForUpload() -> Data? {
        var workingImage = normalizedUprightImage().scaledDown(maxDimension: AppConfig.uploadImageMaxDimension)
        var compressionQuality: CGFloat = AppConfig.imageCompressionQuality
        var data = workingImage.jpegData(compressionQuality: compressionQuality)

        while let currentData = data, currentData.count > AppConfig.uploadImageTargetMaxBytes, compressionQuality > AppConfig.uploadImageMinQuality {
            compressionQuality -= 0.08
            data = workingImage.jpegData(compressionQuality: compressionQuality)
        }

        while let currentData = data, currentData.count > AppConfig.uploadImageTargetMaxBytes {
            let nextDimension = max(max(workingImage.size.width, workingImage.size.height) * 0.82, 640)
            guard nextDimension < max(workingImage.size.width, workingImage.size.height) else {
                break
            }
            workingImage = workingImage.scaledDown(maxDimension: nextDimension)
            data = workingImage.jpegData(compressionQuality: compressionQuality)
        }

        return data
    }

    func avatarUploadData() -> Data? {
        var workingImage = normalizedUprightImage().scaledDown(maxDimension: AppConfig.avatarMaxDimension)
        var compressionQuality: CGFloat = 0.88
        var data = workingImage.jpegData(compressionQuality: compressionQuality)

        while let currentData = data, currentData.count > AppConfig.avatarTargetMaxBytes, compressionQuality > 0.42 {
            compressionQuality -= 0.08
            data = workingImage.jpegData(compressionQuality: compressionQuality)
        }

        while let currentData = data, currentData.count > AppConfig.avatarTargetMaxBytes {
            let nextDimension = max(max(workingImage.size.width, workingImage.size.height) * 0.82, 320)
            guard nextDimension < max(workingImage.size.width, workingImage.size.height) else {
                break
            }
            workingImage = workingImage.scaledDown(maxDimension: nextDimension)
            data = workingImage.jpegData(compressionQuality: compressionQuality)
        }

        return data
    }

    func pngDataForPreview() -> Data? {
        normalizedUprightImage().pngData()
    }

    func scaledDown(maxDimension: CGFloat) -> UIImage {
        let baseImage = normalizedUprightImage()
        let longestSide = max(baseImage.size.width, baseImage.size.height)
        guard longestSide > maxDimension, longestSide > 0 else {
            return baseImage
        }

        let scaleRatio = maxDimension / longestSide
        let targetSize = CGSize(
            width: baseImage.size.width * scaleRatio,
            height: baseImage.size.height * scaleRatio
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            baseImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func loadingOverlayPreviewImage(maxDimension: CGFloat = 720) -> UIImage {
        let baseImage = normalizedUprightImage()
        let displayImage = baseImage.hasAlphaChannel ? baseImage.croppedToVisibleContent() : baseImage
        return displayImage.scaledDown(maxDimension: maxDimension)
    }

    func croppedToVisibleContent(alphaThreshold: UInt8 = 3) -> UIImage {
        let baseImage = normalizedUprightImage()
        guard baseImage.hasAlphaChannel else {
            return baseImage
        }

        let pixelImage = baseImage.renderedPixelImage()
        guard
            let cgImage = pixelImage.cgImage,
            let provider = cgImage.dataProvider,
            let providerData = provider.data,
            let rawData = CFDataGetBytePtr(providerData)
        else {
            return baseImage
        }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else {
            return baseImage
        }

        let bytesPerPixel = max(cgImage.bitsPerPixel / 8, 1)
        let bytesPerRow = cgImage.bytesPerRow

        let alphaOffset: Int
        switch cgImage.alphaInfo {
        case .premultipliedLast, .last, .noneSkipLast:
            alphaOffset = bytesPerPixel - 1
        case .premultipliedFirst, .first, .noneSkipFirst, .alphaOnly:
            alphaOffset = 0
        default:
            return baseImage
        }

        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1

        // 每 2 像素采样一次，减少 4 倍扫描量
        let step = 2
        for y in stride(from: 0, to: height, by: step) {
            let rowOffset = y * bytesPerRow
            for x in stride(from: 0, to: width, by: step) {
                let alpha = rawData[rowOffset + (x * bytesPerPixel) + alphaOffset]
                guard alpha > alphaThreshold else { continue }

                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }

        guard minX <= maxX, minY <= maxY else {
            return baseImage
        }

        // 扩展 1 像素补偿采样步长
        let cropRect = CGRect(
            x: max(minX - 1, 0),
            y: max(minY - 1, 0),
            width: min(maxX - minX + 2, width - minX + 1),
            height: min(maxY - minY + 2, height - minY + 1)
        ).integral

        guard let croppedImage = cgImage.cropping(to: cropRect) else {
            return baseImage
        }

        return UIImage(cgImage: croppedImage, scale: pixelImage.scale, orientation: .up)
    }

    func haloPreviewImage(
        haloColor: UIColor,
        padding: CGFloat = 10,
        haloWidth: CGFloat = 6,
        softness: CGFloat = 2
    ) -> UIImage {
        renderedHaloImage(
            haloColor: haloColor,
            padding: padding,
            haloWidth: haloWidth,
            softness: softness,
            intensity: 0.22,
            falloff: 1.6
        )
    }

    func stickerOutlineImage(
        borderColor: UIColor = .white,
        padding: CGFloat = 6,
        borderWidth: CGFloat = 24,
        softness: CGFloat = 6
    ) -> UIImage {
        renderedHaloImage(
            haloColor: borderColor,
            padding: padding,
            haloWidth: borderWidth,
            softness: softness,
            intensity: 0.34,
            falloff: 1.18
        )
    }

    private func renderedHaloImage(
        haloColor: UIColor,
        padding: CGFloat,
        haloWidth: CGFloat,
        softness: CGFloat,
        intensity: CGFloat,
        falloff: CGFloat
    ) -> UIImage {
        let baseImage = normalizedUprightImage().croppedToVisibleContent()
        guard baseImage.hasAlphaChannel else {
            return baseImage
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = baseImage.scale
        format.opaque = false

        let outerRadius = haloWidth + softness
        let canvasSize = CGSize(
            width: baseImage.size.width + (padding + outerRadius) * 2,
            height: baseImage.size.height + (padding + outerRadius) * 2
        )
        let baseRect = CGRect(
            x: padding + outerRadius,
            y: padding + outerRadius,
            width: baseImage.size.width,
            height: baseImage.size.height
        )
        let tinted = baseImage.withTintColor(haloColor, renderingMode: .alwaysOriginal)
        // 用更大的 step 减少绘制迭代次数（2.0 vs 0.75，减少约 7 倍迭代）
        let step = max(2.0, 1 / max(baseImage.scale, 1))

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in
            var dx = -outerRadius
            while dx <= outerRadius {
                var dy = -outerRadius
                while dy <= outerRadius {
                    let distance = sqrt((dx * dx) + (dy * dy))
                    if distance > 0, distance <= outerRadius {
                        let normalizedDistance = distance / outerRadius
                        let opacity = pow(max(0, 1 - normalizedDistance), falloff) * intensity
                        tinted.draw(in: baseRect.offsetBy(dx: dx, dy: dy), blendMode: .normal, alpha: opacity)
                    }
                    dy += step
                }
                dx += step
            }

            baseImage.draw(in: baseRect)
        }
    }
}

private extension UIImage {
    var hasAlphaChannel: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else {
            return false
        }

        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
            return true
        default:
            return false
        }
    }
}

enum LocalImageLoader {
    private static let stickerCache = NSCache<NSString, UIImage>()

    static func loadImage(from uri: String?) -> UIImage? {
        guard let uri else { return nil }

        if let fileURL = URL(string: uri), fileURL.isFileURL {
            return UIImage(contentsOfFile: fileURL.path)
        }

        return UIImage(contentsOfFile: uri)
    }

    static func loadDisplayImage(for item: LocalHistoryItem) -> UIImage? {
        guard let image = loadImage(from: item.displayImageUri) else {
            return nil
        }

        if item.previewImageUri != nil {
            return image.croppedToVisibleContent()
        }

        return image
    }

    static func loadStickerImage(for item: LocalHistoryItem) -> UIImage? {
        let cacheKey = "\(item.displayImageUri)#sticker" as NSString
        if let cached = stickerCache.object(forKey: cacheKey) {
            return cached
        }

        let image: UIImage?
        if let previewImageUri = item.previewImageUri {
            image = loadImage(from: previewImageUri)?.croppedToVisibleContent()
                ?? loadImage(from: item.originalImageUri)?.stickerOutlineImage(borderWidth: 30, softness: 5)
        } else {
            image = loadDisplayImage(for: item)?.stickerOutlineImage(borderWidth: 30, softness: 5)
        }

        guard let image else {
            return nil
        }

        stickerCache.setObject(image, forKey: cacheKey)
        return image
    }

    static func cachedStickerImage(for item: LocalHistoryItem) -> UIImage? {
        stickerCache.object(forKey: "\(item.displayImageUri)#sticker" as NSString)
    }

    static func loadOriginalImage(for item: LocalHistoryItem) -> UIImage? {
        loadImage(from: item.originalImageUri)
    }

    static func loadRawImage(for item: LocalHistoryItem) -> UIImage? {
        loadImage(from: item.rawImageUri) ?? loadImage(from: item.originalImageUri)
    }

    static func invalidateCache(for item: LocalHistoryItem) {
        stickerCache.removeObject(forKey: "\(item.displayImageUri)#sticker" as NSString)
    }

    static func clearAllCaches() {
        stickerCache.removeAllObjects()
    }
}

enum AdviceLevelMapper {
    static func title(_ level: String?) -> String {
        switch level {
        case "recommended":
            return SafeEatL10n.text(L10nKey.Advice.titleRecommended)
        case "moderate":
            return SafeEatL10n.text(L10nKey.Advice.titleModerate)
        case "caution":
            return SafeEatL10n.text(L10nKey.Advice.titleCaution)
        case "avoid":
            return SafeEatL10n.text(L10nKey.Advice.titleAvoid)
        default:
            return SafeEatL10n.text(L10nKey.Advice.titleEvaluate)
        }
    }

    static func color(_ level: String?) -> Color {
        switch level {
        case "recommended":
            return SafeEatTheme.success
        case "moderate":
            return SafeEatTheme.primary
        case "caution":
            return SafeEatTheme.warning
        case "avoid":
            return SafeEatTheme.danger
        default:
            return SafeEatTheme.textSecondary
        }
    }

    static func haloUIColor(_ level: String?) -> UIColor {
        switch level {
        case "recommended":
            return SafeEatTheme.successUIColor
        case "moderate":
            return SafeEatTheme.primaryUIColor
        case "caution":
            return SafeEatTheme.warningUIColor
        case "avoid":
            return SafeEatTheme.dangerUIColor
        default:
            return .white
        }
    }

    static func compactTitle(_ level: String?) -> String {
        switch level {
        case "recommended":
            return SafeEatL10n.text(L10nKey.Advice.compactRecommended)
        case "moderate":
            return SafeEatL10n.text(L10nKey.Advice.compactModerate)
        case "caution":
            return SafeEatL10n.text(L10nKey.Advice.compactCaution)
        case "avoid":
            return SafeEatL10n.text(L10nKey.Advice.compactAvoid)
        default:
            return SafeEatL10n.text(L10nKey.Advice.compactEvaluate)
        }
    }

    static func menuSummary(level: String?, adviceText: String?) -> String {
        if let adviceText, !adviceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return adviceText
        }

        switch level {
        case "recommended":
            return SafeEatL10n.text(L10nKey.Advice.summaryRecommended)
        case "moderate":
            return SafeEatL10n.text(L10nKey.Advice.summaryModerate)
        case "caution":
            return SafeEatL10n.text(L10nKey.Advice.summaryCaution)
        case "avoid":
            return SafeEatL10n.text(L10nKey.Advice.summaryAvoid)
        default:
            return SafeEatL10n.text(L10nKey.Advice.summaryEvaluate)
        }
    }
}

enum StickerTextFormatter {
    static func score(_ value: Int) -> String {
        SafeEatL10n.format(L10nKey.Common.scoreUnitFormat, value)
    }

    static func adviceScore(level: String?, score: Int) -> String {
        SafeEatL10n.format(
            L10nKey.Common.adviceScoreFormat,
            AdviceLevelMapper.compactTitle(level),
            score
        )
    }

    static func adviceScore(for item: LocalHistoryItem) -> String {
        adviceScore(level: item.adviceLevel, score: item.foodScore)
    }

    static func isScoreTag(_ text: String) -> Bool {
        let normalized = text.lowercased()
        return normalized.rangeOfCharacter(from: .decimalDigits) != nil
            && (normalized.contains("pts") || normalized.contains("分"))
    }
}

private enum StickerPalette {
    static let paperBackgroundLight = Color(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0)
    static let paperIconLight = Color(red: 228.0 / 255.0, green: 228.0 / 255.0, blue: 228.0 / 255.0)
    static let paperBackgroundDark = Color(red: 30.0 / 255.0, green: 30.0 / 255.0, blue: 30.0 / 255.0)
    static let paperIconDark = Color(red: 68.0 / 255.0, green: 68.0 / 255.0, blue: 68.0 / 255.0)
    static let loaderIconLight = SafeEatTheme.primary
    static let loaderIconDark = SafeEatTheme.accent
    static let labelText = SafeEatTheme.textPrimary
    static let subtleText = SafeEatTheme.textSecondary
}

struct StickerPaperBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    private let patternSize = CGSize(width: 14, height: 14)
    private let horizontalSpacing: CGFloat = 92
    private let verticalSpacing: CGFloat = 88

    var body: some View {
        ZStack {
            backgroundColor

            Canvas { context, size in
                guard let symbol = context.resolveSymbol(id: 0) else { return }

                var rowIndex = 0
                for y in stride(from: verticalSpacing * 0.5, through: size.height + verticalSpacing, by: verticalSpacing) {
                    let rowOffset = rowIndex.isMultiple(of: 2) ? 0 : horizontalSpacing * 0.5
                    for x in stride(from: horizontalSpacing * 0.5 + rowOffset, through: size.width + horizontalSpacing, by: horizontalSpacing) {
                        context.draw(symbol, at: CGPoint(x: x, y: y))
                    }
                    rowIndex += 1
                }
            } symbols: {
                Image("AvocadoPattern")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(iconColor)
                    .frame(width: patternSize.width, height: patternSize.height)
                    .tag(0)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? StickerPalette.paperBackgroundDark : StickerPalette.paperBackgroundLight
    }

    private var iconColor: Color {
        colorScheme == .dark ? StickerPalette.paperIconDark : StickerPalette.paperIconLight
    }
}

struct SafeEatDottedRecordBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    private let dotSpacing: CGFloat = 18
    private let dotRadius: CGFloat = 1.5

    var body: some View {
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
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.16 : 0.42),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 18,
                endRadius: 320
            )

            Canvas { context, size in
                let dotColor = colorScheme == .dark
                    ? UIColor.white.withAlphaComponent(0.08)
                    : UIColor(red: 0.80, green: 0.84, blue: 0.82, alpha: 0.68)

                for y in stride(from: dotSpacing * 0.5, through: size.height + dotSpacing, by: dotSpacing) {
                    for x in stride(from: dotSpacing * 0.5, through: size.width + dotSpacing, by: dotSpacing) {
                        let rect = CGRect(
                            x: x - dotRadius,
                            y: y - dotRadius,
                            width: dotRadius * 2,
                            height: dotRadius * 2
                        )
                        context.fill(Path(ellipseIn: rect), with: .color(Color(dotColor)))
                    }
                }
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct SafeEatLoadingOverlay: View {
    @Environment(\.colorScheme) private var colorScheme

    let phase: RecognitionPhase
    var previewImage: UIImage? = nil
    /// (foodId, name, sessionId):foodId 与 name 互斥。选 DB food 传 foodId,选 AI 名走草稿传 name
    var onCandidateSelected: ((String?, String?, String) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil

    // 小贴士循环切换
    @State private var tipIndex: Int = 0

    private let tips: [(title: String, content: String)] = [
        (SafeEatL10n.text(L10nKey.RecognitionPhase.tip), SafeEatL10n.text(L10nKey.RecognitionPhase.tipContent1)),
        (SafeEatL10n.text(L10nKey.RecognitionPhase.tip), SafeEatL10n.text(L10nKey.RecognitionPhase.tipContent2)),
        (SafeEatL10n.text(L10nKey.RecognitionPhase.tip), SafeEatL10n.text(L10nKey.RecognitionPhase.tipContent3)),
        (SafeEatL10n.text(L10nKey.RecognitionPhase.tip), SafeEatL10n.text(L10nKey.RecognitionPhase.tipContent4)),
    ]

    // 标题跑马灯
    @State private var dotPhase: Int = 0
    @State private var dotTimer: Timer?

    // 小贴士随机起始，点击顺序切换

    // 树展开状态:可展开 AI 父项的 name 集合
    @State private var expandedAiNames: Set<String> = []

    private var brandLabelColor: Color {
        colorScheme == .dark ? Color(red: 0.67, green: 0.86, blue: 0.73) : SafeEatTheme.primaryDeep
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

    private var panelFill: LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.08), Color.white.opacity(0.04)]
                : [Color.white.opacity(0.88), Color.white.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var panelStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : SafeEatTheme.line
    }

    var body: some View {
        ZStack {
            loadingBackground

            VStack(spacing: 0) {
                // 品牌 pill
                HStack {
                    brandPill
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)

                Spacer(minLength: 12)

                // 主面板
                mainPanel

                // 底部标签
                HStack(spacing: 10) {
                    footerPill(SafeEatL10n.text(L10nKey.Home.heroTagHealth))
                    footerPill(SafeEatL10n.text(L10nKey.Home.heroTagHistory))
                }
                .padding(.top, 24)
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            tipIndex = Int.random(in: 0..<tips.count)
            startDotAnimation()
        }
        .onDisappear {
            dotTimer?.invalidate()
        }
    }

    // MARK: - 主面板

    @ViewBuilder
    private var mainPanel: some View {
        switch phase {
        case .identifying:
            panelContainer {
                phaseTitle(SafeEatL10n.text(L10nKey.RecognitionPhase.identifying))
                previewStage
            }

        case .selecting(let candidates, let dbMatches, let sessionId):
            panelContainer {
                phaseTitle(SafeEatL10n.text(L10nKey.RecognitionPhase.selectTitle))
                phaseSubtitle(SafeEatL10n.text(L10nKey.RecognitionPhase.selectSubtitle))
                previewStageCompact
                candidateList(candidates: candidates, dbMatches: dbMatches, sessionId: sessionId)
            }

        case .evaluating:
            panelContainer {
                phaseTitle(SafeEatL10n.text(L10nKey.RecognitionPhase.evaluating))
                phaseSubtitle(SafeEatL10n.text(L10nKey.RecognitionPhase.evaluatingSubtitle))
                RecognitionRingAnimation()
            }

        case .nonFood:
            panelContainer {
                phaseTitle(SafeEatL10n.text(L10nKey.RecognitionPhase.nonFoodTitle))
                phaseSubtitle(SafeEatL10n.text(L10nKey.RecognitionPhase.nonFoodSubtitle))
                previewStageCompact
                Button {
                    onDismiss?()
                } label: {
                    Text(SafeEatL10n.text(L10nKey.Common.ok))
                        .font(SafeEatFont.custom(16, relativeTo: .body, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [SafeEatTheme.primaryDeep, SafeEatTheme.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func panelContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 18) {
                    content()
                }
                .padding(24)
            }
            .scrollDisabled({
                if case .selecting = phase { return false }
                return true
            }())
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity)

            // 小贴士固定在面板底部
            tipCard
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
        .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.22 : 0.12), radius: 24, y: 16)
        .padding(.horizontal, 20)
    }

    // MARK: - 阶段标题 / 副标题

    private func phaseTitle(_ text: String) -> some View {
        HStack(spacing: 4) {
            // 左侧加载指示点
            loadingDot(index: 2)
            loadingDot(index: 1)

            Text(text)
                .font(SafeEatFont.custom(26, relativeTo: .title2, weight: .bold))
                .foregroundStyle(SafeEatTheme.textPrimary)

            // 右侧加载指示点
            loadingDot(index: 0)
            loadingDot(index: 1)
        }
    }

    private func loadingDot(index: Int) -> some View {
        Circle()
            .fill(SafeEatTheme.primary)
            .frame(width: 4, height: 4)
            .opacity(dotPhase == index ? 1.0 : 0.25)
            .animation(.easeInOut(duration: 0.3), value: dotPhase)
    }

    private func phaseSubtitle(_ text: String) -> some View {
        Text(text)
            .font(SafeEatFont.textStyle(.subheadline))
            .foregroundStyle(SafeEatTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }

    // MARK: - 预览图

    private var previewStage: some View {
        ZStack {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 260)
                    .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.24 : 0.12), radius: 18, y: 10)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(SafeEatTheme.primary.opacity(0.68))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
    }

    /// 候选选择阶段的紧凑预览图
    private var previewStageCompact: some View {
        ZStack {
            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 120)
                    .shadow(color: SafeEatTheme.primaryDeep.opacity(colorScheme == .dark ? 0.24 : 0.12), radius: 10, y: 6)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            } else {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(SafeEatTheme.primary.opacity(0.68))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
    }

    // MARK: - 候选列表

    /// 树状:AI 候选作父项,其命中的 DB 作子项按 matchedAiName 分组
    /// 子项=0 或 1 → 父项直进(无箭头);子项≥2 → 展开(有箭头),子项点选传 foodId
    private func candidateList(candidates: [IdentifyCandidate], dbMatches: [DbMatch], sessionId: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(candidates) { candidate in
                let children = dbMatches.filter { $0.matchedAiName == candidate.name }
                candidateTreeRow(candidate: candidate, children: children, sessionId: sessionId)
            }
        }
    }

    /// 父项:有≥2 子项才展开+箭头;否则直进(0 子项走草稿传 name,1 子项传 foodId)
    private func candidateTreeRow(candidate: IdentifyCandidate, children: [DbMatch], sessionId: String) -> some View {
        let expandable = children.count >= 2
        let isExpanded = expandedAiNames.contains(candidate.name)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                if expandable {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        if isExpanded {
                            expandedAiNames.remove(candidate.name)
                        } else {
                            expandedAiNames.insert(candidate.name)
                        }
                    }
                } else if children.count == 1 {
                    // 单子项直进:传该 foodId
                    onCandidateSelected?(children[0].foodId, nil, sessionId)
                } else {
                    // 无子项直进:走草稿传 AI 名
                    onCandidateSelected?(nil, candidate.name, sessionId)
                }
            } label: {
                aiParentRow(candidate: candidate, expandable: expandable, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)

            if expandable && isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(children) { match in
                        dbChildRow(match, sessionId: sessionId)
                    }
                }
                .padding(.leading, 16)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity
                    )
                )
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isExpanded)
    }

    private func aiParentRow(candidate: IdentifyCandidate, expandable: Bool, isExpanded: Bool) -> some View {
        let percent = Int((candidate.confidence * 100).rounded())

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(SafeEatTheme.line, lineWidth: 3)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: candidate.confidence)
                    .stroke(
                        confidenceColor(candidate.confidence),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("\(percent)%")
                    .font(SafeEatFont.custom(11, relativeTo: .caption2, weight: .semibold))
                    .foregroundColor(SafeEatTheme.textPrimary)
            }

            Text(candidate.name)
                .font(SafeEatFont.textStyle(.body))
                .foregroundColor(SafeEatTheme.textPrimary)

            Spacer()

            if expandable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SafeEatTheme.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(SafeEatTheme.line, lineWidth: 1)
        )
    }

    private func dbChildRow(_ match: DbMatch, sessionId: String) -> some View {
        return Button {
            onCandidateSelected?(match.foodId, nil, sessionId)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 16))
                    .foregroundColor(SafeEatTheme.primary)
                    .frame(width: 40, height: 40)

                Text(match.canonicalName)
                    .font(SafeEatFont.textStyle(.body))
                    .foregroundColor(SafeEatTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SafeEatTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SafeEatTheme.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return SafeEatTheme.success }
        if confidence >= 0.5 { return SafeEatTheme.warning }
        return SafeEatTheme.danger
    }

    // MARK: - 识别小贴士

    private var tipCard: some View {
        let current = tips[tipIndex % tips.count]

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                tipIndex = (tipIndex + 1) % tips.count
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SafeEatTheme.warning)

                VStack(alignment: .leading, spacing: 3) {
                    Text(current.title)
                        .font(SafeEatFont.custom(14, relativeTo: .subheadline, weight: .bold))
                        .foregroundStyle(SafeEatTheme.textPrimary)
                    Text(current.content)
                        .font(SafeEatFont.custom(13, relativeTo: .caption))
                        .foregroundStyle(SafeEatTheme.textSecondary)
                        .id(tipIndex)
                        .transition(.opacity)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SafeEatTheme.textSecondary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.08 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(SafeEatTheme.warning.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 背景 & 品牌元素

    private var loadingBackground: some View {
        ZStack {
            SafeEatMainGradientBackground()

            RadialGradient(
                colors: [
                    SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.16 : 0.34),
                    Color.clear,
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 360
            )

            SafeEatDottedRecordBackground()
                .opacity(colorScheme == .dark ? 0.26 : 0.38)

            LinearGradient(
                colors: [
                    Color.black.opacity(colorScheme == .dark ? 0.24 : 0.04),
                    Color.black.opacity(colorScheme == .dark ? 0.10 : 0.02),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var brandPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(SafeEatTheme.primary.opacity(0.22))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .fill(SafeEatTheme.primary)
                        .frame(width: 8, height: 8)
                )

            Text(SafeEatL10n.text(L10nKey.Home.brandPill))
                .font(SafeEatFont.custom(16, relativeTo: .headline))
                .foregroundStyle(brandLabelColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(topPillFill)
        )
        .overlay(
            Capsule()
                .stroke(topPillStroke, lineWidth: 1)
        )
    }

    private func footerPill(_ text: String) -> some View {
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

    // MARK: - 跑马灯动画

    private func startDotAnimation() {
        dotTimer?.invalidate()
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}

struct StickerTextBubble: View {
    let text: String
    let font: Font
    var maxWidth: CGFloat? = nil
    var lineLimit: Int? = nil
    var textColor: Color = StickerPalette.labelText
    var horizontalPadding: CGFloat = 9
    var verticalPadding: CGFloat = 3

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.11), radius: 10, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white, lineWidth: 4)
            )
            .frame(maxWidth: maxWidth)
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum RecognitionStickerThumbnailStyle {
    case card
    case floating
}

struct RecognitionStickerThumbnailView: View {
    @Environment(\.colorScheme) private var colorScheme

    let stickerImage: UIImage?
    let titleText: String
    let metaText: String?
    var imageHeight: CGFloat
    var labelMaxWidth: CGFloat
    var style: RecognitionStickerThumbnailStyle

    init(item: LocalHistoryItem, imageHeight: CGFloat, labelMaxWidth: CGFloat) {
        self.stickerImage = LocalImageLoader.loadStickerImage(for: item)
        self.titleText = item.recognizedName
        self.metaText = StickerTextFormatter.adviceScore(for: item)
        self.imageHeight = imageHeight
        self.labelMaxWidth = labelMaxWidth
        self.style = .card
    }

    init(
        image: UIImage?,
        titleText: String,
        metaText: String?,
        imageHeight: CGFloat,
        labelMaxWidth: CGFloat,
        style: RecognitionStickerThumbnailStyle = .card
    ) {
        self.stickerImage = image
        self.titleText = titleText
        self.metaText = metaText
        self.imageHeight = imageHeight
        self.labelMaxWidth = labelMaxWidth
        self.style = style
    }

    var body: some View {
        Group {
            switch style {
            case .card:
                cardBody
            case .floating:
                floatingBody
            }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(cardBackground)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(imagePanelBackground)
                    .padding(12)

                stickerImage(height: imageHeight)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: imageHeight + 34)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(cardStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.12 : 0.08), radius: 14, y: 8)

            VStack(spacing: 7) {
                Text(displayTitle)
                    .font(SafeEatFont.custom(17, relativeTo: .headline, weight: .bold))
                    .foregroundStyle(SafeEatTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: labelMaxWidth)

                HStack(spacing: 8) {
                    ForEach(Array(metaTags.prefix(2).enumerated()), id: \.offset) { index, tag in
                        Text(tag)
                            .font(SafeEatFont.custom(12, relativeTo: .caption, weight: .bold))
                            .foregroundStyle(metaTextColor(for: index, text: tag))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(metaBackgroundColor(for: index, text: tag))
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var floatingBody: some View {
        VStack(alignment: .center, spacing: 0) {
            stickerImage(height: imageHeight)
                .frame(maxWidth: .infinity)

            VStack(spacing: 6) {
                StickerTextBubble(
                    text: displayTitle,
                    font: SafeEatFont.custom(17, relativeTo: .headline, weight: .bold),
                    maxWidth: labelMaxWidth,
                    lineLimit: 2,
                    textColor: SafeEatTheme.primaryDeep,
                    horizontalPadding: 12,
                    verticalPadding: 5
                )

                if !metaTags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(Array(metaTags.prefix(2).enumerated()), id: \.offset) { index, tag in
                            StickerTextBubble(
                                text: tag,
                                font: SafeEatFont.custom(12, relativeTo: .caption, weight: .bold),
                                maxWidth: nil,
                                lineLimit: 1,
                                textColor: metaBubbleTextColor(for: index, text: tag),
                                horizontalPadding: 10,
                                verticalPadding: 4
                            )
                        }
                    }
                }
            }
            .offset(y: -8)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func stickerImage(height: CGFloat) -> some View {
        if let stickerImage {
            Image(uiImage: stickerImage)
                .resizable()
                .scaledToFit()
                .frame(height: height)
                .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .frame(height: height)
                .overlay {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
        }
    }

    private var displayTitle: String {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? SafeEatL10n.text(L10nKey.Common.unnamed) : trimmed
    }

    private var metaTags: [String] {
        guard let metaText else { return [] }

        let tags = metaText
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if tags.count == 2,
           StickerTextFormatter.isScoreTag(tags[0]),
           !StickerTextFormatter.isScoreTag(tags[1]) {
            return [tags[1], tags[0]]
        }
        return tags
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.16, blue: 0.19).opacity(0.88)
            : Color.white.opacity(0.78)
    }

    private var imagePanelBackground: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.04)
            : Color(red: 0.97, green: 0.98, blue: 0.97)
    }

    private var cardStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : SafeEatTheme.line
    }

    private func metaTextColor(for index: Int, text: String) -> Color {
        if StickerTextFormatter.isScoreTag(text) {
            return SafeEatTheme.warning
        }
        return index == 0 ? SafeEatTheme.primaryDeep : SafeEatTheme.textSecondary
    }

    private func metaBackgroundColor(for index: Int, text: String) -> Color {
        if StickerTextFormatter.isScoreTag(text) {
            return SafeEatTheme.warning.opacity(colorScheme == .dark ? 0.20 : 0.14)
        }
        if index == 0 {
            return SafeEatTheme.primarySoft.opacity(colorScheme == .dark ? 0.22 : 0.78)
        }
        return colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)
    }

    private func metaBubbleTextColor(for index: Int, text: String) -> Color {
        if StickerTextFormatter.isScoreTag(text) {
            return SafeEatTheme.warning
        }
        return index == 0 ? SafeEatTheme.primaryDeep : SafeEatTheme.textSecondary
    }
}

struct RecognitionStickerExpandedView: View {
    let item: LocalHistoryItem
    let isFlipped: Bool
    let maxSize: CGSize

    var body: some View {
        let width = min(maxSize.width * 0.5, 300)
        let height = min(maxSize.height * 0.5, 360)

        ZStack {
            frontSide(width: width, height: height)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            backSide(width: width, height: height)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(width: width, height: height)
    }

    private func frontSide(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 12) {
            RecognitionStickerThumbnailView(
                image: LocalImageLoader.loadStickerImage(for: item),
                titleText: item.recognizedName,
                metaText: StickerTextFormatter.adviceScore(for: item),
                imageHeight: height * 0.56,
                labelMaxWidth: width * 0.82
            )

            StickerTextBubble(
                text: SafeEatL10n.text(L10nKey.Sticker.swipeHint),
                font: SafeEatFont.custom(12, relativeTo: .caption),
                maxWidth: width * 0.58,
                lineLimit: 1,
                textColor: StickerPalette.subtleText
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func backSide(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 10) {
            StickerTextBubble(
                text: SafeEatL10n.text(L10nKey.Sticker.resultTitle),
                font: SafeEatFont.custom(13, relativeTo: .footnote),
                maxWidth: width * 0.44,
                lineLimit: 1
            )

            StickerTextBubble(
                text: item.recognizedName,
                font: SafeEatFont.custom(20, relativeTo: .title3),
                maxWidth: width * 0.82,
                lineLimit: 3
            )

            HStack(spacing: 10) {
                StickerTextBubble(
                    text: StickerTextFormatter.score(item.foodScore),
                    font: SafeEatFont.custom(12, relativeTo: .caption),
                    maxWidth: width * 0.28,
                    lineLimit: 1,
                    textColor: StickerPalette.subtleText
                )

                StickerTextBubble(
                    text: AdviceLevelMapper.compactTitle(item.adviceLevel),
                    font: SafeEatFont.custom(12, relativeTo: .caption),
                    maxWidth: width * 0.32,
                    lineLimit: 1,
                    textColor: StickerPalette.subtleText
                )
            }

            StickerTextBubble(
                text: item.createdAt.historyTimestampText,
                font: SafeEatFont.custom(11, relativeTo: .caption2),
                maxWidth: width * 0.72,
                lineLimit: 1,
                textColor: StickerPalette.subtleText
            )

            StickerTextBubble(
                text: AdviceLevelMapper.menuSummary(level: item.adviceLevel, adviceText: item.adviceText),
                font: SafeEatFont.custom(12, relativeTo: .caption),
                maxWidth: width * 0.84,
                lineLimit: 5
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Date {
    var historyTimestampText: String {
        let formatter = DateFormatter()
        formatter.locale = AppSettingsStore.shared.displayLocale
        formatter.dateFormat = AppSettingsStore.shared.language == .en ? "MMM d HH:mm" : "MM 月 dd 日 HH:mm"
        return formatter.string(from: self)
    }
}
