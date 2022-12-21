import SwiftUI

struct AlbumListView: View {
    @StateObject var viewModel: AlbumListViewModel
    @ObservedObject var createAlbumCellViewModel: CreateAlbumCellViewModel
    
    var router: AlbumListViewRouting
    
    var body: some View {
        ZStack(alignment: .topTrailing)  {
            GeometryReader { proxy in
                if viewModel.shouldLoad {
                    ProgressView()
                        .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        LazyVGrid(columns: viewModel.columns, spacing: 0) {
                            if viewModel.isCreateAlbumFeatureFlagEnabled {
                                CreateAlbumCell(viewModel: createAlbumCellViewModel)
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
            }
        }
        .fullScreenCover(item: $viewModel.album) {
            router.albumContainer(album: $0)
                .ignoresSafeArea()
        }
        .padding([.top, .bottom], 10)
        .onAppear {
            viewModel.loadAlbums()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
}
