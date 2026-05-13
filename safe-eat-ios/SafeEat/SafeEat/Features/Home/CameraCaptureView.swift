import AVFoundation
import Combine
import CoreImage
import ImageIO
import SwiftUI
import UIKit

struct CameraCapturePayload {
    let croppedImage: UIImage
    let rawImage: UIImage
}

struct CameraCaptureView: View {
    let onCapture: (CameraCapturePayload) -> Void

    private let previewRotationAngle: CGFloat = 90
    private let topBarHeight: CGFloat = 72
    private let bottomBarHeight: CGFloat = 188

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var camera = CameraSessionModel()
    @State private var pendingCapturedImage: CameraCapturePayload?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    cameraTopBar(topInset: proxy.safeAreaInsets.top)

                    ZStack {
                        if camera.authorizationStatus == .authorized, camera.isConfigured {
                            CameraPreview(
                                session: camera.session,
                                rotationAngle: previewRotationAngle,
                                onPreviewLayerAvailable: { layer in
                                    camera.setPreviewLayer(layer)
                                }
                            )
                            .ignoresSafeArea()
                        } else if camera.authorizationStatus == .authorized {
                            ProgressView(SafeEatL10n.text(L10nKey.Home.cameraStarting))
                                .tint(.white)
                                .foregroundStyle(.white)
                        } else {
                            permissionPlaceholder
                        }

                        if camera.authorizationStatus == .authorized, camera.isConfigured {
                            CameraGuidanceOverlay()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    cameraBottomBar(bottomInset: proxy.safeAreaInsets.bottom)
                }
            }
        }
        .onPreferenceChange(CameraGuideRectPreferenceKey.self) { rect in
            camera.updateGuideRect(rect)
        }
        .onPreferenceChange(CameraGuideSizeRatioPreferenceKey.self) { ratio in
            camera.updateGuideSizeRatio(ratio)
        }
        .task {
            await camera.prepare()
        }
        .onDisappear {
            camera.stopSession()
            if let pendingCapturedImage {
                onCapture(pendingCapturedImage)
                self.pendingCapturedImage = nil
            }
        }
        .onReceive(camera.$capturedImage) { image in
            guard let image, pendingCapturedImage == nil else { return }
            pendingCapturedImage = image
            camera.stopSession()
            dismiss()
        }
    }

    private func cameraTopBar(topInset: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(SafeEatL10n.text(L10nKey.Home.cameraTitle))
                .font(SafeEatFont.custom(18, relativeTo: .headline, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            Button {
                camera.toggleFlash()
            } label: {
                Image(systemName: camera.isFlashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(camera.isFlashEnabled ? SafeEatTheme.warning : .white)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(camera.isFlashAvailable ? 1 : 0.35)
            .disabled(!camera.isFlashAvailable)
            .accessibilityLabel(
                SafeEatL10n.text(
                    camera.isFlashEnabled ? L10nKey.Home.cameraFlashOn : L10nKey.Home.cameraFlashOff
                )
            )
        }
        .padding(.horizontal, 22)
        .frame(height: topBarHeight)
        .padding(.top, topInset)
        .background(Color.black)
    }

    private func cameraBottomBar(bottomInset: CGFloat) -> some View {
        VStack(spacing: 18) {
            if let errorMessage = camera.errorMessage {
                Text(errorMessage)
                    .font(SafeEatFont.textStyle(.footnote))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.55))
                    .clipShape(Capsule())
            }

            Text(SafeEatL10n.text(L10nKey.Home.cameraBottomHint))
                .font(SafeEatFont.custom(15, relativeTo: .subheadline, weight: .semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.90, blue: 0.86))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                camera.capturePhoto()
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 94, height: 94)

                    Circle()
                        .stroke(.white, lineWidth: 5)
                        .frame(width: 82, height: 82)

                    Circle()
                        .fill(.white)
                        .frame(width: 66, height: 66)
                }
            }
            .buttonStyle(.plain)
            .disabled(!camera.canCapturePhoto)
            .opacity(camera.canCapturePhoto ? 1 : 0.62)
        }
        .frame(maxWidth: .infinity)
        .frame(height: bottomBarHeight + bottomInset, alignment: .top)
        .padding(.top, 10)
        .background(Color.black)
    }

    private var permissionPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.9))

            Text(SafeEatL10n.text(L10nKey.Home.cameraPermissionTitle))
                .font(SafeEatFont.textStyle(.headline))
                .foregroundStyle(.white)

            Text(SafeEatL10n.text(L10nKey.Home.cameraPermissionBody))
                .font(SafeEatFont.textStyle(.footnote))
                .foregroundStyle(.white.opacity(0.75))

            Button(SafeEatL10n.text(L10nKey.Home.cameraOpenSettings)) {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(settingsURL)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}

