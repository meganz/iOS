import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAPermissions
import MEGAPhotos
import MEGAPreference
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI
import Video

struct MediaTabView: View {
    @ObservedObject var viewModel: MediaTabViewModel
    @State private var orientation = UIDevice.current.orientation
    
    var body: some View {
        tabs
            .ignoresSafeArea(.container, edges: isLiquidGlassSupported ? .bottom : [])
            .overlay {
                if viewModel.isSearching {
                    VisualMediaSearchResultsView(
                        viewModel: viewModel.visualMediaSearchResultsViewModel
                    )
                }
            }
    }
    
    private var tabs: some View {
        MEGASwiftUI.PageTabView(
            tabs: MediaTab.allCases.map { PageTabItem(id: $0, title: $0.title) },
            selectedTab: $viewModel.selectedTab,
            selectedTextForegroundColor: TokenColors.Button.brand.swiftUI,
            textForegroundColor: TokenColors.Text.secondary.swiftUI,
            tabSelectionIndicatorColor: TokenColors.Button.brand.swiftUI,
            backgroundColor: TokenColors.Background.surface1.swiftUI,
            // Disable tab switching in edit mode, but keep content interactive
            isTabSwitchingDisabled: Binding(
                get: { viewModel.editMode == .active },
                set: { _ in }
            ),
            ignoresBottomContainerSafeArea: isLiquidGlassSupported,
            disableScrollViewInsets: isLiquidGlassSupported
        ) { tab in
            contentView(for: tab)
        }
        .environment(\.editMode, $viewModel.editMode)
        .onAppear {
            viewModel.onViewAppear()
        }
    }
    
    private var isLiquidGlassSupported: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        
        return false
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private func contentView(for tab: MediaTab) -> some View {
        switch viewModel.tabViewModels[tab] {
        case let videoTabViewModel as VideoTabViewModel:
            videoListView(videoTabViewModel: videoTabViewModel)
        case let albumTabViewModel as MediaAlbumTabContentViewModel:
            AlbumListView(
                viewModel: albumTabViewModel.albumListViewModel,
                router: albumTabViewModel.albumListViewRouter)
        case let timelineTabViewModel as MediaTimelineTabContentViewModel:
            TimelineMediaTabContentView(viewModel: timelineTabViewModel)
        case let playlistTabViewModel as PlaylistTabViewModel:
            playlistView(playlistTabViewModel: playlistTabViewModel)
        default:
            placeholderView(for: tab)
        }
    }
    
    @ViewBuilder
    private func videoListView(videoTabViewModel: VideoTabViewModel) -> some View {
        EquatableVideoListView(
            viewModel: videoTabViewModel.videoListViewModel,
            videoConfig: videoTabViewModel.videoConfig,
            router: videoTabViewModel.router
        )
    }
    
    @ViewBuilder
    private func playlistView(playlistTabViewModel: PlaylistTabViewModel) -> some View {
        PlaylistView(
            viewModel: playlistTabViewModel.videoPlaylistsViewModel,
            videoConfig: playlistTabViewModel.videoConfig,
            router: playlistTabViewModel.router
        )
    }
    
    // MARK: - Placeholder Views (WIP)
    
    @ViewBuilder
    private func placeholderView(for tab: MediaTab) -> some View {
        VStack {
            Spacer()
            Text(tab.title)
                .font(.title)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text("WIP - Tab content will be integrated later")
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TokenColors.Background.page.swiftUI)
    }
    
}
