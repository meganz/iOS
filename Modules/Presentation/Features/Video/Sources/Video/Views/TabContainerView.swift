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
                .frame(height: syncModel.showsTabView ? 44 : 0)
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

struct TabBarView: View {
    @Binding var currentTab: VideosTab
    @Namespace var namespace
    let videoConfig: VideoConfig
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        HStack {
            if interfaceOrientation.isLandscape {
                Spacer()
            }
            ForEach(VideosTab.allCases, id: \.self) { tab in
                TabBarItem(
                    currentTab: self.$currentTab,
                    namespace: namespace.self,
                    tabBarItemName: tab.title,
                    tab: tab,
                    videoConfig: videoConfig
                )
                .frame(maxWidth: orientation.isPortrait ? .infinity : 195)
            }
            if interfaceOrientation.isLandscape {
                Spacer()
            }
        }
        .frame(maxWidth: interfaceOrientation.isPortrait ? .infinity : nil)
        .edgesIgnoringSafeArea(.all)
        .background(videoConfig.colorAssets.navigationBgColor)
        .onRotate { newOrientation in
            orientation = newOrientation
        }
    }
    
    private var interfaceOrientation: UIInterfaceOrientation {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .unknown
        }
        return windowScene.interfaceOrientation
    }
}

struct TabBarItem: View {
    @Binding var currentTab: VideosTab
    let namespace: Namespace.ID
    
    var tabBarItemName: String
    var tab: VideosTab
    
    let videoConfig: VideoConfig
    
    var body: some View {
        Button(
            action: { currentTab = tab },
            label: buttonContent
        )
    }
    
    private func buttonContent() -> some View {
        VStack {
            Spacer()
            
            Text(tabBarItemName)
                .multilineTextAlignment(.center)
                .font(isTabActive ? .system(.subheadline).bold() : .subheadline)
                .foregroundColor(
                    isTabActive
                    ? videoConfig.colorAssets.tabActiveIndicatorColor
                    : videoConfig.colorAssets.tabInactiveTextColor
                )
            Group {
                if isTabActive {
                    videoConfig.colorAssets.tabActiveIndicatorColor
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace, properties: .frame)
                } else {
                    videoConfig.colorAssets.tabInactiveIndicatorColor
                        .frame(height: 2)
                }
            }
        }
        .animation(.spring(), value: self.currentTab)
    }
    
    private var isTabActive: Bool {
        currentTab == tab
    }
}

#Preview {
    func makeNullViewModel() -> VideoListViewModel {
        VideoListViewModel(
            syncModel: VideoRevampSyncModel(),
            contentProvider: VideoListViewModelContentProvider(photoLibraryUseCase: Preview_PhotoLibraryUseCase()),
            selection: VideoSelection(),
            fileSearchUseCase: Preview_FilesSearchUseCase(),
            thumbnailLoader: Preview_ThumbnailLoader(),
            sensitiveNodeUseCase: Preview_SensitiveNodeUseCase()
        )
    }

    func makeVideoPlaylistsViewModel() -> VideoPlaylistsViewModel {
        VideoPlaylistsViewModel(
            videoPlaylistsUseCase: Preview_VideoPlaylistUseCase(),
            videoPlaylistContentUseCase: Preview_VideoPlaylistContentUseCase(),
            videoPlaylistModificationUseCase: Preview_VideoPlaylistModificationUseCase(),
            syncModel: VideoRevampSyncModel(),
            alertViewModel: .preview,
            renameVideoPlaylistAlertViewModel: .preview,
            thumbnailLoader: Preview_ThumbnailLoader(),
            contentProvider: VideoPlaylistsViewModelContentProvider(
                videoPlaylistsUseCase: Preview_VideoPlaylistUseCase())
        )
    }
    
    return Group {
        TabContainerView(
            videoListViewModel: makeNullViewModel(),
            videoPlaylistViewModel: makeVideoPlaylistsViewModel(),
            syncModel: VideoRevampSyncModel(),
            videoConfig: .preview,
            router: Preview_VideoRevampRouter(),
            didChangeCurrentTab: { _ in }
        )
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
}
