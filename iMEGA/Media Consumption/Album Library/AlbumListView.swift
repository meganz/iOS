import ContentLibraries
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

struct AlbumListView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
    @StateObject var viewModel: AlbumListViewModel
    var router: any AlbumListViewRouting
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        content
        .throwingTask { try await viewModel.monitorAlbums() }
        .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel)
        .alert(item: $viewModel.albumAlertType, content: { albumAlertType in
            viewModel.showAlertView(albumAlertType)
        })
        .overlay(placeholderView)
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
        .onDisappear { viewModel.onViewDisappear() }
        .environment(\.editMode, $editMode)
        .onReceive(viewModel.selection.$editMode) { editMode = $0 }
        .onReceive(viewModel.$albumHudMessage) { hudMessage in
            guard let hudMessage else { return }
            SVProgressHUD.dismiss(withDelay: 3)
            SVProgressHUD.show(hudMessage.icon, status: hudMessage.message)
        }
    }
    
    private var content: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 10) {
                    CreateAlbumCell { viewModel.onCreateAlbum() }
                        .opacity($editMode.wrappedValue.isEditing ? 0.5 : 1)
                    
                    ForEach(viewModel.albums, id: \.self) { album in
                        router.cell(album: album, selection: viewModel.selection) {
                            viewModel.album = $0
                        }
                        .clipped()
                    }
                }
            }
            .padding(.horizontal, 6)
        }
    }
    
    private var placeholderView: some View {
        AlbumListPlaceholderView(isActive: viewModel.shouldLoad) { viewModel.onCreateAlbum() }
    }
    
    @ViewBuilder
    private func albumContentAdditionView(_ album: AlbumEntity) -> some View {
        AlbumContentPickerView(viewModel: AlbumContentPickerViewModel(
            album: album,
            photoLibraryUseCase: PhotoLibraryUseCase(
                photosRepository: PhotoLibraryRepository(
                    cameraUploadNodeAccess: CameraUploadNodeAccess.shared),
                searchRepository: FilesSearchRepository.newRepo, 
                sensitiveDisplayPreferenceUseCase: SensitiveDisplayPreferenceUseCase(
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                        repo: UserAttributeRepository.newRepo),
                    hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }),
                hiddenNodesFeatureFlagEnabled: { DIContainer.remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes) }
            ),
            completion: { album, selectedPhotos in
                viewModel.onNewAlbumContentAdded(album, photos: selectedPhotos)
            },
            isNewAlbum: true,
            configuration: PhotoLibraryContentConfiguration(
                selectLimit: 150,
                scaleFactor: UIDevice().iPadDevice ? .five : .three)
        ), invokeDismiss: {
            viewModel.newlyAddedAlbum = nil
        })
    }
    
    private func shareLinksView(forAlbums albums: [AlbumEntity]) -> some View {
        EnforceCopyrightWarningView(viewModel: EnforceCopyrightWarningViewModel(
            preferenceUseCase: PreferenceUseCase.default,
            copyrightUseCase: CopyrightUseCase(
                shareUseCase: ShareUseCase(
                    shareRepository: ShareRepository.newRepo,
                    filesSearchRepository: FilesSearchRepository.newRepo,
                    nodeRepository: NodeRepository.newRepo))),
                                    termsAgreedView: {
            GetAlbumsLinksViewWrapper(albums: albums)
                .ignoresSafeArea(edges: .bottom)
                .navigationBarHidden(true)
        }, invokeDismiss: {
            viewModel.showShareAlbumLinks = false
        })
    }
}
