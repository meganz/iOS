import MEGAData
import MEGADomain
import SwiftUI

struct AlbumListView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @StateObject var viewModel: AlbumListViewModel
    @ObservedObject var createAlbumCellViewModel: CreateAlbumCellViewModel
    var router: AlbumListViewRouting
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 10) {
                    CreateAlbumCell(viewModel: createAlbumCellViewModel)
                        .opacity($editMode.wrappedValue.isEditing ? 0.5 : 1)
                        .onTapGesture { viewModel.onCreateAlbum() }
                    
                    ForEach(viewModel.albums, id: \.self) { album in
                        router.cell(album: album, selection: viewModel.selection)
                        .clipped()
                        .onTapGesture(count: 1) { viewModel.onAlbumTap(album) }
                    }
                }
            }
            .padding(.horizontal, 6)
        }
        .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel)
        .alert(item: $viewModel.albumAlertType, content: { albumAlertType in
            viewModel.showAlertView(albumAlertType)
        })
        .overlay(viewModel.shouldLoad ? ProgressView()
            .scaleEffect(1.5) : nil)
        .fullScreenCover(item: $viewModel.album, onDismiss: {
            viewModel.newAlbumContent = nil
        }, content: {
            router.albumContainer(album: $0, newAlbumPhotosToAdd: viewModel.newAlbumContent?.photos, existingAlbumNames: {viewModel.albumNames})
                .ignoresSafeArea()
        })
        .sheet(item: $viewModel.newlyAddedAlbum, onDismiss: {
            viewModel.navigateToNewAlbum()
        }, content: {
            albumContentAdditionView($0)
        })
        .sheet(isPresented: $viewModel.showShareAlbumLinks, onDismiss: {
            viewModel.setEditModeToInactive()
        }, content: {
            shareLinksView(forAlbums: viewModel.selectedUserAlbums)
        })
        .padding([.top, .bottom], 10)
        .onAppear {
            viewModel.loadAlbums()
        }
        .onDisappear {
            viewModel.cancelLoading()
        }
        .progressViewStyle(.circular)
        .environment(\.editMode, $editMode)
        .onReceive(viewModel.selection.$editMode) {
            editMode = $0
        }
        .onReceive(viewModel.$albumHudMessage) { hudMessage in
            guard let hudMessage else { return }
            SVProgressHUD.dismiss(withDelay: 3)
            SVProgressHUD.show(hudMessage.icon, status: hudMessage.message)
        }
    }
    
    @ViewBuilder
    private func albumContentAdditionView(_ album: AlbumEntity) -> some View {
        AlbumContentPickerView(viewModel: AlbumContentPickerViewModel(
            album: album,
            photoLibraryUseCase: PhotoLibraryUseCase(photosRepository: PhotoLibraryRepository.newRepo, searchRepository: FilesSearchRepository.newRepo),
            completion: { album, selectedPhotos in
                viewModel.onNewAlbumContentAdded(album, photos: selectedPhotos)
            },
            isNewAlbum: true,
            configuration: PhotoLibraryContentConfiguration(
                scaleFactor: UIDevice().iPadDevice ? .five : .three)
            )
        )
    }
    
    private func shareLinksView(forAlbums albums: [AlbumEntity]) -> some View {
        EnforceCopyrightWarningView(viewModel: EnforceCopyrightWarningViewModel(
            preferenceUseCase: PreferenceUseCase.default,
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo))) {
                GetAlbumsLinksViewWrapper(albums: albums)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationBarHidden(true)
            }
    }
}
