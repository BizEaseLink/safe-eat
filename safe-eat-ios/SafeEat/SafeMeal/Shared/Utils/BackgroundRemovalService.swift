import CoreImage
import UIKit
import Vision
import CoreImage.CIFilterBuiltins

enum BackgroundRemovalService {
    static func makePendingPreview(from image: UIImage) -> UIImage {
        image
            .normalizedUprightImage()
            .scaledDown(maxDimension: 540)
    }

    static func removeForegroundIfPossible(from image: UIImage) async -> UIImage {
        let normalizedImage = image.normalizedUprightImage()
        guard let imageData = normalizedImage.pngDataForPreview() else {
            return normalizedImage
        }

        return await Task.detached(priority: .userInitiated) {
            guard let detachedImage = UIImage(data: imageData) else {
                return UIImage(data: imageData)?.normalizedUprightImage() ?? UIImage()
            }

            return removeForegroundSync(from: detachedImage)
        }.value
    }

    private static func removeForegroundSync(from image: UIImage) -> UIImage {
        let normalizedImage = image.normalizedUprightImage()
        guard #available(iOS 17.0, *), let cgImage = normalizedImage.cgImage else {
            return normalizedImage
        }

        do {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])

            guard let result = request.results?.first else {
                return normalizedImage
            }

            let maskBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            let ciImage = CIImage(cgImage: cgImage)
            let maskImage = CIImage(cvPixelBuffer: maskBuffer)
            let clearBackground = CIImage(color: .clear).cropped(to: ciImage.extent)
            
            let filter = CIFilter.blendWithMask()
            filter.inputImage = ciImage
            filter.backgroundImage = clearBackground
            filter.maskImage = maskImage

            guard let output = filter.outputImage else {
                return normalizedImage
            }

            let context = CIContext()
            guard let renderedCGImage = context.createCGImage(output, from: output.extent) else {
                return normalizedImage
            }

            return UIImage(cgImage: renderedCGImage, scale: normalizedImage.scale, orientation: .up)
        } catch {
            return normalizedImage
        }
    }

    static func makePreviewImage(from image: UIImage, adviceLevel: String?) async -> UIImage {
        // 在小尺寸上做所有处理（540 足够预览显示）
        let displaySource = image.scaledDown(maxDimension: 540)
        let foreground = await removeForegroundIfPossible(from: displaySource)

        // foreground 有透明背景，必须用 PNG 传递给后续渲染（JPEG 会丢失 alpha）
        guard let foregroundData = foreground.pngData() else {
            return foreground
        }

        return await Task.detached(priority: .userInitiated) {
            guard let detachedForeground = UIImage(data: foregroundData) else {
                return foreground
            }

            // halo + sticker outline 在小尺寸上完成
            let accented = detachedForeground.haloPreviewImage(
                haloColor: AdviceLevelMapper.haloUIColor(adviceLevel),
                padding: 6,
                haloWidth: 4,
                softness: 1
            )

            return accented
                .stickerOutlineImage(borderColor: .white, padding: 6, borderWidth: 16, softness: 2)
        }.value
    }
}
