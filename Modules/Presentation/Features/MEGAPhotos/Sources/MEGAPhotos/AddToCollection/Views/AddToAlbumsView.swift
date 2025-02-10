import ContentLibraries
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import SwiftUI

struct AddToAlbumsView: View {
    @ObservedObject var viewModel: AddToAlbumsViewModel
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                AlbumListPlaceholderView(
                    isActive: viewModel.viewState == .loading)
                .padding(.top, TokenSpacing._3)
            case .ideal:
                content
            case .empty:
                empty
            }
        }
        .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel())
        .task {
            await viewModel.monitorUserAlbums()
        }
    }
    
    private var content: some View {
        AlbumListContentView(viewModel: viewModel)
            .padding(.top, TokenSpacing._3)
            .environment(\.editMode, $viewModel.editMode)
    }
    
    private var empty: some View {
        ContentUnavailableView(label: {
            MEGAAssetsImageProvider.image(named: .playlist)
        }, description: {
            Text(Strings.Localizable.Photos.AddToAlbum.Empty.message)
                .font(.body)
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
        }, actions: {
            MEGAButton(Strings.Localizable.CameraUploads.Albums.CreateAlbum.title,
                       action: viewModel.onCreateAlbumTapped)
            .frame(width: 288)
        })
        .frame(maxHeight: .infinity)
    }
}
