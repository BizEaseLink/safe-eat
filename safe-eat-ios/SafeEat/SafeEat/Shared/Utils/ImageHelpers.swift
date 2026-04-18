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
        normalizedUprightImage().jpegData(compressionQuality: AppConfig.imageCompressionQuality)
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

        for y in 0 ..< height {
            let rowOffset = y * bytesPerRow
            for x in 0 ..< width {
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

        let cropRect = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
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
        let step = max(0.75, 1 / max(baseImage.scale, 1))

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

    static func loadOriginalImage(for item: LocalHistoryItem) -> UIImage? {
        loadImage(from: item.originalImageUri)
    }

    static func loadRawImage(for item: LocalHistoryItem) -> UIImage? {
        loadImage(from: item.rawImageUri) ?? loadImage(from: item.originalImageUri)
    }

    static func invalidateCache(for item: LocalHistoryItem) {
        stickerCache.removeObject(forKey: "\(item.displayImageUri)#sticker" as NSString)
    }
}

enum AdviceLevelMapper {
    static func title(_ level: String?) -> String {
        switch level {
        case "recommended":
            return "推荐食用"
        case "caution":
            return "谨慎食用"
        case "avoid":
            return "不建议食用"
        default:
            return "建议评估"
        }
    }

    static func color(_ level: String?) -> Color {
        switch level {
        case "recommended":
            return SafeEatTheme.success
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
            return "推荐"
        case "caution":
            return "谨慎"
        case "avoid":
            return "避免"
        default:
            return "评估"
        }
    }

    static func menuSummary(level: String?, adviceText: String?) -> String {
        if let adviceText, !adviceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return adviceText
        }

        switch level {
        case "recommended":
            return "整体更适合当前饮食方向，可以作为这次的优先选择。"
        case "caution":
            return "可以继续吃，但建议控制份量，并留意搭配与频率。"
        case "avoid":
            return "当前更不建议继续食用，优先换成更稳妥的选择。"
        default:
            return "建议结合身体状态和本次搭配，再做进一步判断。"
        }
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

struct SafeEatLoadingOverlay: View {
    var title: String
    var subtitle: String? = nil

    var body: some View {
        ZStack {
            loadingBackground

            VStack(spacing: 24) {
                AvocadoLoadingView()

                VStack(spacing: 8) {
                    Text(title)
                        .font(SafeEatFont.custom(22, relativeTo: .title3))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(SafeEatFont.textStyle(.subheadline))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(28)
        }
        .ignoresSafeArea()
    }

    private var loadingBackground: some View {
        Color(.systemBackground)
    }
}

private struct AvocadoLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase = 0

    private let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()
    private let layerScales: [CGFloat] = [0.44, 0.62, 0.80, 1.0]

    var body: some View {
        ZStack {
            ForEach(Array(layerScales.enumerated()), id: \.offset) { index, scale in
                Image("AvocadoPattern")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132 * scale, height: 132 * scale)
                    .foregroundStyle(loaderColor)
                    .opacity(layerOpacity(for: index))
                    .scaleEffect(layerScaleEffect(for: index))
                    .shadow(color: loaderColor.opacity(0.16), radius: 8, y: 4)
            }
        }
        .frame(width: 150, height: 150)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = (phase + 1) % 9
            }
        }
    }

    private var visibleLayerCount: Int {
        switch phase {
        case 0:
            return 0
        case 1 ... 4:
            return phase
        default:
            return max(0, 8 - phase)
        }
    }

    private var loaderColor: Color {
        colorScheme == .dark ? StickerPalette.loaderIconDark : StickerPalette.loaderIconLight
    }

    private func layerOpacity(for index: Int) -> Double {
        index < visibleLayerCount ? 1 : 0
    }

    private func layerScaleEffect(for index: Int) -> CGFloat {
        index < visibleLayerCount ? 1 : 0.92
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

struct RecognitionStickerThumbnailView: View {
    let stickerImage: UIImage?
    let titleText: String
    let metaText: String?
    var imageHeight: CGFloat
    var labelMaxWidth: CGFloat

    init(item: LocalHistoryItem, imageHeight: CGFloat, labelMaxWidth: CGFloat) {
        self.stickerImage = LocalImageLoader.loadStickerImage(for: item)
        self.titleText = item.recognizedName
        self.metaText = "\(item.foodScore) 分 · \(AdviceLevelMapper.compactTitle(item.adviceLevel))"
        self.imageHeight = imageHeight
        self.labelMaxWidth = labelMaxWidth
    }

    init(image: UIImage?, titleText: String, metaText: String?, imageHeight: CGFloat, labelMaxWidth: CGFloat) {
        self.stickerImage = image
        self.titleText = titleText
        self.metaText = metaText
        self.imageHeight = imageHeight
        self.labelMaxWidth = labelMaxWidth
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            stickerImage(height: imageHeight)

            VStack(spacing: -2) {
                ForEach(titleTags, id: \.self) { tag in
                    StickerTextBubble(
                        text: tag,
                        font: SafeEatFont.custom(19, relativeTo: .headline),
                        maxWidth: labelMaxWidth,
                        lineLimit: 1,
                        horizontalPadding: 11,
                        verticalPadding: 4
                    )
                }

                if !metaTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(metaTags, id: \.self) { tag in
                            StickerTextBubble(
                                text: tag,
                                font: SafeEatFont.custom(11, relativeTo: .caption2),
                                lineLimit: 1,
                                textColor: StickerPalette.subtleText,
                                horizontalPadding: 8,
                                verticalPadding: 3
                            )
                        }
                    }
                    .frame(maxWidth: labelMaxWidth)
                    .padding(.top, 6)
                }
            }
            .offset(y: metaTags.isEmpty ? 18 : 28)
        }
        .padding(.bottom, metaTags.isEmpty ? 30 : 54)
        .frame(maxWidth: .infinity)
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

    private var titleTags: [String] {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ["未命名"] }

        let words = trimmed
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }
        if !words.isEmpty {
            if words.count <= 3 {
                return words
            }

            return Array(words.prefix(2)) + [words.dropFirst(2).joined(separator: " ")]
        }

        let characters = Array(trimmed)
        let chunkSize = characters.count > 8 ? 4 : 3
        return stride(from: 0, to: characters.count, by: chunkSize)
            .map { startIndex in
                let endIndex = min(startIndex + chunkSize, characters.count)
                return String(characters[startIndex..<endIndex])
            }
            .prefix(3)
            .map { $0 }
    }

    private var metaTags: [String] {
        guard let metaText else { return [] }

        return metaText
            .split(separator: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
                metaText: "\(item.foodScore) 分 · \(AdviceLevelMapper.compactTitle(item.adviceLevel))",
                imageHeight: height * 0.56,
                labelMaxWidth: width * 0.82
            )

            StickerTextBubble(
                text: "左右滑动查看结果",
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
                text: "识别结果",
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
                    text: "\(item.foodScore) 分",
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM 月 dd 日 HH:mm"
        return formatter.string(from: self)
    }
}
