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
            
            HStack {
                Text(previewEntity.duration)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(videoConfig.colorAssets.whiteColor)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.vertical, 1)
            .padding(.horizontal, 4)
            .background(videoConfig.colorAssets.videoThumbnailDurationTextBackgroundColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(4)
        }
        .padding(.all, 8)
    }
}

// MARK: - Preview

#Preview {
    VideoThumbnailView(previewEntity: .all, videoConfig: .preview)
}
