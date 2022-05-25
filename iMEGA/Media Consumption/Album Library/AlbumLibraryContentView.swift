import SwiftUI

@available(iOS 14.0, *)
struct AlbumLibraryContentView: View {
    @StateObject var viewModel: AlbumLibraryContentViewModel
    var router: AlbumLibraryContentViewRouting
    
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
                        LazyVGrid(columns: viewModel.columns, spacing: 5) {
                            cell()
                                .clipped()
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isPresenting) {
            router.albumContent(for: viewModel.cameraUploadNode)
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
    
    @ViewBuilder
    private func cell() -> some View {
        if !viewModel.albums.isEmpty {
            ForEach(viewModel.albums) { album in
                router.cell(for: album.handle)
                    .onTapGesture(count: 1) {
                        isPresenting.toggle()
                        viewModel.cameraUploadNode = album
                    }
            }
        } else {
            router.singleCell()
                .onTapGesture(count: 1) {
                    isPresenting.toggle()
                    viewModel.cameraUploadNode = nil
                }
        }
    }
}
