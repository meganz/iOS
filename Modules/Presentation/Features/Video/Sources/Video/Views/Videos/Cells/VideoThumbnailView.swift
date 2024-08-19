import MEGADesignToken
import MEGAPresentation
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
