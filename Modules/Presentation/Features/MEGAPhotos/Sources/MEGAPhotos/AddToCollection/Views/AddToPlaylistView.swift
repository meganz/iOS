import ContentLibraries
import MEGADesignToken
import MEGADomain
import SwiftUI

struct AddToPlaylistView: View {
    @ObservedObject var viewModel: AddToPlaylistViewModel
    
    var body: some View {
        VStack {
            NewPlaylistView(
                addPlaylistAction: viewModel.onCreatePlaylistTapped)
            
            contentView
                .overlay(VideoListPlaceholderView(
                    isActive: !viewModel.isVideoPlayListsLoaded))
                .padding(.horizontal, TokenSpacing._3)
        }
        .alert(isPresented: $viewModel.showCreatePlaylistAlert,
               viewModel.alertViewModel())
    }
    
    private var contentView: some View {
        VideoPlaylistsCollectionViewRepresenter(
            viewModel: viewModel,
            router: viewModel.router)
        .task {
            await viewModel.loadVideoPlaylists()
        }
        .task {
            await viewModel.monitorPlaylistUpdates()
        }
    }
}
