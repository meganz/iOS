import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

struct PlaylistView: View {
    
    @StateObject private var viewModel: VideoPlaylistsViewModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    
    init(
        viewModel: @autoclosure @escaping () -> VideoPlaylistsViewModel,
        videoConfig: VideoConfig,
        router: some VideoRevampRouting
    ) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.videoConfig = videoConfig
        self.router = router
    }
    
    var body: some View {
        VStack {
            newPlaylistView
            contentView
                .overlay(placeholder)
        }
        .background(videoConfig.colorAssets.pageBackgroundColor)
        .alert(isPresented: $viewModel.shouldShowAddNewPlaylistAlert, viewModel.alertViewModel)
        .alert(isPresented: $viewModel.shouldShowRenamePlaylistAlert, viewModel.renameVideoPlaylistAlertViewModel)
        .alert(
            Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Title.deletePlaylist,
            isPresented: $viewModel.shouldShowDeletePlaylistAlert
        ) {
            deleteVideoPlaylistAlertView
        } message: {
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Subtitle.playlistWillBeDeletedButItsContentsWillStayInYourTimeline)
        }
        .task {
            await viewModel.onViewAppeared()
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
        .onReceive(viewModel.$shouldShowVideoPlaylistPicker) { shouldShow in
            if shouldShow {
                router.openVideoPicker { selectedVideos in
                    viewModel.shouldShowVideoPlaylistPicker = false
                    Task {
                        await viewModel.addVideosToNewlyCreatedVideoPlaylist(videos: selectedVideos)
                    }
                }
            }
        }
        .onReceive(viewModel.$shouldOpenVideoPlaylistContent) { shouldOpen in
            if let newlyCreatedVideoPlaylist = viewModel.newlyCreatedVideoPlaylist, shouldOpen {
                router.openVideoPlaylistContent(
                    for: newlyCreatedVideoPlaylist,
                    presentationConfig: VideoPlaylistContentSnackBarPresentationConfig(
                        shouldShowSnackBar: true,
                        text: viewModel.newlyAddedVideosToPlaylistSnackBarMessage
                    )
                )
            }
        }
        .sheet(isPresented: $viewModel.isSheetPresented) {
            bottomView()
        }
    }
    
    private var deleteVideoPlaylistAlertView: some View {
        HStack {
            Button(Strings.Localizable.cancel) { }
            Button(Strings.Localizable.delete) {
                if let selectedVideoPlaylist = viewModel.selectedVideoPlaylistEntity {
                    Task {
                        await viewModel.deleteVideoPlaylist(selectedVideoPlaylist)
                    }
                }
            }
            .keyboardShortcut(.defaultAction)
        }
    }
    
    @ViewBuilder
    private func bottomView() -> some View {
        if #available(iOS 16.4, *) {
            iOS16SupportBottomSheetView()
                .presentationCornerRadius(16)
        } else if #available(iOS 16, *) {
            iOS16SupportBottomSheetView()
        } else {
            bottomSheetView()
        }
    }
    
    @available(iOS 16.0, *)
    private func iOS16SupportBottomSheetView() -> some View {
        bottomSheetView()
            .presentationDetents([ .height(presentationDetentsHeight) ])
            .presentationDragIndicator(.hidden)
    }
    
    private func bottomSheetView() -> some View {
        ActionSheetContentView(
            style: .plainIgnoreHeaderIgnoreScrolling,
            headerView: EmptyView(),
            actionButtons: {
                actionButtons()
            }()
        )
    }
    
    private var presentationDetentsHeight: CGFloat {
        let estimatedContentHeight: () -> CGFloat = {
            let textHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight
            let dividerHeight: CGFloat = 1
            let cellHeight = textHeight + dividerHeight
            let extraHeight: CGFloat = 75
            return (cellHeight * CGFloat(actionButtons().count)) + extraHeight
        }
        return estimatedContentHeight()
    }
    
    private func actionButtons() -> [ActionSheetButton] {
        let items = [
            ContextAction(
                type: .rename,
                icon: "rename",
                title: Strings.Localizable.rename
            ),
            ContextAction(
                type: .deletePlaylist,
                icon: "rubbishBin",
                title: Strings.Localizable.Videos.Tab.Playlist.PlaylistContent.Menu.deletePlaylist
            )
        ]
        
        return items
            .map { contextAction in
                ActionSheetButton(
                    icon: contextAction.icon,
                    title: contextAction.title,
                    action: { viewModel.didSelectActionSheetMenuAction(contextAction) }
                )
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.shouldShowVideosEmptyView {
            emptyView
        } else {
            listView
        }
    }
    
    private var emptyView: some View {
        VideoPlaylistEmptyView(videoConfig: videoConfig)
            .padding(.bottom, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private var newPlaylistView: some View {
        HStack(spacing: 8) {
            addPlaylistButton
            Text(Strings.Localizable.Videos.Tab.Playlist.Content.newPlaylist)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(videoConfig.colorAssets.primaryTextColor)

        }
        .frame(height: 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 8)
    }
    
    private var addPlaylistButton: some View {
        Button {
            viewModel.shouldShowAddNewPlaylistAlert = true
        } label: {
            ZStack {
                Circle()
                    .frame(width: 44, height: 44)
                
                Image(uiImage: videoConfig.rowAssets.addPlaylistImage.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .frame(width: 22, height: 22)
                    .tint(videoConfig.colorAssets.addPlaylistButtonTextColor)
            }
        }
        .tint(videoConfig.colorAssets.addPlaylistButtonBackgroundColor)
        .frame(width: 44, height: 44)
        .alert(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.title, isPresented: $viewModel.shouldShowAddNewPlaylistAlert) {
            TextField(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.placeholder, text: $viewModel.playlistName)
            Button(Strings.Localizable.Videos.Tab.Playlist.Content.Alert.Button.create) { }
                .keyboardShortcut(.defaultAction)
            Button(Strings.Localizable.cancel, role: .cancel) { }
        }
    }
        
    private var listView: some View {
        VideoPlaylistsCollectionViewRepresenter(
            thumbnailLoader: viewModel.thumbnailLoader,
            viewModel: viewModel,
            videoConfig: videoConfig,
            router: router,
            didSelectMoreOptionForItem: { viewModel.didSelectMoreOptionForItem($0) }
        )
        .listStyle(PlainListStyle())
        .padding(.horizontal, 8)
    }
    
    private var placeholder: some View {
        VideoListPlaceholderView(videoConfig: videoConfig, isActive: viewModel.shouldShowPlaceHolderView)
    }
}

#Preview {
    PlaylistView(
        viewModel: VideoPlaylistsViewModel(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(userVideoPlaylists: [.preview]),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: Preview_VideoPlaylistModificationUseCase(),
            syncModel: VideoRevampSyncModel(),
            alertViewModel: .preview,
            renameVideoPlaylistAlertViewModel: .preview, 
            thumbnailLoader: Preview_ThumbnailLoader()
        ),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter()
    )
}

#Preview {
    PlaylistView(
        viewModel: VideoPlaylistsViewModel(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: Preview_VideoPlaylistModificationUseCase(),
            syncModel: VideoRevampSyncModel(),
            alertViewModel: .preview,
            renameVideoPlaylistAlertViewModel: .preview,
            thumbnailLoader: Preview_ThumbnailLoader()
        ),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter()
    )
    .preferredColorScheme(.dark)
}