final class CameraSessionModel: NSObject, ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published var errorMessage: String?
    @Published var capturedImage: CameraCapturePayload?
    @Published var isConfigured = false
    @Published var isCapturingPhoto = false
    @Published var isFlashEnabled = false

    let session = AVCaptureSession()

    var canCapturePhoto: Bool {
        authorizationStatus == .authorized && isConfigured && !isCapturingPhoto
    }

    var isFlashAvailable: Bool {
        videoDevice?.hasFlash ?? false
    }

    private let sessionQueue = DispatchQueue(label: "bizeasylink.safeeat.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private let guideRectLock = NSLock()
    private var hasConfiguredSession = false
    private var normalizedGuideRect: CGRect = .zero
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
    private var videoDevice: AVCaptureDevice?
    @MainActor private var latestGuideRect: CGRect = .zero

    func prepare() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = status

        switch status {
        case .authorized:
            startSession()
        case .notDetermined:
            let granted = await requestVideoAccess()
            authorizationStatus = granted ? .authorized : .denied
            if granted {
                startSession()
            } else {
                errorMessage = SafeEatL10n.text(L10nKey.Home.cameraPermissionOff)
            }
        case .denied, .restricted:
            errorMessage = SafeEatL10n.text(L10nKey.Home.cameraPermissionOff)
        @unknown default:
            errorMessage = SafeEatL10n.text(L10nKey.Home.cameraUnsupported)
        }
    }

    @MainActor
    func setPreviewLayer(_ previewLayer: AVCaptureVideoPreviewLayer) {
        self.previewLayer = previewLayer
        recomputeNormalizedGuideRect()
    }

    @MainActor
    func updateGuideRect(_ guideRect: CGRect) {
        latestGuideRect = guideRect
        recomputeNormalizedGuideRect()
    }

    /// 扫描框相对于屏幕的尺寸比例
    /// - width: 扫描框宽度占屏幕宽度的比例 (0.0 ~ 1.0)
    /// - height: 扫描框高度占屏幕宽度的比例 (0.0 ~ 1.0) - 注意：是相对于屏幕宽度，不是高度
    /// 
    /// 使用示例：
    /// ```
    /// let screenWidth = UIScreen.main.bounds.width
    /// let screenHeight = UIScreen.main.bounds.height
    /// let guideWidth = screenWidth * camera.guideSizeRatio.width
    /// let guideHeight = screenWidth * camera.guideSizeRatio.height  // 注意：高度相对于宽度
    /// ```
    @Published private(set) var guideSizeRatio: CGSize = .zero

    @MainActor
    func updateGuideSizeRatio(_ ratio: CGSize) {
        guideSizeRatio = ratio
    }

    func capturePhoto() {
        guard canCapturePhoto else { return }

        errorMessage = nil
        isCapturingPhoto = true
        sessionQueue.async {
            let settings = AVCapturePhotoSettings()
            if self.videoDevice?.hasFlash == true {
                settings.flashMode = self.isFlashEnabled ? .on : .off
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    @MainActor
    func toggleFlash() {
        guard isFlashAvailable else { return }
        isFlashEnabled.toggle()
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func startSession() {
        sessionQueue.async {
            do {
                try self.configureSessionIfNeeded()
                guard !self.session.isRunning else { return }
                self.session.startRunning()
            } catch {
                Task { @MainActor in
                    self.errorMessage = SafeEatL10n.text(L10nKey.Home.cameraStartFailed)
                }
            }
        }
    }

    private func configureSessionIfNeeded() throws {
        guard !hasConfiguredSession else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .photo

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        else {
            throw CameraError.cameraUnavailable
        }
        videoDevice = camera

        let input = try AVCaptureDeviceInput(device: camera)

        guard session.canAddInput(input) else {
            throw CameraError.inputUnavailable
        }
        session.addInput(input)

        guard session.canAddOutput(photoOutput) else {
            throw CameraError.outputUnavailable
        }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true

        hasConfiguredSession = true
        Task { @MainActor in
            self.isConfigured = true
        }
    }

    private func requestVideoAccess() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    @MainActor
    private func recomputeNormalizedGuideRect() {
        guard
            let previewLayer,
            !latestGuideRect.isNull,
            !latestGuideRect.isEmpty
        else {
            setNormalizedGuideRect(.zero)
            return
        }

        let clampedGuideRect = latestGuideRect.standardized.intersection(previewLayer.bounds)
        guard !clampedGuideRect.isNull, !clampedGuideRect.isEmpty else {
            setNormalizedGuideRect(.zero)
            return
        }

        let normalized = previewLayer.metadataOutputRectConverted(fromLayerRect: clampedGuideRect).standardized
        setNormalizedGuideRect(normalized)
    }

    private func setNormalizedGuideRect(_ rect: CGRect) {
        guideRectLock.lock()
        normalizedGuideRect = rect
        guideRectLock.unlock()
    }

    private func currentNormalizedGuideRect() -> CGRect {
        guideRectLock.lock()
        let rect = normalizedGuideRect
        guideRectLock.unlock()
        return rect
    }

    private func cropImageToGuideRectIfPossible(_ image: UIImage) -> UIImage {
        let normalizedRect = currentNormalizedGuideRect().standardized
        guard !normalizedRect.isNull, !normalizedRect.isEmpty else {
            return image
        }

        let baseImage = image.normalizedUprightImage()
        guard let cgImage = baseImage.cgImage else {
            return image
        }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)
        let fullBounds = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)

        // 直接按预览层里的白框内区域裁切，避免再次推导比例带来的偏差。
        let pixelRect = CGRect(
            x: normalizedRect.minX * pixelWidth,
            y: normalizedRect.minY * pixelHeight,
            width: normalizedRect.width * pixelWidth,
            height: normalizedRect.height * pixelHeight
        )
            .integral
            .intersection(fullBounds)

        guard
            !pixelRect.isNull,
            pixelRect.width >= 80,
            pixelRect.height >= 80,
            let croppedCGImage = cgImage.cropping(to: pixelRect)
        else {
            return image
        }

        return UIImage(cgImage: croppedCGImage, scale: baseImage.scale, orientation: .up)
    }
}

extension CameraSessionModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if error != nil {
            Task { @MainActor in
                self.isCapturingPhoto = false
                self.errorMessage = SafeEatL10n.text(L10nKey.Home.cameraCaptureFailed)
            }
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let rawImage = Self.bakedCaptureImage(from: photo, data: data)
        else {
            Task { @MainActor in
                self.isCapturingPhoto = false
                self.errorMessage = SafeEatL10n.text(L10nKey.Home.cameraCaptureFailed)
            }
            return
        }

        let croppedImage = cropImageToGuideRectIfPossible(rawImage)

        Task { @MainActor in
            self.isCapturingPhoto = false
            self.capturedImage = CameraCapturePayload(
                croppedImage: croppedImage,
                rawImage: rawImage
            )
        }
    }

    nonisolated private static func bakedCaptureImage(from photo: AVCapturePhoto, data: Data) -> UIImage? {
        guard var ciImage = CIImage(data: data, options: [.applyOrientationProperty: false]) else {
            return UIImage(data: data)?.normalizedUprightImage()
        }

        let exifOrientation =
            (photo.metadata[kCGImagePropertyOrientation as String] as? UInt32)
            ?? imageSourceOrientation(from: data)

        if let exifOrientation {
            ciImage = ciImage.oriented(forExifOrientation: Int32(exifOrientation))
        }

        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage(data: data)?.normalizedUprightImage()
        }

        return UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
    }

    nonisolated private static func imageSourceOrientation(from data: Data) -> UInt32? {
        guard
            let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
        else {
            return nil
        }

        return properties[kCGImagePropertyOrientation] as? UInt32
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let rotationAngle: CGFloat
    let onPreviewLayerAvailable: (AVCaptureVideoPreviewLayer) -> Void

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        onPreviewLayerAvailable(view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        uiView.previewLayer.session = session
        onPreviewLayerAvailable(uiView.previewLayer)
        if let connection = uiView.previewLayer.connection,
           connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
    }
}

