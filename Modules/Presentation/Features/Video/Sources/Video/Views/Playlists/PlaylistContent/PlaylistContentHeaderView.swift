import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASwiftUI
import SwiftUI

struct PlaylistContentHeaderView: View {
    let viewState: VideoPlaylistContentViewModel.ViewState
    let previewEntity: VideoPlaylistCellPreviewEntity
    let onTapAddButton: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            switch viewState {
            case .partial, .loading, .error:
                thumbnailPlaceholderView
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .loaded, .empty:
                contentView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
        .background(TokenColors.Background.surface1.swiftUI)
    }
    
    private var contentView: some View {
        Group {
            thumbnailView
            
            VStack(alignment: .leading, spacing: TokenSpacing._4) {
                VStack(alignment: .leading, spacing: textVStackSpacing) {
                    Text(previewEntity.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundStyle(TokenColors.Text.primary.swiftUI)
                    
                    secondaryInformationView
                }
                
                if previewEntity.shouldShowAddButton {
                    addButton
                }
            }
        }
    }
    
    @ViewBuilder
    private var thumbnail: some View {
        if [.partial, .loading].contains(viewState) {
            thumbnailPlaceholderView
        } else {
            thumbnailView
        }
    }
    
    private var thumbnailPlaceholderView: some View {
        Rectangle()
            .cornerRadius(4, corners: .allCorners)
            .foregroundStyle(TokenColors.Background.surface3.swiftUI)
            .frame(width: 142, height: 80)
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
                    viewContext: .playlistContentHeader,
                    imageContainers: previewEntity.thumbnail.imageContainers
                )
            }
        }
        .frame(width: 142, height: 80)
    }
    
    private var emptyThumbnailImage: Image {
        let image: Image = switch previewEntity.type {
        case .favourite:
            MEGAAssetsImageProvider.image(named: .favouritePlaylistThumbnail)
        case .user:
            MEGAAssetsImageProvider.image(named: .rectangleVideoStack)
        }
        return image.renderingMode(.template)
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
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        }
        .frame(width: 142, height: 80)
        .background(TokenColors.Background.surface3.swiftUI.cornerRadius(4))
    }
    
    private var textVStackSpacing: CGFloat {
        previewEntity.isEmpty ? TokenSpacing._1 : TokenSpacing._4
    }
    
    @ViewBuilder
    private var secondaryInformationView: some View {
        if previewEntity.isEmpty {
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        } else {
            VideoPlaylistSecondaryInformationView(
                videosCount: previewEntity.count,
                totalDuration: previewEntity.duration,
                isPublicLink: previewEntity.isExported,
                layoutIgnoringOrientation: true
            )
        }
    }
    
    @ViewBuilder
    private var addButton: some View {
        PillView(
            viewModel: .init(
                title: Strings.Localizable.Videos.Tab.Playlist.Content.Header.Button.Title.add,
                icon: .leading(Image(systemName: "plus").renderingMode(.template)),
                foreground: TokenColors.Text.accent.swiftUI,
                background: TokenColors.Button.secondary.swiftUI,
                shape: .capsule
            )
        )
        .onTapGesture { onTapAddButton() }
    }
}

// MARK: - Preview partial & loading

#Preview {
    Group {
        view(
            viewState: .partial,
            imageContainers: [],
            isExported: false,
            playlistType: .favourite,
            playlistName: ""
        )
        
        view(
            viewState: .loading,
            imageContainers: [],
            isExported: false,
            playlistType: .user,
            playlistName: ""
        )
    }
}

// MARK: - Preview empty

#Preview {
    Group {
        view(
            viewState: .empty,
            imageContainers: [],
            isExported: false,
            playlistType: .favourite,
            playlistName: "An empty favorite playlist header"
        )
        
        view(
            viewState: .empty,
            imageContainers: [],
            isExported: false,
            playlistType: .user,
            playlistName: "An empty user playlist header"
        )
    }
}

// MARK: - Preview loaded

#Preview {
    view(
        viewState: .loaded,
        imageContainers: [
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail),
            ImageContainer(image: sampleImage, type: .thumbnail)
        ],
        isExported: false,
        playlistType: .favourite,
        playlistName: "A non empty favorite video playlist"
    )
}

#Preview {
    view(
        viewState: .loaded,
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

@MainActor
private func view(
    viewState: VideoPlaylistContentViewModel.ViewState,
    imageContainers: [any ImageContaining],
    isExported: Bool,
    playlistType: VideoPlaylistEntityType,
    playlistName: String = "A playlist name"
) -> some View {
    PlaylistContentHeaderView(
        viewState: viewState,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: imageContainers),
            count: count(viewState: viewState, count: imageContainers.count),
            duration: duration(viewState: viewState),
            title: playlistName,
            isExported: isExported,
            type: playlistType
        ),
        onTapAddButton: {}
    )
}

private func count(viewState: VideoPlaylistContentViewModel.ViewState, count: Int) -> String {
    switch viewState {
    case .partial, .loading, .error:
        ""
    case .loaded:
        "\(count) videos"
    case .empty:
        "empty playlist"
    }
}

private func duration(viewState: VideoPlaylistContentViewModel.ViewState) -> String {
    switch viewState {
    case .partial, .loading, .error, .empty:
        ""
    case .loaded:
        "3:05:20"
    }
}

private var sampleImage: Image {
    PreviewImageContainerFactory.withColor(.blue, size: CGSize(width: 400, height: 400)).image
}
