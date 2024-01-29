import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

enum VideosTab: CaseIterable {
    case all
    case playlist
    
    var title: String {
        switch self {
        case .all:
            return Strings.Localizable.Videos.Tab.Title.all
        case .playlist:
            return Strings.Localizable.Videos.Tab.Title.playlist
        }
    }
}

struct TabContainerView: View {
    @State var currentTab: VideosTab = .all
    
    let videoListViewModel: VideoListViewModel
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    
    var body: some View {
        VStack {
            TabBarView(currentTab: self.$currentTab, videoConfig: videoConfig)
                .frame(height: 44)
            
            TabView(selection: self.$currentTab) {
                VideoListView(
                    viewModel: videoListViewModel,
                    videoConfig: videoConfig,
                    router: router
                )
                .tag(VideosTab.all)
                PlaylistView(videoConfig: videoConfig).tag(VideosTab.playlist)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .edgesIgnoringSafeArea(.all)
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
                .frame(width: orientation.isPortrait ? .infinity : 195)
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
                videoConfig: .preview,
                router: Preview_VideoRevampRouter()
            )
            TabContainerView(
                videoListViewModel: makeNullViewModel(),
                videoConfig: .preview,
                router: Preview_VideoRevampRouter()
            )
            .preferredColorScheme(.dark)
        }
    }
    
    static func makeNullViewModel() -> VideoListViewModel {
        VideoListViewModel(
            fileSearchUseCase: Preview_FilesSearchUseCase(),
            thumbnailUseCase: Preview_ThumbnailUseCase()
        )
    }
}
