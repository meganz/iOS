import ContentLibraries
import MEGAAssets
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
            viewState: viewModel.viewState,
            previewEntity: viewModel.headerPreviewEntity,
            videos: viewModel.videos,
            playlistType: viewModel.videoPlaylistEntity.type,
            router: router,
            thumbnailLoader: viewModel.thumbnailLoader,
            sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
            nodeUseCase: viewModel.nodeUseCase,
            featureFlagProvider: viewModel.featureFlagProvider,
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
        .sheet(isPresented: $viewModel.shouldShowShareLinkView) {
            AnyView(router.showShareLink(videoPlaylist: viewModel.videoPlaylistEntity))
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
    private let viewState: VideoPlaylistContentViewModel.ViewState
    private let previewEntity: VideoPlaylistCellPreviewEntity
    private let thumbnailLoader: any ThumbnailLoaderProtocol
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private let videos: [NodeEntity]
    private let playlistType: VideoPlaylistEntityType
    let router: any VideoRevampRouting
    @StateObject private var videoSelection: VideoSelection
    private let onTapAddButton: () -> Void
    
    init(
        videoConfig: VideoConfig,
        viewState: VideoPlaylistContentViewModel.ViewState,
        previewEntity: VideoPlaylistCellPreviewEntity,
        videos: [NodeEntity],
        playlistType: VideoPlaylistEntityType,
        router: any VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        videoSelection: @autoclosure @escaping () -> VideoSelection,
        onTapAddButton: @escaping () -> Void
    ) {
        self.videoConfig = videoConfig
        self.viewState = viewState
        self.previewEntity = previewEntity
        self.thumbnailLoader = thumbnailLoader
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.nodeUseCase = nodeUseCase
        self.featureFlagProvider = featureFlagProvider
        self.videos = videos
        self.playlistType = playlistType
        self.router = router
        _videoSelection = StateObject(wrappedValue: videoSelection())
        self.onTapAddButton = onTapAddButton
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            if !videoSelection.editMode.isEditing {
                PlaylistContentHeaderView(
                    viewState: viewState,
                    previewEntity: previewEntity,
                    onTapAddButton: onTapAddButton
                )
            }
            
            content()
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    @ViewBuilder
    private func content() -> some View {
        switch viewState {
        case .partial, .loading, .error:
            VStack {
                EmptyView()
            }
            .frame(maxHeight: .infinity, alignment: .center)
        case .loaded:
            listView()
        case .empty:
            videoEmptyView()
                .frame(maxHeight: .infinity, alignment: .center)
        }
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
            MEGAAssetsImageProvider.image(named: .favouritesEmptyState)
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
            viewType: .playlistContent(type: playlistType),
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
    }
}

// MARK: Preview - ViewState.partial
#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        viewState: .partial,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "",
            duration: "",
            title: "",
            isExported: false,
            type: .favourite
        ),
        videos: [],
        playlistType: .user,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
}

// MARK: - Preview - ViewState.loading

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        viewState: .loading,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "",
            duration: "",
            title: "",
            isExported: false,
            type: .favourite
        ),
        videos: [],
        playlistType: .user,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}

// MARK: - Preview - ViewState.loaded

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        viewState: .loaded,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: [
                ImageContainer(image: Image(systemName: "person"), type: .thumbnail)
            ]),
            count: "1 video",
            duration: "3:05:20",
            title: "Magic of Disney’s Animal Kingdom",
            isExported: false,
            type: .user
        ),
        videos: [ .preview ],
        playlistType: .user,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}

// MARK: - Preview - ViewState.empty

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        viewState: .empty,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "",
            duration: "empty playlist",
            title: "Favourites",
            isExported: false,
            type: .favourite
        ),
        videos: [],
        playlistType: .user,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
}

// MARK: - Preview - ViewState.error

#Preview {
    PlaylistContentView(
        videoConfig: .preview,
        viewState: .error,
        previewEntity: VideoPlaylistCellPreviewEntity(
            thumbnail: VideoPlaylistThumbnail(type: .normal, imageContainers: []),
            count: "",
            duration: "",
            title: "",
            isExported: false,
            type: .user
        ),
        videos: [],
        playlistType: .user,
        router: Preview_VideoRevampRouter(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        videoSelection: VideoSelection(),
        onTapAddButton: {}
    )
    .preferredColorScheme(.dark)
}
