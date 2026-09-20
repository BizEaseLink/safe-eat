import SwiftUI
import UIKit

/// 异步加载贴纸图片的组件，避免在主线程同步处理图片
/// 解决大量贴纸同时加载时导致的卡顿问题
struct AsyncRecognitionStickerView: View {
    let item: LocalHistoryItem
    var imageHeight: CGFloat = 126
    var labelMaxWidth: CGFloat = 200
    var rotationAngle: Double = 0
    var offsetY: CGFloat = 0
    var style: RecognitionStickerThumbnailStyle = .card

    @State private var loadedImage: UIImage?
    @State private var hasError = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            stickerContent
            if item.feedbackPending {
                Image(systemName: "hourglass")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(4)
            }
        }
        .rotationEffect(.degrees(rotationAngle))
        .offset(y: offsetY)
        .frame(maxWidth: .infinity, alignment: .top)
        .task(id: item.id) {
            await loadImageAsync()
        }
    }

    private var stickerContent: some View {
        Group {
            if let image = loadedImage {
                RecognitionStickerThumbnailView(
                    image: image,
                    titleText: item.recognizedName,
                    metaText: StickerTextFormatter.adviceScore(for: item),
                    imageHeight: imageHeight,
                    labelMaxWidth: labelMaxWidth,
                    style: style
                )
            } else if hasError {
                placeholderView
            } else {
                skeletonView
            }
        }
    }

    private var placeholderView: some View {
        RecognitionStickerThumbnailView(
            image: nil,
            titleText: item.recognizedName,
            metaText: StickerTextFormatter.adviceScore(for: item),
            imageHeight: imageHeight,
            labelMaxWidth: labelMaxWidth,
            style: style
        )
    }

    private var skeletonView: some View {
        RecognitionStickerThumbnailView(
            image: nil,
            titleText: item.recognizedName,
            metaText: StickerTextFormatter.adviceScore(for: item),
            imageHeight: imageHeight,
            labelMaxWidth: labelMaxWidth,
            style: style
        )
        .overlay {
            ProgressView()
                .tint(.white.opacity(0.78))
        }
    }

    private func loadImageAsync() async {
        let currentItem = item

        if let cached = LocalImageLoader.cachedStickerImage(for: currentItem) {
            await MainActor.run {
                loadedImage = cached
                hasError = false
            }
            return
        }

        await MainActor.run {
            hasError = false
        }

        let image = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: LocalImageLoader.loadStickerImage(for: currentItem))
            }
        }

        guard !Task.isCancelled else { return }

        await MainActor.run {
            loadedImage = image
            hasError = image == nil
        }
    }
}

/// 预加载并缓存贴纸图片的工具类
@MainActor
enum StickerImageCache {
    private static var preloadTasks: [String: Bool] = [:]

    /// 预加载图片到缓存（后台执行）
    static func preload(for items: [LocalHistoryItem]) {
        for item in items {
            let key = item.id
            guard preloadTasks[key] == nil, LocalImageLoader.cachedStickerImage(for: item) == nil else { continue }

            preloadTasks[key] = true

            DispatchQueue.global(qos: .utility).async {
                _ = LocalImageLoader.loadStickerImage(for: item)
                Task { @MainActor in
                    Self.preloadTasks.removeValue(forKey: key)
                }
            }
        }
    }

    /// 取消预加载任务
    static func cancelPreload(for itemId: String) {
        preloadTasks.removeValue(forKey: itemId)
    }

    /// 清除所有预加载任务
    static func cancelAll() {
        preloadTasks.removeAll()
    }
}
