import SwiftUI
import MEGADomain

struct AlbumListView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @StateObject var viewModel: AlbumListViewModel
    @ObservedObject var createAlbumCellViewModel: CreateAlbumCellViewModel
    var router: AlbumListViewRouting
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 10) {
                    if viewModel.isCreateAlbumFeatureFlagEnabled {
                        CreateAlbumCell(viewModel: createAlbumCellViewModel)
                            .onTapGesture {
                                viewModel.showCreateAlbumAlert.toggle()
                            }
                    }
                    ForEach(viewModel.albums, id: \.self) { album in
                        router.cell(album: album)
                            .onTapGesture(count: 1)  {
                                viewModel.albumCreationAlertMsg = nil
                                viewModel.album = album
                            }
                            .clipped()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel)
        .overlay(viewModel.shouldLoad ? ProgressView()
            .scaleEffect(1.5) : nil)
        .fullScreenCover(item: $viewModel.album) {
            router.albumContainer(album: $0, messageForNewAlbum: viewModel.albumCreationAlertMsg)
                .ignoresSafeArea()
        }
        .sheet(item: $viewModel.newlyAddedAlbum, content: { item in
            albumContentAdditionView(item)
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
    
    @ViewBuilder
    private func albumContentAdditionView(_ album: AlbumEntity) -> some View {
        AlbumContentPickerView(viewModel: AlbumContentPickerViewModel(
            album: album,
            photoLibraryUseCase: PhotoLibraryUseCase(photosRepository: PhotoLibraryRepository.newRepo, searchRepository: FilesSearchRepository.newRepo),
            albumContentModificationUseCase: AlbumContentModificationUseCase(userAlbumRepo: UserAlbumRepository.newRepo),
            completion: { msg, album in
                viewModel.onAlbumContentAdded(msg, album)
            })
        )
    }
}
