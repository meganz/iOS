import SwiftUI

public struct AlbumListContentView<ViewModel: AlbumListContentViewModelProtocol>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    @ObservedObject private var viewModel: ViewModel
    
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 10) {
                    CreateAlbumCell { viewModel.onCreateAlbumTapped() }
                        .opacity(viewModel.createButtonOpacity)
                    
                    ForEach(viewModel.albums, id: \.self) { albumViewModel in
                        AlbumCell(viewModel: albumViewModel)
                            .clipped()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }
}
