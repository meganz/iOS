import ContentLibraries
import SwiftUI

struct AddToAlbumsView: View {
    @StateObject var viewModel: AddToAlbumsViewModel
    
    var body: some View {
        AlbumListContentView(viewModel: viewModel)
            .environment(\.editMode, $viewModel.editMode)
            .task {
                await viewModel.monitorUserAlbums()
            }
    }
}
