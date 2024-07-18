import MEGASwiftUI
import SwiftUI

struct VideoThumbnailView: View {
    
    let previewEntity: VideoCellPreviewEntity
    let videoConfig: VideoConfig
    
    var body: some View {
        GeometryReader { geometry in
            thumbnailImageView
                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                .overlay(thumbnailLayerView)
        }
    }
    
    @ViewBuilder
    private var thumbnailImageView: some View {
        if previewEntity.imageContainer.type == .placeholder {
            videoConfig.colorAssets.videoThumbnailImageViewPlaceholderBackgroundColor
                .frame(width: 150, height: 150)
        } else {
            previewEntity.imageContainer.image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(4)
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
            
            Image(uiImage: videoConfig.rowAssets.playImage)
                .resizable()
                .frame(width: 24, height: 24)
                .opacity(0.8)
            
            Spacer()
            
            VideoDurationView(
                duration: previewEntity.duration,
                videoConfig: videoConfig
            )
        }
        .padding(.all, 8)
    }
}

// MARK: - Preview

#Preview {
    VideoThumbnailView(previewEntity: .all(title: .short), videoConfig: .preview)
}
