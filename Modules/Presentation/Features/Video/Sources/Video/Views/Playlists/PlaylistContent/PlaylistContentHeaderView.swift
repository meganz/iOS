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
            if previewEntity.imageContainers.isEmpty {
                emptyThumbnailView()
            } else {
                VideoPlaylistThumbnailView(
                    videoConfig: videoConfig,
                    viewContext: .playlistContentHeader,
                    imageContainers: previewEntity.imageContainers
                )
            }
        }
        .frame(width: 142, height: 80)
    }
    
    private func emptyThumbnailView() -> some View {
        Group {
            emptyThumbnailImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .foregroundStyle(videoConfig.colorAssets.emptyFavoriteThumbnaillImageForegroundColor)
        }
        .frame(width: 142, height: 80)
        .background(videoConfig.colorAssets.emptyFavoriteThumbnailBackgroundColor.cornerRadius(4))
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
    
    private var textVStackSpacing: CGFloat {
        previewEntity.imageContainers.isEmpty ? TokenSpacing._1 : TokenSpacing._4
    }
    
    @ViewBuilder
    private var secondaryInformationView: some View {
        if previewEntity.imageContainers.isEmpty {
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
        } else {
            VideoPlaylistSecondaryInformationView(
                videoConfig: videoConfig,
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported
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
            imageContainers: imageContainers,
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
