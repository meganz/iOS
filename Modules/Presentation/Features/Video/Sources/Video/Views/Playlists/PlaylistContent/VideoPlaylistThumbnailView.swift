import MEGADesignToken
import MEGAPresentation
import SwiftUI

struct VideoPlaylistThumbnailView: View {

    private let videoConfig: VideoConfig
    private let topLeftImage: (any ImageContaining)?
    private let topRightImage: (any ImageContaining)?
    private let bottomLeftImage: (any ImageContaining)?
    private let bottomRightImage: (any ImageContaining)?
    
    private var thumbnailType = ThumbnailType.single
    
    private enum ThumbnailType {
        case single
        case multiple
    }
    
    private let cornerRadius: CGFloat = 4
    
    init(
        videoConfig: VideoConfig,
        imageContainers: [any ImageContaining]
    ) {
        self.videoConfig = videoConfig
        self.topLeftImage = imageContainers[safe: 0]
        self.topRightImage = imageContainers[safe: 1]
        self.bottomLeftImage = imageContainers[safe: 2]
        self.bottomRightImage = imageContainers[safe: 3]
        
        self.thumbnailType = imageContainers.count > 1 ? .multiple : .single
    }
    
    var body: some View {
        Group {
            switch thumbnailType {
            case .single:
                singleThumbnailLayoutView(image: topLeftImage)
            case .multiple:
                multipleThumbnailLayout
            }
        }
        .background(thumbnailBackgroundColor)
        .cornerRadius(cornerRadius)
    }
    
    private var thumbnailBackgroundColor: Color {
        videoConfig.playlistContentAssets.headerView.color.thumbnailBackgroundColor
    }
    
    private var multipleThumbnailLayout: some View {
        VStack(spacing: TokenSpacing._2) {
            HStack(spacing: TokenSpacing._2) {
                multipleThumbnailLayoutView(image: topLeftImage)
                multipleThumbnailLayoutView(image: topRightImage)
            }

            HStack(spacing: TokenSpacing._2) {
                multipleThumbnailLayoutView(image: bottomLeftImage)
                multipleThumbnailLayoutView(image: bottomRightImage)
            }
        }
        .cornerRadius(cornerRadius)
    }
    
    @ViewBuilder
    private func singleThumbnailLayoutView(image: (any ImageContaining)?) -> some View {
        if let image {
            switch image.type {
            case .thumbnail:
                image.image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 142, height: 80)
                    .sensitive(image)
            default:
                EmptyView()
                    .frame(width: 142, height: 80)
            }
        } else {
            thumbnailBackgroundColor
                .frame(width: 142, height: 80)
                .aspectRatio(contentMode: .fill)
        }
    }
    
    @ViewBuilder
    private func multipleThumbnailLayoutView(image: (any ImageContaining)?) -> some View {
        if let image {
            switch image.type {
            case .thumbnail:
                image.image
                    .resizable()
                    .frame(height: 39)
                    .aspectRatio(contentMode: .fit)
                    .sensitive(image)
            default:
                EmptyView()
                    .frame(width: 142, height: 80)
            }
        } else {
            thumbnailBackgroundColor
                .frame(height: 39)
                .aspectRatio(contentMode: .fill)
        }
    }
}

// MARK: - Light mode

#Preview {
    renderPreviews()
}

// MARK: - Dark mode

#Preview {
    renderPreviews()
        .preferredColorScheme(.dark)
}

private func renderPreviews() -> some View {
    Group {
        
        // MARK: - All Thumbnails
        
        VideoPlaylistThumbnailView(videoConfig: .preview, imageContainers: [
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail)
        ])
        
        // MARK: - 3 thumbnails
        VideoPlaylistThumbnailView(videoConfig: .preview, imageContainers: [
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail)
        ])
        
        // MARK: - 2 thumbnails
        VideoPlaylistThumbnailView(videoConfig: .preview, imageContainers: [
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail),
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail)
        ])
        
        // MARK: - 1 thumbnail
        VideoPlaylistThumbnailView(videoConfig: .preview, imageContainers: [
            ImageContainer(image: PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 1, height: 1)).image, type: .thumbnail)
        ])
    }
    .padding()
}
