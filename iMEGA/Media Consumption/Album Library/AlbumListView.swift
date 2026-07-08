import ContentLibraries
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwiftUI
import SwiftUI

struct AlbumListView: View {
    @StateObject var viewModel: AlbumListViewModel
    var router: any AlbumListViewRouting
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        AlbumListContentView(viewModel: viewModel, router: router, editMode: $editMode)
            .overlay(placeholderView)
            .padding(.top, TokenSpacing._3)
            .background(TokenColors.Background.page.swiftUI)
            .modifier(AlbumListPresentationModifier(viewModel: viewModel, router: router, editMode: $editMode))
    }
    
    private var placeholderView: some View {
        AlbumListPlaceholderView(
            isActive: viewModel.shouldLoad,
            onCreateTapHandler: nil)
    }
}

// MARK: - Content

/// Extracted into a dedicated `View` type (not a computed property) so that its
/// large generic body forms its own type-metadata / view-graph boundary. This
/// keeps `AlbumListView.body`'s concrete type small and avoids re-instantiating
/// one giant nested generic type on every render.
private struct AlbumListContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass: UserInterfaceSizeClass?
    @ObservedObject var viewModel: AlbumListViewModel
    let router: any AlbumListViewRouting
    @Binding var editMode: EditMode
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: viewModel.columns(horizontalSizeClass: horizontalSizeClass), spacing: 10) {
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
        .overlay(alignment: .bottomTrailing) {
            RoundedPrimaryImageButton(
                image: MEGAAssets.Image.plus,
                action: viewModel.onCreateAlbum)
            .padding(TokenSpacing._5)
            .opacity(editMode.isEditing ? 0 : 1)
        }
    }
}

// MARK: - Presentation

/// Groups every presentation and lifecycle modifier (alerts, sheets,
/// fullScreenCover, task, onReceive, HUD) into a single `ViewModifier`. This
/// collapses ~10 nested `ModifiedContent<…>` layers in `AlbumListView.body`
/// into one,  shrinking that body's concrete type. Layout
/// modifiers (`overlay`/`padding`/`background`) intentionally stay in
/// `AlbumListView.body` to preserve the original geometry.
private struct AlbumListPresentationModifier: ViewModifier {
    @ObservedObject var viewModel: AlbumListViewModel
    let router: any AlbumListViewRouting
    @Binding var editMode: EditMode
    
    func body(content: Content) -> some View {
        content
            .throwingTask { try await viewModel.monitorAlbums() }
            .alert(isPresented: $viewModel.showCreateAlbumAlert, viewModel.alertViewModel)
            .alert(item: $viewModel.albumAlertType, content: { albumAlertType in
                viewModel.showAlertView(albumAlertType)
            })
            .fullScreenCover(item: $viewModel.album, onDismiss: {
                viewModel.newAlbumContent = nil
            }, content: {
                router.albumContainer(album: $0, newAlbumPhotosToAdd: viewModel.newAlbumContent?.photos)
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
            .onDisappear { viewModel.onViewDisappear() }
            .environment(\.editMode, $editMode)
            .onReceive(viewModel.selection.$editMode) { editMode = $0 }
            .onReceive(viewModel.$albumHudMessage) { hudMessage in
                guard let hudMessage else { return }
                SVProgressHUD.dismiss(withDelay: 3)
                SVProgressHUD.show(hudMessage.icon, status: hudMessage.message)
            }
    }
    
    @ViewBuilder
    private func albumContentAdditionView(_ album: AlbumEntity) -> some View {
        AlbumContentPickerView(
            viewModel: AlbumContentPickerViewModel(
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
                            repo: UserAttributeRepository.newRepo)
                    )
                ),
                completion: { album, selectedPhotos in
                    viewModel.onNewAlbumContentAdded(album, photos: selectedPhotos)
                },
                isNewAlbum: true,
                configuration: PhotoLibraryContentConfiguration(
                    selectLimit: 150,
                    scaleFactor: UIDevice().iPadDevice ? .five : .three)
            ),
            invokeDismiss: {
                viewModel.newlyAddedAlbum = nil
            }
        )
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
