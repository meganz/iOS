import ContentLibraries
import MEGADomain
import MEGASwiftUI
import SwiftUI

struct TabContainerView: View {
    @State private var currentTab: VideosTab = .all
    @State private var orientation = UIDevice.current.orientation
    @State private var layoutID = UUID()
    
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
        GeometryReader { geometry in
            let tabBarHeight = currentTabBarHeight
            
            VStack(spacing: 0) {
                TabBarView(currentTab: self.$currentTab, videoConfig: videoConfig)
                    .frame(height: syncModel.showsTabView ? tabBarHeight : 0)
                    .frame(maxWidth: .infinity)
                    .opacity(syncModel.showsTabView ? 1 : 0)
                    .allowsHitTesting(syncModel.showsTabView)
                    .animation(.easeInOut(duration: 0.1), value: syncModel.showsTabView)
                
                TabView(selection: self.$currentTab) {
                    VideoListView(
                        viewModel: videoListViewModel,
                        videoConfig: videoConfig,
                        router: router
                    )
                    .tag(VideosTab.all)
                    .gesture(syncModel.showsTabView ? nil : DragGesture())
                    .ignoresSafeArea(edges: .bottom)
                    
                    PlaylistView(
                        viewModel: videoPlaylistViewModel,
                        videoConfig: videoConfig,
                        router: router
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .tag(VideosTab.playlist)
                    .gesture(syncModel.showsTabView ? nil : DragGesture())
                }
                .frame(width: geometry.size.width, height: geometry.size.height - (syncModel.showsTabView ? tabBarHeight : 0))
                .animation(.easeInOut(duration: 0.1), value: syncModel.showsTabView)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(videoListViewModel.featureFlagProvider.isLiquidGlassEnabled() ? .clear : videoConfig.colorAssets.pageBackgroundColor)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .id(layoutID)
            .onChange(of: geometry.safeAreaInsets) { _ in
                guard videoListViewModel.featureFlagProvider.isLiquidGlassEnabled() else { return }
                refreshLayoutID()
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onRotate { newOrientation in
            let isOrientationChanged = orientation.isLandscape != newOrientation.isLandscape
            orientation = newOrientation
            
            if isOrientationChanged {
                refreshLayoutID()
            }
        }
        .onChange(of: syncModel.showsTabView) { showsTabView in
            if showsTabView {
                refreshLayoutID()
            }
        }
        .onChange(of: currentTab) {
            didChangeCurrentTab($0)
        }
        .onAppear {
            guard videoListViewModel.featureFlagProvider.isLiquidGlassEnabled() else { return }
            refreshLayoutID()
        }
    }
    
    private var currentTabBarHeight: CGFloat {
        orientation.isLandscape ? 60 : TabBarView.defaultHeight
    }
    
    private func refreshLayoutID() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            layoutID = UUID()
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
        accountStorageUseCase: Preview_AccountStorageUseCase(),
        syncModel: VideoRevampSyncModel(),
        alertViewModel: .preview,
        renameVideoPlaylistAlertViewModel: .preview,
        thumbnailLoader: Preview_ThumbnailLoader(),
        featureFlagProvider: Preview_FeatureFlagProvider(isFeatureFlagEnabled: false),
        contentProvider: VideoPlaylistsViewModelContentProvider(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase()
        ),
        videoRevampRouter: Preview_VideoRevampRouter()
    )
}
