import AVFoundation
import CoreImage
import ImageIO
import UIKit

/// 方向扶正工具：EXIF 为主 + UIDevice.orientation 兜底，方向只算一次。
/// 拍照和相册复用同一套逻辑，裁切不读方向、扶正才用。
enum OrientationBaker {
    // MARK: - 记方向（只算一次）

    /// 拍照路径：从 photo.metadata 取 EXIF Orientation，缺失走 imageSourceOrientation，再缺失 UIDevice 兜底。
    nonisolated static func resolveOrientationForCapture(
        photo: AVCapturePhoto,
        data: Data
    ) -> CGImagePropertyOrientation {
        if let raw = (photo.metadata[kCGImagePropertyOrientation as String] as? UInt32),
           let orientation = CGImagePropertyOrientation(rawValue: raw) {
            return orientation
        }

        if let raw = imageSourceOrientation(from: data),
           let orientation = CGImagePropertyOrientation(rawValue: raw) {
            return orientation
        }

        return orientationFromDevice()
    }

    /// 相册路径：从 UIImage.imageOrientation 映射到 EXIF orientation，缺失 UIDevice 兜底。
    nonisolated static func resolveOrientationForAlbum(image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return orientationFromDevice()
        }
    }

    // MARK: - 扶正（用记下的方向重绘到 .up）

    /// 用算好的 orientation 把 UIImage 重绘成 .up，返回 bakedImage。
    /// - 前置摄像头镜像：若 orientation 是 mirrored 变体，CIImage.oriented 已处理镜像，不再二次镜像。
    nonisolated static func bake(
        _ image: UIImage,
        to orientation: CGImagePropertyOrientation
    ) -> UIImage? {
        guard let cgImage = image.cgImage else {
            return image.normalizedUprightImage()
        }

        let ciImage = CIImage(cgImage: cgImage)
        let oriented = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))

        let ciContext = CIContext()
        guard let bakedCG = ciContext.createCGImage(oriented, from: oriented.extent) else {
            return image.normalizedUprightImage()
        }

        return UIImage(cgImage: bakedCG, scale: UIScreen.main.scale, orientation: .up)
    }

    /// 拍照路径专用：直接从 JPEG data + EXIF orientation 重绘到 .up（复用原 bakedCaptureImage 逻辑）。
    /// 裁切在扶正之前，需要先把原始 data 解成未扶正的 UIImage 供裁切，再用此方法扶正裁切后的图。
    nonisolated static func bakeCaptureData(
        data: Data,
        orientation: CGImagePropertyOrientation
    ) -> UIImage? {
        guard let ciImage = CIImage(data: data, options: [.applyOrientationProperty: false]) else {
            return UIImage(data: data)?.normalizedUprightImage()
        }

        let oriented = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(oriented, from: oriented.extent) else {
            return UIImage(data: data)?.normalizedUprightImage()
        }

        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }

    /// 从原始 JPEG data 解出未扶正的 UIImage（供裁切使用，裁切用原始坐标不碰方向）。
    nonisolated static func rawImage(from data: Data) -> UIImage? {
        guard let ciImage = CIImage(data: data, options: [.applyOrientationProperty: false]),
              let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage(data: data)
        }
        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }

    // MARK: - 调试辅助

    /// 记录扶正角度（0/90/180/270），当前管道不强制用，保留供调试/对齐预览。
    nonisolated static func appliedRotationAngle(for orientation: CGImagePropertyOrientation) -> Int {
        switch orientation {
        case .up, .upMirrored: return 0
        case .left, .leftMirrored: return 90
        case .down, .downMirrored: return 180
        case .right, .rightMirrored: return 270
        @unknown default: return 0
        }
    }

    // MARK: - 私有

    /// UIDevice.orientation 兜底：EXIF 缺失时用设备姿态推断。
    private nonisolated static func orientationFromDevice() -> CGImagePropertyOrientation {
        // 在后台线程访问 UIDevice.orientation 不够可靠，且 AVCapturePhoto 基本都带 EXIF，
        // 这里只作最后兜底，默认 .up。
        switch UIDevice.current.orientation {
        case .landscapeLeft: return .right
        case .landscapeRight: return .left
        case .portraitUpsideDown: return .down
        default: return .up
        }
    }

    private nonisolated static func imageSourceOrientation(from data: Data) -> UInt32? {
        guard
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        else {
            return nil
        }
        return properties[kCGImagePropertyOrientation] as? UInt32
    }
}
