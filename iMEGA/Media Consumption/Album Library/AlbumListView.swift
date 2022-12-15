import SwiftUI

struct AlbumListView: View {
    @StateObject var viewModel: AlbumListViewModel
    var router: AlbumListViewRouting
    
    @State private var isPresenting = false
    
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
                                CreateAlbumCell()
                            }
                            ForEach(viewModel.albums, id: \.self) { album in
                                router.cell(album: album)
                                    .onTapGesture(count: 1)  {
                                        viewModel.album = album
                                        isPresenting.toggle()
                                    }
                                    .clipped()
                            }
                        }
                    }
                    .padding(.horizontal, 6)
                }
            }
        }
        .fullScreenCover(isPresented: $isPresenting) {
            albumContent
        }
        .padding([.top, .bottom], 10)
        .onAppear {
            viewModel.loadAlbums()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
    }
    
    @ViewBuilder
    private var albumContent: some View {
        if let album = viewModel.album {
            router.albumContent(album: album)
                .ignoresSafeArea()
        } else {
            ZStack {
                EmptyView()
            }.onAppear {
                isPresenting.toggle()
            }
        }
    }
}
