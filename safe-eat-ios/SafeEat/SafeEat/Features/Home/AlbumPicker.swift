import PhotosUI
import SwiftUI
import UIKit

/// 相册选图入口。feature flag 默认关（AppConfig.galleryPickerEnabled）。
/// 相册图是用户已构图好的成品，不裁剪，只扶正到 .up + 压缩，走同一条 recognize 管道。
struct AlbumPicker: View {
    let onPick: (UIImage) -> Void

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            VStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(SafeEatTheme.textSecondary)
                Text(SafeEatL10n.text(L10nKey.Tab.album))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(SafeEatTheme.textSecondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
            .frame(minWidth: 56)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedItem) { _, newValue in
            guard let newValue else { return }
            Task { @MainActor in
                guard let image = await loadImage(from: newValue) else {
                    selectedItem = nil
                    return
                }
                let orientation = OrientationBaker.resolveOrientationForAlbum(image: image)
                let baked = OrientationBaker.bake(image, to: orientation) ?? image
                selectedItem = nil
                onPick(baked)
            }
        }
    }

    @MainActor
    private func loadImage(from item: PhotosPickerItem) async -> UIImage? {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }
}
