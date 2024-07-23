import MEGADomain
import MEGAL10n
import MEGAPresentation
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
            videos: viewModel.videos,
            router: router,
            thumbnailLoader: viewModel.thumbnailLoader,
            sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
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
        .task {
            await viewModel.subscribeToSelectedDisplayActionChanged()
        }
        .alert(isPresented: $viewModel.shouldShowRenamePlaylistAlert, viewModel.renameVideoPlaylistAlertViewModel)
        .task {
            await viewModel.monitorVideoPlaylists()
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
        .task {
            await viewModel.subscribeToSelectedVideoPlaylistActionChanged()
        }
        .alert(
            Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Title.deletePlaylist,
            isPresented: $viewModel.shouldShowDeletePlaylistAlert
        ) {
            deleteVideoPlaylistAlertView
        } message: {
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Subtitle.playlistWillBeDeletedButItsContentsWillStayInYourTimeline)
        }
        .confirmationDialog(
            Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.ActionSheet.Title.removeFromPlaylist,
            isPresented: $viewModel.shouldShowDeleteVideosFromVideoPlaylistActionSheet,
            titleVisibility: .visible
        ) {
            Button(Strings.Localizable.remove, role: .destructive) {
                Task {
                    try? await viewModel.deleteVideosFromVideoPlaylist()
                }
            }
            Button(Strings.Localizable.cancel, role: .cancel) {
                viewModel.didTapCancelOnDeleteVideosFromVideoPlaylistActionSheet()
            }
        }
    }
    
    private var deleteVideoPlaylistAlertView: some View {
        HStack {
            Button(Strings.Localizable.cancel) { }
            Button(Strings.Localizable.delete) {
                viewModel.deleteVideoPlaylist()
            }
            .keyboardShortcut(.defaultAction)
        }
    }
}

struct PlaylistContentView: View {
    
    private let videoConfig: VideoConfig
    private let previewEntity: VideoPlaylistCellPreviewEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let videos: [NodeEntity]
    let router: any VideoRevampRouting
    @StateObject private var videoSelection: VideoSelection
    private let onTapAddButton: () -> Void
    
    init(
        videoConfig: VideoConfig,
        previewEntity: VideoPlaylistCellPreviewEntity,
        videos: [NodeEntity],
        router: any VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        videoSelection: @autoclosure @escaping () -> VideoSelection,
        onTapAddButton: @escaping () -> Void
    ) {
        self.videoConfig = videoConfig
        self.previewEntity = previewEntity
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
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
            videos: videos,
            videoConfig: videoConfig,
            selection: videoSelection,
            router: router,
            viewType: .playlistContent,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase
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
        videos: [],
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
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
        videos: [],
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
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
        videos: [],
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
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
        videos: [],
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}
