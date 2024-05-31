import MEGADomain
import MEGAL10n
import SwiftUI

struct PlaylistContentScreen: View {
    
    @StateObject private var viewModel: VideoPlaylistContentViewModel
    
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistContentViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        PlaylistContentView(
            videoConfig: videoConfig,
            previewEntity: viewModel.headerPreviewEntity,
            thumbnailUseCase: viewModel.thumbnailUseCase,
            videos: viewModel.videos,
            router: router,
            onTapAddButton: {}
        )
        .task {
            await viewModel.onViewAppeared()
        }
        .onReceive(viewModel.$shouldPopScreen) { shouldPopScreen in
            if shouldPopScreen {
                router.popScreen()
            }
        }
    }
}

struct PlaylistContentView: View {
    
    let videoConfig: VideoConfig
    let previewEntity: VideoPlaylistCellPreviewEntity
    let thumbnailUseCase: any ThumbnailUseCaseProtocol
    let videos: [NodeEntity]
    let router: any VideoRevampRouting
    let onTapAddButton: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            PlaylistContentHeaderView(
                videoConfig: videoConfig,
                previewEntity: previewEntity,
                onTapAddButton: onTapAddButton
            )
            
            if previewEntity.imageContainers.isEmpty {
                Spacer()
                videoEmptyView()
                Spacer()
            } else {
                listView()
            }
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    private func videoEmptyView() -> some View {
        VideoListEmptyView(
            videoConfig: .preview,
            image: videoEmptyViewImage(for: previewEntity),
            text: videoEmptyViewText(for: previewEntity)
        )
    }
    
    private func videoEmptyViewImage(for previewEntity: VideoPlaylistCellPreviewEntity) -> UIImage {
        switch previewEntity.type {
        case .favourite:
            videoConfig.playlistContentAssets.favouritesEmptyStateImage
        case .user:
            videoConfig.videoListAssets.noResultVideoImage
        }
    }
    
    private func videoEmptyViewText(for previewEntity: VideoPlaylistCellPreviewEntity) -> String {
        switch previewEntity.type {
        case .favourite:
            Strings.Localizable.noFavourites
        case .user:
            Strings.Localizable.Videos.Tab.All.Content.emptyState
        }
    }
    
    private func listView() -> some View {
        AllVideosCollectionViewRepresenter(
            thumbnailUseCase: thumbnailUseCase,
            videos: videos,
            videoConfig: videoConfig,
            selection: VideoSelection(),
            router: router,
            viewType: .playlistContent
        )
    }
}

// MARK: Preview

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "24 Videos",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .favourite
        ),
        thumbnailUseCase: Preview_ThumbnailUseCase(),
        videos: [],
        router: Preview_VideoRevampRouter(),
        onTapAddButton: {}
    )
}

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "24 Videos",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .user
        ),
        thumbnailUseCase: Preview_ThumbnailUseCase(),
        videos: [],
        router: Preview_VideoRevampRouter(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "",
            duration: "",
            title: "Favourites",
            isExported: false,
            type: .favourite
        ),
        thumbnailUseCase: Preview_ThumbnailUseCase(),
        videos: [],
        router: Preview_VideoRevampRouter(),
        onTapAddButton: {}
    )
}

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        previewEntity: VideoPlaylistCellPreviewEntity(
            imageContainers: [],
            count: "",
            duration: "",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .user
        ),
        thumbnailUseCase: Preview_ThumbnailUseCase(),
        videos: [],
        router: Preview_VideoRevampRouter(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}
