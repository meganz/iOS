import ContentLibraries
import SwiftUI

struct AddToAlbumsView: View {
    @StateObject var viewModel: AddToAlbumsViewModel
    
    var body: some View {
        AlbumListContentView(viewModel: viewModel)
            .environment(\.editMode, $viewModel.editMode)
            .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel())
            .task {
                await viewModel.monitorUserAlbums()
            }
    }
}