private final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private enum CameraError: Error {
    case cameraUnavailable
    case inputUnavailable
    case outputUnavailable
}

private struct CameraGuideRectPreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// 扫描框相对于屏幕的尺寸比例（百分比）
/// - width: 扫描框宽度占屏幕宽度的比例
/// - height: 扫描框高度占屏幕宽度的比例（不是屏幕高度！）
private struct CameraGuideSizeRatioPreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

/// 扫描框尺寸配置（百分比）
/// - 使用屏幕尺寸的百分比，方便裁切时复用
enum CameraGuideSize {
    /// 扫描框宽度占屏幕宽度的比例 (0.0 ~ 1.0)
    static let widthRatio: CGFloat = 0.85
    
    /// 扫描框高度相对于宽度的比例
    static let heightRatio: CGFloat = 1.24
    
    /// 扫描框最大宽度（pt）
    static let maxWidth: CGFloat = 318
    
    /// 扫描框最小宽度（pt）
    static let minWidth: CGFloat = 236
    
    /// 左右边距（pt）
    static let horizontalPadding: CGFloat = 36
}

private struct CameraGuideLayout {
    let frameRect: CGRect
    let captureRect: CGRect
    let labelWidth: CGFloat
    /// 扫描框尺寸占屏幕的比例（用于裁切）
    let sizeRatio: CGSize

