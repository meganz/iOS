import SwiftUI

@available(iOS 14.0, *)
struct AlbumLibraryContentView: View {
    @StateObject var viewModel: AlbumLibraryContentViewModel
    var router: AlbumLibraryContentViewRouting
    
    var body: some View {
        ZStack(alignment: .topTrailing)  {
            GeometryReader { proxy in
                if viewModel.albums.isEmpty {
                    ProgressView()
                        .position(x: proxy.frame(in: .local).midX, y: proxy.frame(in: .local).midY)
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        LazyVGrid(columns: viewModel.columns, spacing: 5) {
                            ForEach(viewModel.albums) { album in
                                router.cell(for: album)
                                    .clipped()
                                    .onTapGesture(count: 1) {
                                        viewModel.selectedAlbum = album
                                    }
                            }
                        }
                    }
                }
            }
        }
        .fullScreenCover(item: $viewModel.selectedAlbum) {
            router.albumContent(for: $0)
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
