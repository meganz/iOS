import SwiftUI

struct AlbumListView: View {
    @StateObject var viewModel: AlbumListViewModel
    @ObservedObject var createAlbumCellViewModel: CreateAlbumCellViewModel
    @State var alertViewModel: TextFieldAlertViewModel
    
    var router: AlbumListViewRouting
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns, spacing: 10) {
                    if viewModel.isCreateAlbumFeatureFlagEnabled {
                        CreateAlbumCell(viewModel: createAlbumCellViewModel)
                            .onTapGesture {
                                viewModel.showCreateAlbumAlert.toggle()
                            }
                    }
                    ForEach(viewModel.albums, id: \.self) { album in
                        router.cell(album: album)
                            .onTapGesture(count: 1)  {
                                viewModel.album = album
                            }
                            .clipped()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .alert(isPresented: $viewModel.showCreateAlbumAlert, alertViewModel)
        .overlay(viewModel.shouldLoad ? ProgressView()
            .scaleEffect(1.5) : nil)
        .fullScreenCover(item: $viewModel.album) {
            router.albumContainer(album: $0)
                .ignoresSafeArea()
        }
        .sheet(item: $viewModel.newlyAddedAlbum, content: { item in
            AlbumContentAdditionView(viewModel: AlbumContentAdditionViewModel(albumName: item.name, locationName: "All Locations"))
        })
        .padding([.top, .bottom], 10)
        .onAppear {
            viewModel.loadAlbums()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .progressViewStyle(.circular)
    }
}
