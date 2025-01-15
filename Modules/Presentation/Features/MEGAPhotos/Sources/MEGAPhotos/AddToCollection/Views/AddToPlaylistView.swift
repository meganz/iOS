import ContentLibraries
import MEGADesignToken
import MEGADomain
import SwiftUI

struct AddToPlaylistView: View {
    @ObservedObject var viewModel: AddToPlaylistViewModel
    
    var body: some View {
        VStack {
            NewPlaylistView {
                
            }
            
            contentView
                .overlay(VideoListPlaceholderView(
                    isActive: !viewModel.isVideoPlayListsLoaded))
                .padding(.horizontal, TokenSpacing._3)
        }
    }
    
    private var contentView: some View {
        VideoPlaylistsCollectionViewRepresenter(
            viewModel: viewModel,
            router: viewModel.router,
            didSelectMoreOptionForItem: { _ in})
        .task {
            await viewModel.loadVideoPlaylists()
        }
    }
}
