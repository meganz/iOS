import MEGADomain
import MEGAL10n
import SwiftUI

struct PlaylistContentScreen: View {
    
    @StateObject private var viewModel: VideoPlaylistContentViewModel
    
    private let videoConfig: VideoConfig
    @StateObject private var videoSelection: VideoSelection
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistContentViewModel,
        videoConfig: VideoConfig,
        videoSelection: @autoclosure @escaping () -> VideoSelection,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        _videoSelection = StateObject(wrappedValue: videoSelection())
        self.router = router
    }
    
    var body: some View {
        PlaylistContentView(
            videoConfig: videoConfig,
            previewEntity: viewModel.headerPreviewEntity,
            thumbnailUseCase: viewModel.thumbnailUseCase,
            videos: viewModel.videos,
            router: router,
            videoSelection: videoSelection,
            onTapAddButton: { viewModel.shouldShowVideoPlaylistPicker = true }
        )
        .task {
            await viewModel.onViewAppeared()
        }
        .task {
            await viewModel.subscribeToAllSelected()
        }
        .onReceive(viewModel.$shouldPopScreen) { shouldPopScreen in
            if shouldPopScreen {
                router.popScreen()
            }
        }
        .onReceive(viewModel.$shouldShowVideoPlaylistPicker) { shouldShow in
            if shouldShow {
                router.openVideoPicker { selectedVideos in
                    viewModel.shouldShowVideoPlaylistPicker = false
                    Task {
                        await viewModel.addVideosToVideoPlaylist(videos: selectedVideos)
                    }
                }
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
    @StateObject private var videoSelection: VideoSelection
    let onTapAddButton: () -> Void
    
    init(
        videoConfig: VideoConfig,
        previewEntity: VideoPlaylistCellPreviewEntity,
        thumbnailUseCase: any ThumbnailUseCaseProtocol,
        videos: [NodeEntity],
        router: any VideoRevampRouting,
        videoSelection: @autoclosure @escaping () -> VideoSelection,
        onTapAddButton: @escaping () -> Void
    ) {
        self.videoConfig = videoConfig
        self.previewEntity = previewEntity
        self.thumbnailUseCase = thumbnailUseCase
        self.videos = videos
        self.router = router
        _videoSelection = StateObject(wrappedValue: videoSelection())
        self.onTapAddButton = onTapAddButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            if !videoSelection.editMode.isEditing {
                PlaylistContentHeaderView(
                    videoConfig: videoConfig,
                    previewEntity: previewEntity,
                    onTapAddButton: onTapAddButton
                )
            }
            
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
            selection: videoSelection,
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
        videoSelection: VideoSelection(),
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
        videoSelection: VideoSelection(),
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
        videoSelection: VideoSelection(),
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
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}
