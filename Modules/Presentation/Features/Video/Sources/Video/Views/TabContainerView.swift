import ContentLibraries
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct TabContainerView: View {
    @State private var currentTab: VideosTab = .all
    
    @StateObject private var videoListViewModel: VideoListViewModel
    @StateObject private var videoPlaylistViewModel: VideoPlaylistsViewModel
    @StateObject private var syncModel: VideoRevampSyncModel
    private let videoConfig: VideoConfig
    private let router: any VideoRevampRouting
    private let didChangeCurrentTab: (_ currentTab: VideosTab) -> Void
    
    init(
        videoListViewModel: @autoclosure @escaping () -> VideoListViewModel,
        videoPlaylistViewModel: @autoclosure @escaping () -> VideoPlaylistsViewModel,
        syncModel: @autoclosure @escaping () -> VideoRevampSyncModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting,
        didChangeCurrentTab: @escaping (_: VideosTab) -> Void
    ) {
        self._videoListViewModel = StateObject(wrappedValue: videoListViewModel())
        self._videoPlaylistViewModel = StateObject(wrappedValue: videoPlaylistViewModel())
        self._syncModel = StateObject(wrappedValue: syncModel())
        self.videoConfig = videoConfig
        self.router = router
        self.didChangeCurrentTab = didChangeCurrentTab
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(currentTab: self.$currentTab, videoConfig: videoConfig)
                .frame(height: syncModel.showsTabView ? TabBarView.defaultHeight : 0)
                .opacity(syncModel.showsTabView ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: syncModel.showsTabView)
            
            TabView(selection: self.$currentTab) {
                VideoListView(
                    viewModel: videoListViewModel,
                    videoConfig: videoConfig,
                    router: router
                )
                .tag(VideosTab.all)
                .gesture(syncModel.showsTabView ? nil : DragGesture())
                
                PlaylistView(
                    viewModel: videoPlaylistViewModel,
                    videoConfig: videoConfig,
                    router: router
                )
                .tag(VideosTab.playlist)
                .gesture(syncModel.showsTabView ? nil : DragGesture())
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(videoConfig.colorAssets.pageBackgroundColor)
        }
        .onChange(of: currentTab) {
            didChangeCurrentTab($0)
        }
    }
}

#Preview {
    TabContainerView(
        videoListViewModel: makeNullViewModel(),
        videoPlaylistViewModel: makeVideoPlaylistsViewModel(),
        syncModel: VideoRevampSyncModel(),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter(),
        didChangeCurrentTab: { _ in }
    )
}

#Preview {
    TabContainerView(
        videoListViewModel: makeNullViewModel(),
        videoPlaylistViewModel: makeVideoPlaylistsViewModel(),
        syncModel: VideoRevampSyncModel(),
        videoConfig: .preview,
        router: Preview_VideoRevampRouter(),
        didChangeCurrentTab: { _ in }
    )
    .preferredColorScheme(.dark)
}

@MainActor
private func makeNullViewModel() -> VideoListViewModel {
    VideoListViewModel(
        syncModel: VideoRevampSyncModel(),
        contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: Preview_PhotoLibraryUseCase()),
        selection: VideoSelection(),
        fileSearchUseCase: Preview_FilesSearchUseCase(),
        thumbnailLoader: Preview_ThumbnailLoader(),
        sensitiveNodeUseCase: Preview_SensitiveNodeUseCase(),
        nodeUseCase: Preview_NodeUseCase(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false)
    )
}

@MainActor
private func makeVideoPlaylistsViewModel() -> VideoPlaylistsViewModel {
    VideoPlaylistsViewModel(
        videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
        videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
        videoPlaylistModificationUseCase: Preview_VideoPlaylistModificationUseCase(),
        sortOrderPreferenceUseCase: Preview_SortOrderPreferenceUseCase(),
        syncModel: VideoRevampSyncModel(),
        alertViewModel: .preview,
        renameVideoPlaylistAlertViewModel: .preview,
        thumbnailLoader: Preview_ThumbnailLoader(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        contentProvider: VideoPlaylistsViewModelContentProvider(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase()
        )
    )
}
