import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import SwiftUI

struct FavoritePlaylistCell: View {
    
    @StateObject private var viewModel: VideoPlaylistCellViewModel
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistCellViewModel,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.router = router
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(0)
        .background(TokenColors.Background.page.swiftUI)
        .task {
            await viewModel.onViewAppear()
        }
        .onTapGesture {
            router.openVideoPlaylistContent(for: viewModel.videoPlaylistEntity)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VideoListPlaceholderCell()
                .shimmering(active: viewModel.isLoading)
        } else {
            ThumbnailLayerView(
                thumbnail: viewModel.previewEntity.thumbnail,
                videoPlaylistType: viewModel.previewEntity.type
            )
            .frame(width: 142, height: 80, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.previewEntity.title)
                    .font(.subheadline)
                    .foregroundColor(TokenColors.Icon.primary.swiftUI)
                
                secondaryInformationView()
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
    
    @ViewBuilder
    private func secondaryInformationView() -> some View {
        switch viewModel.secondaryInformationViewType {
        case .emptyPlaylist:
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.PlaylistCell.Subtitle.emptyPlaylist)
                .font(.caption)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
        case .information:
            VideoPlaylistSecondaryInformationView(
                videosCount: viewModel.previewEntity.count,
                totalDuration: viewModel.previewEntity.duration,
                isPublicLink: viewModel.previewEntity.isExported,
                layoutIgnoringOrientation: false
            )
        }
    }
}

struct ThumbnailLayerView: View {
    
    let thumbnail: VideoPlaylistThumbnail
    let videoPlaylistType: VideoPlaylistEntityType
    
    var body: some View {
        ZStack {
            TokenColors.Background.surface3.swiftUI
            
            switch thumbnail.type {
            case .empty:
                emptyPlaylistCoverThumbnailView(with: centerBackgroundImage)
            case .allVideosHasNoThumbnails:
                allVideosHasNoThumbnailsThumbnailView()
            case .normal:
                VideoPlaylistThumbnailView(
                    viewContext: .playlistCell,
                    imageContainers: thumbnail.imageContainers
                )
                
                playlistIcon()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding([.top, .trailing], 8)
            }
        }
    }
    
    @ViewBuilder
    private func allVideosHasNoThumbnailsThumbnailView() -> some View {
        if let image = thumbnail.imageContainers.first?.image {
            emptyPlaylistCoverThumbnailView(with: image)
        } else {
            EmptyView()
        }
    }
    
    private func emptyPlaylistCoverThumbnailView(with image: Image) -> some View {
        VStack(spacing: 0) {
            HStack {
                playlistIcon()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, -16)
            .padding(.trailing, 4)
            
            image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
        }
        .padding(0)
    }
    
    private var centerBackgroundImage: Image {
        switch videoPlaylistType {
        case .favourite:
            MEGAAssetsImageProvider.image(named: .favouritePlaylistThumbnail)
        case .user:
            MEGAAssetsImageProvider.image(named: .rectangleVideoStack)
        }
    }
    
    private func playlistIcon() -> some View {
        MEGAAssetsImageProvider.image(named: .rectangleVideoStack)
            .resizable()
            .foregroundStyle(TokenColors.Text.onColor.swiftUI)
            .frame(width: 16, height: 16)
    }
}

#Preview {
    struct FavoritePlaylistCellPreview: View {
        var body: some View {
            FavoritePlaylistCell(
                viewModel: makeNullViewModel(),
                router: Preview_VideoRevampRouter()
            )
            .frame(height: 80, alignment: .center)
            
            FavoritePlaylistCell(
                viewModel: makeNullViewModel(),
                router: Preview_VideoRevampRouter()
            )
            .frame(height: 80, alignment: .center)
            .preferredColorScheme(.dark)
        }
        
        @MainActor
        func makeNullViewModel() -> VideoPlaylistCellViewModel {
            VideoPlaylistCellViewModel(
                videoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoader(
                    thumbnailLoader: Preview_ThumbnailLoader(),
                    fallbackImageContainer: ImageContainer(image: Image("square"), type: .thumbnail)
                ),
                videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
                sortOrderPreferenceUseCase: Preview_SortOrderPreferenceUseCase(),
                videoPlaylistEntity: videoPlaylistEntity(),
                setSelection: SetSelection(),
                onTapMoreOptions: { _ in }
            )
        }
        
        @MainActor
        func videoPlaylistEntity() -> VideoPlaylistEntity {
            VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 1),
                name: "Favorites",
                count: 15,
                type: .favourite,
                creationTime: Date(),
                modificationTime: Date()
            )
        }
    }
    
    return FavoritePlaylistCellPreview()
}
