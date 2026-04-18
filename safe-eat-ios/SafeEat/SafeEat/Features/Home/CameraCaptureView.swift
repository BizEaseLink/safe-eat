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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @StateObject private var camera = CameraSessionModel()
    @State private var pendingCapturedImage: CameraCapturePayload?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

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
                ProgressView("正在启动相机…")
                    .tint(.white)
                    .foregroundStyle(.white)
            } else {
                permissionPlaceholder
            }

            if camera.authorizationStatus == .authorized, camera.isConfigured {
                CameraGuidanceOverlay()
            }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                if let errorMessage = camera.errorMessage {
                    Text(errorMessage)
                        .font(SafeEatFont.textStyle(.footnote))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(.bottom, 18)
                }

                Button {
                    camera.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.25))
                            .frame(width: 82, height: 82)
                        Circle()
                            .fill(.white)
                            .frame(width: 64, height: 64)
                    }
                }
                .disabled(!camera.canCapturePhoto)
                .padding(.bottom, 34)
            }
        }
        .onPreferenceChange(CameraGuideRectPreferenceKey.self) { rect in
            camera.updateGuideRect(rect)
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

    private var permissionPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.9))

            Text("需要相机权限才能直接拍照识别")
                .font(SafeEatFont.textStyle(.headline))
                .foregroundStyle(.white)

            Text("请在系统设置中打开相机权限后再试。")
                .font(SafeEatFont.textStyle(.footnote))
                .foregroundStyle(.white.opacity(0.75))

            Button("打开设置") {
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

    let session = AVCaptureSession()

    var canCapturePhoto: Bool {
        authorizationStatus == .authorized && isConfigured && !isCapturingPhoto
    }

    private let sessionQueue = DispatchQueue(label: "bizeasylink.safeeat.camera.session")
    private let photoOutput = AVCapturePhotoOutput()
    private let guideRectLock = NSLock()
    private var hasConfiguredSession = false
    private var normalizedGuideRect: CGRect = .zero
    private weak var previewLayer: AVCaptureVideoPreviewLayer?
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
                errorMessage = "相机权限未开启。"
            }
        case .denied, .restricted:
            errorMessage = "相机权限未开启。"
        @unknown default:
            errorMessage = "当前设备不支持相机。"
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

    func capturePhoto() {
        guard canCapturePhoto else { return }

        errorMessage = nil
        isCapturingPhoto = true
        sessionQueue.async {
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
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
                    self.errorMessage = "相机启动失败，请稍后重试。"
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
        let normalizedRect = currentNormalizedGuideRect()
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
                self.errorMessage = "拍照失败，请重试。"
            }
            return
        }

        guard
            let data = photo.fileDataRepresentation(),
            let rawImage = Self.bakedCaptureImage(from: photo, data: data)
        else {
            Task { @MainActor in
                self.isCapturingPhoto = false
                self.errorMessage = "拍照失败，请重试。"
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

private struct CameraGuideLayout {
    let frameRect: CGRect
    let labelWidth: CGFloat

    static func make(in proxy: GeometryProxy) -> CameraGuideLayout {
        let horizontalInset: CGFloat = 36
        let width = max(236, min(proxy.size.width - horizontalInset * 2, 318))
        let desiredHeight = width * 1.24
        let topSafe = proxy.safeAreaInsets.top + 124
        let bottomControlsSafe = proxy.safeAreaInsets.bottom + 238
        let availableHeight = max(240, proxy.size.height - topSafe - bottomControlsSafe)
        let height = min(desiredHeight, availableHeight)
        let x = (proxy.size.width - width) / 2
        let preferredY = max(proxy.safeAreaInsets.top + 138, (proxy.size.height - height) / 2 - 46)
        let maxY = max(proxy.safeAreaInsets.top + 92, proxy.size.height - bottomControlsSafe - height)
        let y = min(preferredY, maxY)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        let labelWidth = min(width - 28, 224)
        return CameraGuideLayout(frameRect: rect, labelWidth: labelWidth)
    }
}

private struct CameraGuidanceOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let layout = CameraGuideLayout.make(in: proxy)

            ZStack(alignment: .topLeading) {
                Color.clear
                    .preference(key: CameraGuideRectPreferenceKey.self, value: layout.frameRect)

                CameraCornerBrackets()
                    .stroke(.white.opacity(0.86), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))
                    .frame(width: layout.frameRect.width, height: layout.frameRect.height)
                    .position(x: layout.frameRect.midX, y: layout.frameRect.midY)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

                Text("请将主体放置于框线内")
                    .font(SafeEatFont.custom(13, relativeTo: .caption))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(width: layout.labelWidth)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.black.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.white.opacity(0.58), lineWidth: 0)
                    )
                    .position(
                        x: layout.frameRect.midX,
                        y: layout.frameRect.maxY + 20
                    )
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
