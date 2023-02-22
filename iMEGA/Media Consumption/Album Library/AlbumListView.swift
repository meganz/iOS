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
        .fullScreenCover(item: $viewModel.album, onDismiss: {
            viewModel.newAlbumContent = nil
        }, content: {
            router.albumContainer(album: $0, newAlbumPhotosToAdd: viewModel.newAlbumContent?.1)
                .ignoresSafeArea()
        })
        .sheet(item: $viewModel.newlyAddedAlbum, onDismiss: {
            viewModel.navigateToNewAlbum()
        }, content: {
            albumContentAdditionView($0)
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
            completion: { album, selectedPhotos in
                viewModel.onNewAlbumContentAdded(album, photos: selectedPhotos)
            })
        )
    }
}
