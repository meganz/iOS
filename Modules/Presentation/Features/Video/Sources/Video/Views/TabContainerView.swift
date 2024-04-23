import MEGADomain
import MEGASwiftUI
import SwiftUI

struct TabContainerView: View {
    @State private var currentTab: VideosTab = .all
    
    @StateObject var videoListViewModel: VideoListViewModel
    @StateObject var videoPlaylistViewModel: VideoPlaylistsViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    let didChangeCurrentTab: (_ currentTab: VideosTab) -> Void
    
    private var showTabView: Bool {
        videoListViewModel.syncModel.showsTabView
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabBarView(currentTab: self.$currentTab, videoConfig: videoConfig)
                .frame(height: showTabView ? 44 : 0)
                .opacity(showTabView ? 1 : 0)
                .animation(.easeInOut(duration: 0.1), value: showTabView)
            
            TabView(selection: self.$currentTab) {
                VideoListView(
                    viewModel: videoListViewModel,
                    videoConfig: videoConfig,
                    router: router
                )
                .tag(VideosTab.all)
                .gesture(showTabView ? nil : DragGesture())
                
                PlaylistView(
                    viewModel: videoPlaylistViewModel,
                    videoConfig: videoConfig
                )
                .tag(VideosTab.playlist)
                .gesture(showTabView ? nil : DragGesture())
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabContainerView(
                videoListViewModel: makeNullViewModel(),
                videoPlaylistViewModel: makeVideoPlaylistsViewModel(),
                videoConfig: .preview,
                router: Preview_VideoRevampRouter(),
                didChangeCurrentTab: { _ in }
            )
            TabContainerView(
                videoListViewModel: makeNullViewModel(),
                videoPlaylistViewModel: makeVideoPlaylistsViewModel(),
                videoConfig: .preview,
                router: Preview_VideoRevampRouter(),
                didChangeCurrentTab: { _ in }
            )
            .preferredColorScheme(.dark)
        }
    }
    
    static func makeNullViewModel() -> VideoListViewModel {
        VideoListViewModel(
            fileSearchUseCase: Preview_FilesSearchUseCase(),
            thumbnailUseCase: Preview_ThumbnailUseCase(),
            syncModel: VideoRevampSyncModel(),
            selection: VideoSelection()
        )
    }
    
    static func makeVideoPlaylistsViewModel() -> VideoPlaylistsViewModel {
        VideoPlaylistsViewModel(syncModel: VideoRevampSyncModel())
    }
}
