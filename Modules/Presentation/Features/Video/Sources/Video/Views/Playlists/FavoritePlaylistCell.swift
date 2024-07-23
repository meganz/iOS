import MEGADomain
import MEGAL10n
import MEGAPresentation
import SwiftUI

struct FavoritePlaylistCell: View {
    
    @StateObject private var viewModel: VideoPlaylistCellViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistCellViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        HStack {
            content
        }
        .padding(0)
        .background(videoConfig.colorAssets.pageBackgroundColor)
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
                videoConfig: videoConfig,
                imageContainers: viewModel.previewEntity.imageContainers,
                centerBackgroundImage: videoConfig.rowAssets.favouritePlaylistThumbnailImage
            )
            .frame(width: 142, height: 80, alignment: .center)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.previewEntity.title)
                    .font(.subheadline)
                    .foregroundColor(videoConfig.colorAssets.primaryTextColor)
                
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
                .foregroundStyle(videoConfig.colorAssets.secondaryTextColor)
        case .information:
            VideoPlaylistSecondaryInformationView(
                videoConfig: videoConfig,
                videosCount: viewModel.previewEntity.count,
                totalDuration: viewModel.previewEntity.duration,
                isPublicLink: viewModel.previewEntity.isExported
            )
        }
    }
}

struct ThumbnailLayerView: View {
    
    let videoConfig: VideoConfig
    let imageContainers: [any ImageContaining]
    let centerBackgroundImage: UIImage
    
    var body: some View {
        ZStack {
            videoConfig.colorAssets.emptyFavoriteThumbnailBackgroundColor
            
            if imageContainers.isEmpty {
                emptyThumbnailView()
            } else {
                 VideoPlaylistThumbnailView(videoConfig: videoConfig, imageContainers: imageContainers)
                
                playlistIcon()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding([.top, .trailing], 8)
            }
        }
    }
    
    private func emptyThumbnailView() -> some View {
        VStack(spacing: 0) {
            HStack {
                playlistIcon()
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.top, -16)
            .padding(.trailing, 4)
            
            Image(uiImage: centerBackgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .foregroundStyle(videoConfig.colorAssets.emptyFavoriteThumbnaillImageForegroundColor)
        }
        .padding(0)
    }
    
    private func playlistIcon() -> some View {
        Image(uiImage: videoConfig.rowAssets.rectangleVideoStackPlaylistImage)
            .resizable()
            .foregroundStyle(videoConfig.colorAssets.whiteColor)
            .frame(width: 16, height: 16)
    }
}

#Preview {
    func makeNullViewModel() -> VideoPlaylistCellViewModel {
        VideoPlaylistCellViewModel(
            videoPlaylistThumbnailLoader: VideoPlaylistThumbnailLoader(thumbnailLoader: Preview_ThumbnailLoader()),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            videoPlaylistEntity: videoPlaylistEntity(),
            onTapMoreOptions: { _ in }
        )
    }
    
    func videoPlaylistEntity() -> VideoPlaylistEntity {
        VideoPlaylistEntity(
            id: 1,
            name: "Favorites",
            count: 15,
            type: .favourite,
            creationTime: Date(),
            modificationTime: Date()
        )
    }
    
    return Group {
        FavoritePlaylistCell(
            viewModel: makeNullViewModel(),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter()
        )
        .frame(height: 80, alignment: .center)
        
        FavoritePlaylistCell(
            viewModel: makeNullViewModel(),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter()
        )
        .frame(height: 80, alignment: .center)
        .preferredColorScheme(.dark)
    }
}
