import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct AddToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: AddToCollectionViewModel
    
    public init(viewModel: @autoclosure @escaping () -> AddToCollectionViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        NavigationStackView {
            content
                .background(TokenColors.Background.page.swiftUI)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Text(Strings.Localizable.cancel)
                                .font(.body)
                                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        if viewModel.showBottomBar {
                            Spacer()
                            
                            Button {
                                viewModel.addToCollectionTapped()
                                dismiss()
                            } label: {
                                Text(Strings.Localizable.Photos.AddTo.Button.Title.add)
                                    .font(.body)
                                    .foregroundStyle(
                                        viewModel.isAddButtonDisabled ?
                                        TokenColors.Text.disabled.swiftUI :
                                            TokenColors.Text.secondary.swiftUI)
                            }
                            .disabled(viewModel.isAddButtonDisabled)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(viewModel.title)
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.mode {
        case .album: albumsContent
        case .collection: collectionsContent
        }
    }
    
    private var albumsContent: some View {
        AddToAlbumsView(viewModel: viewModel.addToAlbumsViewModel)
    }
    
    private var collectionsContent: some View {
        PageTabView(
            tabs: [
                .init(
                    title: Strings.Localizable.CameraUploads.Albums.title) {
                        albumsContent
                    },
                .init(
                    title: Strings.Localizable.Videos.Tab.Title.playlist) {
                        AddToPlaylistView(
                            viewModel: viewModel.addToPlaylistViewModel)
                    }
            ],
            selectedTextForegroundColor: TokenColors.Button.brand.swiftUI,
            textForegroundColor: TokenColors.Text.primary.swiftUI,
            tabSelectionIndicatorColor: TokenColors.Button.brand.swiftUI,
            backgroundColor: TokenColors.Background.surface1.swiftUI
        )
    }
}
