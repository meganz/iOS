import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct AddToPlaylistView: View {
    @ObservedObject var viewModel: AddToPlaylistViewModel
    
    var body: some View {
        contentView
            .alert(isPresented: $viewModel.showCreatePlaylistAlert,
                   viewModel.alertViewModel())
            .task {
                await viewModel.loadVideoPlaylists()
            }
            .task {
                await viewModel.monitorPlaylistUpdates()
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.videoPlaylists.isNotEmpty {
            VStack {
                NewPlaylistView(
                    addPlaylistAction: viewModel.onCreatePlaylistTapped)
                
                playlists
                    .overlay(VideoListPlaceholderView(
                        isActive: !viewModel.isVideoPlayListsLoaded))
                    .padding(.horizontal, TokenSpacing._3)
            }
        } else {
            empty
        }
    }
    
    private var playlists: some View {
        VideoPlaylistsCollectionViewRepresenter(
            viewModel: viewModel,
            router: viewModel.router)
    }
    
    private var empty: some View {
        ContentUnavailableView(label: {
            MEGAAssetsImageProvider.image(named: .glassPlaylist)
                .resizable()
                .frame(width: 128, height: 128)
        }, description: {
            Text(Strings.Localizable.Photos.AddToPlaylist.Empty.message)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }, actions: {
            MEGAButton(Strings.Localizable.Photos.AddToPlaylist.Empty.Create.Button.title,
                       action: viewModel.onCreatePlaylistTapped)
            .frame(width: 288)
        })
        .frame(maxHeight: .infinity)
    }
}
