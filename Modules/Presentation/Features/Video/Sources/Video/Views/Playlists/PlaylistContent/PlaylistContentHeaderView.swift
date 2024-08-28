import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct PlaylistContentHeaderView: View {
    let videoConfig: VideoConfig
    let previewEntity: VideoPlaylistCellPreviewEntity
    let onTapAddButton: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            thumbnailView
            
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                VStack(alignment: .leading, spacing: textVStackSpacing) {
                    Text(previewEntity.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(videoConfig.playlistContentAssets.headerView.color.primaryTextColor)
                    
                    secondaryInformationView
                }
             
                if previewEntity.shouldShowAddButton {
                    addButton
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(videoConfig.playlistContentAssets.headerView.color.pageBackgroundColor)
    }
    
    private var thumbnailView: some View {
        Group {
            switch previewEntity.thumbnail.type {
            case .empty:
                emptyPlaylistCoverThumbnailView(with: emptyThumbnailImage)
            case .allVideosHasNoThumbnails:
                allVideosHasNoThumbnailsThumbnailView()
            case .normal:
                VideoPlaylistThumbnailView(
                    videoConfig: videoConfig,
                    viewContext: .playlistContentHeader,
                    imageContainers: previewEntity.thumbnail.imageContainers
                )
            }
        }
        .frame(width: 142, height: 80)
    }
    
    private var emptyThumbnailImage: Image {
        let image = switch previewEntity.type {
        case .favourite:
            videoConfig.rowAssets.favouritePlaylistThumbnailImage
        case .user:
            videoConfig.rowAssets.rectangleVideoStackPlaylistImage
        }
        return Image(uiImage: image.withRenderingMode(.alwaysTemplate))
    }
    
    @ViewBuilder
    private func allVideosHasNoThumbnailsThumbnailView() -> some View {
        if let image = previewEntity.thumbnail.imageContainers.first?.image {
            emptyPlaylistCoverThumbnailView(with: image)
        } else {
            EmptyView()
        }
    }
    
    private func emptyPlaylistCoverThumbnailView(with image: Image) -> some View {
        Group {
            image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .foregroundStyle(videoConfig.colorAssets.emptyFavoriteThumbnaillImageForegroundColor)
        }
        .frame(width: 142, height: 80)
        .background(videoConfig.colorAssets.emptyFavoriteThumbnailBackgroundColor.cornerRadius(4))
    }
    
    private var textVStackSpacing: CGFloat {
        previewEntity.isEmpty ? TokenSpacing._1 : TokenSpacing._4
    }
    
    @ViewBuilder
    private var secondaryInformationView: some View {
        if previewEntity.isEmpty {
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
        } else {
            VideoPlaylistSecondaryInformationView(
                videoConfig: videoConfig,
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported,
                layoutIgnoringOrientation: true
            )
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        if isDesignTokenEnabled {
            PillView(
                viewModel: .init(
                    title: Strings.Localizable.Videos.Tab.Playlist.Content.Header.Button.Title.add,
                    icon: .leading(Image(uiImage: videoConfig.playlistContentAssets.headerView.image.addButtonImage.withRenderingMode(.alwaysTemplate))),
                    foreground: TokenColors.Text.accent.swiftUI,
                    background: TokenColors.Button.secondary.swiftUI,
                    shape: .capsule
                )
            )
            .onTapGesture { onTapAddButton() }
        } else {
            IconButton(
                image: Image(uiImage: videoConfig.playlistContentAssets.headerView.image.addButtonImage),
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Header.Button.Title.add,
                tintColor: videoConfig.playlistContentAssets.headerView.color.buttonTintColor,
                action: { onTapAddButton() }
            )
        }
    }
}

// MARK: - Helpers

#Preview {
    Group {
        view(
            imageContainers: [],
            isExported: false,
            playlistType: .favourite
        )
        
        view(
            imageContainers: [],
            isExported: false,
            playlistType: .user
        )
    }
}

#Preview {
    view(
        imageContainers: [
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail)
        ],
        isExported: false,
        playlistType: .favourite
    )
}

#Preview {
    view(
        imageContainers: [
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail)
        ],
        isExported: true,
        playlistType: .favourite
    )
    .preferredColorScheme(.dark)
}

private func view(imageContainers: [any ImageContaining], isExported: Bool, playlistType: VideoPlaylistEntityType) -> some View {
    PlaylistContentHeaderView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "24 Videos",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: isExported,
            type: playlistType
        ),
        onTapAddButton: {}
    )
}

private var sampleImage: Image {
    PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 400, height: 400)).image
}
