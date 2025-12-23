import ContentLibraries
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAPermissions
import MEGAPreference
import MEGASwiftUI
import SwiftUI
import Video

struct MediaTabView: View {
    @ObservedObject var viewModel: MediaTabViewModel

    var body: some View {
        MEGASwiftUI.PageTabView(
            tabs: MediaTab.allCases.map { tab in
                MEGASwiftUI.PageTabView.TabItem(id: tab, title: tab.title) {
                    contentView(for: tab)
                }
            },
            selectedTab: $viewModel.selectedTab,
            selectedTextForegroundColor: TokenColors.Button.brand.swiftUI,
            textForegroundColor: TokenColors.Text.secondary.swiftUI,
            tabSelectionIndicatorColor: TokenColors.Button.brand.swiftUI,
            backgroundColor: TokenColors.Background.surface1.swiftUI,
            // Disable tab switching in edit mode, but keep content interactive
            isTabSwitchingDisabled: Binding(
                get: { viewModel.editMode == .active },
                set: { _ in }
            )
        )
        .navigationTitle(viewModel.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                ForEach(viewModel.leadingNavigationBarViewModels) { viewModel in
                    NavigationBarItemViewBuilder.makeView(for: viewModel)
                }
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ForEach(viewModel.trailingNavigationBarViewModels) { viewModel in
                    NavigationBarItemViewBuilder.makeView(for: viewModel)
                }
            }
        }
        .environment(\.editMode, $viewModel.editMode)
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
            NewTimelineView(viewModel: timelineTabViewModel.timelineViewModel)
        case let playlistTabViewModel as PlaylistTabViewModel:
            playlistView(playlistTabViewModel: playlistTabViewModel)
        default:
            placeholderView(for: tab)
        }
    }

    @ViewBuilder
    private func videoListView(videoTabViewModel: VideoTabViewModel) -> some View {
        VideoListView(
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
