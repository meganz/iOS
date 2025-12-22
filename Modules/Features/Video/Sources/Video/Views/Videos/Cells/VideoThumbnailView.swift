import MEGAAppPresentation
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct VideoThumbnailView: View {

    let previewEntity: VideoCellPreviewEntity
    let videoConfig: VideoConfig
    let isMediaRevampEnabled: Bool

    init(
        previewEntity: VideoCellPreviewEntity,
        videoConfig: VideoConfig,
        isMediaRevampEnabled: Bool = false
    ) {
        self.previewEntity = previewEntity
        self.videoConfig = videoConfig
        self.isMediaRevampEnabled = isMediaRevampEnabled
    }

    var body: some View {
        GeometryReader { geometry in
            thumbnailImageView
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                .overlay(thumbnailLayerView)
        }
    }
    
    @ViewBuilder
    private var thumbnailImageView: some View {
        if previewEntity.hasThumbnail {
            previewEntity.imageContainer.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(4)
                .sensitive(previewEntity.imageContainer)
        } else {
            FileTypeIconThumbnailView(image: previewEntity.imageContainer.image)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(4)
                .sensitive(.opacity)
        }
    }
    
    private var thumbnailLayerView: some View {
        VStack {
            Image(uiImage: videoConfig.rowAssets.favoriteImage)
                .renderingMode(.template)
                .foregroundColor(videoConfig.colorAssets.whiteColor)
                .opacity(previewEntity.isFavorite ? 1 : 0)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer()

            // Hide play icon when mediaRevamp is enabled
            if !isMediaRevampEnabled {
                Image(uiImage: videoConfig.rowAssets.playImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .opacity(0.8)
            }

            Spacer()

            if !previewEntity.duration.isEmpty {
                VideoDurationView(
                    duration: previewEntity.duration,
                    videoConfig: videoConfig,
                    isMediaRevampEnabled: isMediaRevampEnabled
                )
            }
        }
        .padding(isMediaRevampEnabled ? EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._3, bottom: TokenSpacing._1, trailing: TokenSpacing._1) : EdgeInsets(top: TokenSpacing._3, leading: TokenSpacing._3, bottom: TokenSpacing._3, trailing: TokenSpacing._3))
    }
}

// MARK: - Preview

#Preview {
    VideoThumbnailView(previewEntity: .all(title: .short), videoConfig: .preview)
}

#Preview {
    VideoThumbnailView(previewEntity: .all(title: .short, hasThumbnail: false), videoConfig: .preview)
}

private struct FileTypeIconThumbnailView: View {

    let image: Image

    var body: some View {
        ZStack {
            TokenColors.Background.surface2.swiftUI
            image
                .resizable()
                .frame(width: 46, height: 52, alignment: .center)
            Color.black.opacity(0.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FileTypeIconThumbnailView(image: Image(systemName: "film.fill"))
}
