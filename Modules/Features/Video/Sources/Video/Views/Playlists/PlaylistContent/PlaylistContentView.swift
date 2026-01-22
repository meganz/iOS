import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
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
            searchText: viewModel.searchText,
            playlistType: viewModel.videoPlaylistEntity.type,
            router: router,
            thumbnailLoader: viewModel.thumbnailLoader,
            sensitiveNodeUseCase: viewModel.sensitiveNodeUseCase,
            nodeUseCase: viewModel.nodeUseCase,
            featureFlagProvider: viewModel.featureFlagProvider,
            videoSelection: videoSelection,
            sortHeaderConfig: viewModel.sortHeaderConfig,
            sortOrder: $viewModel.sortOrder,
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
            guard shouldShow else { return }
            viewModel.showVideoPicker()
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
    private let searchText: String?
    private let playlistType: VideoPlaylistEntityType
    let router: any VideoRevampRouting
    @StateObject private var videoSelection: VideoSelection
    @Binding var sortOrder: MEGAUIComponent.SortOrder
    let sortHeaderConfig: SortHeaderConfig
    private let onTapAddButton: () -> Void
    
    init(
        videoConfig: VideoConfig,
        viewState: VideoPlaylistContentViewModel.ViewState,
        previewEntity: VideoPlaylistCellPreviewEntity,
        videos: [NodeEntity],
        searchText: String?,
        playlistType: VideoPlaylistEntityType,
        router: any VideoRevampRouting,
        thumbnailLoader: some ThumbnailLoaderProtocol,
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        featureFlagProvider: some FeatureFlagProviderProtocol,
        videoSelection: @autoclosure @escaping () -> VideoSelection,
        sortHeaderConfig: SortHeaderConfig,
        sortOrder: Binding<MEGAUIComponent.SortOrder>,
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
        self.searchText = searchText
        self.playlistType = playlistType
        self.router = router
        _videoSelection = StateObject(wrappedValue: videoSelection())
        self.sortHeaderConfig = sortHeaderConfig
        self._sortOrder = sortOrder
        self.onTapAddButton = onTapAddButton
    }
    
    private var isMediaRevampEnabled: Bool {
        featureFlagProvider.isFeatureFlagEnabled(for: .mediaRevamp)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !videoSelection.editMode.isEditing {
                PlaylistContentHeaderView(
                    viewState: viewState,
                    previewEntity: previewEntity,
                    isMediaRevampEnabled: isMediaRevampEnabled,
                    onTapAddButton: onTapAddButton
                )
            }
            if isMediaRevampEnabled && !videoSelection.editMode.isEditing {
                sortHeaderView()
                    .frame(height: 36)
            }
            content()
        }
        .overlay(alignment: .bottomTrailing) {
            RoundedPrimaryImageButton(
                image: MEGAAssets.Image.plus,
                isLiquidGlassEnabled: featureFlagProvider.isLiquidGlassEnabled(),
                action: { onTapAddButton() }
            )
            .padding(TokenSpacing._5)
            .opacity(isMediaRevampEnabled && !videoSelection.editMode.isEditing && previewEntity.shouldShowAddButton ? 1 : 0)
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
    }
    
    @ViewBuilder
    private func sortHeaderView() -> some View {
        ResultsHeaderView(height: 44, leftView: {
            SortHeaderView(config: sortHeaderConfig, selection: $sortOrder)
        })
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
            MEGAAssets.UIImage.favouritesEmptyState
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
            searchText: searchText,
            videoConfig: videoConfig,
            selection: videoSelection,
            router: router,
            viewType: .playlistContent(type: playlistType),
            sectionTopInset: (isMediaRevampEnabled && !videoSelection.editMode.isEditing) ? 0 : TokenSpacing._5,
            thumbnailLoader: thumbnailLoader,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
    }
}