    static func make(in proxy: GeometryProxy) -> CameraGuideLayout {
        let screenWidth = proxy.size.width
        let screenHeight = proxy.size.height
        
        // 使用百分比计算宽度
        let widthByRatio = screenWidth * CameraGuideSize.widthRatio
        // 限制最大最小值
        let width = min(CameraGuideSize.maxWidth, max(CameraGuideSize.minWidth, widthByRatio))
        
        // 高度按宽度比例计算
        let height = width * CameraGuideSize.heightRatio
        
        // 计算尺寸比例（相对于屏幕）
        let sizeRatio = CGSize(width: width / screenWidth, height: height / screenHeight)
        
        let topSafe = proxy.safeAreaInsets.top + 124
        let bottomControlsSafe = proxy.safeAreaInsets.bottom + 238
        let availableHeight = max(240, screenHeight - topSafe - bottomControlsSafe)
        let adjustedHeight = min(height, availableHeight)
        
        let x = (screenWidth - width) / 2
        let preferredY = max(proxy.safeAreaInsets.top + 138, (screenHeight - adjustedHeight) / 2 - 46)
        let maxY = max(proxy.safeAreaInsets.top + 92, screenHeight - bottomControlsSafe - adjustedHeight)
        let y = min(preferredY, maxY)
        
        let rect = CGRect(x: x, y: y, width: width, height: adjustedHeight)
        let captureRect = rect.insetBy(
            dx: max(10, rect.width * 0.045),
            dy: max(14, rect.height * 0.055)
        )
        let labelWidth = min(width - 28, 224)
        
        return CameraGuideLayout(
            frameRect: rect, 
            captureRect: captureRect, 
            labelWidth: labelWidth,
            sizeRatio: sizeRatio
        )
    }
}

private struct CameraGuidanceOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let layout = CameraGuideLayout.make(in: proxy)

            ZStack(alignment: .topLeading) {
                Color.clear
                    .preference(key: CameraGuideRectPreferenceKey.self, value: layout.captureRect)
                    .preference(key: CameraGuideSizeRatioPreferenceKey.self, value: layout.sizeRatio)

                CameraCornerBrackets()
                    .stroke(.white.opacity(0.86), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                    .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                    .position(x: layout.frameRect.midX, y: layout.frameRect.midY)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
    }
}

private struct CameraCornerBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        let corner: CGFloat = min(rect.width, rect.height) * 0.14
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + corner))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - corner, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + corner))

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - corner))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + corner, y: rect.maxY))

        path.move(to: CGPoint(x: rect.maxX - corner, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - corner))

        return path
    }
}
