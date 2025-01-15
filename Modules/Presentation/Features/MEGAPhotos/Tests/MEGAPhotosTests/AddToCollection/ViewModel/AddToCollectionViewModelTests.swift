import ContentLibraries
import MEGADomain
import MEGADomainMock
import MEGAL10n
@testable import MEGAPhotos
import MEGAPresentationMock
import Testing

@Suite("AddToCollectionViewModel Tests")
struct AddToCollectionViewModelTests {

    @Suite("Constructor")
    @MainActor
    struct Constructor {
        @Test("When album is selected it should enable add button")
        func addButtonDisabled() async throws {
            let albumSelection = AlbumSelection(mode: .single)
            
            let sut = AddToCollectionViewModelTests
                .makeSUT(addToAlbumsViewModel: .init(albumSelection: albumSelection))
            
            #expect(sut.isAddButtonDisabled == true)
            
            albumSelection.setSelectedAlbums([.init(id: 1, type: .user)])
            
            #expect(sut.isAddButtonDisabled == false)
        }
        
        @Test("When items are not empty it should show bottom bar")
        func showBottomBar() async throws {
            let addToAlbumsViewModel = AddToAlbumsViewModel()
            let sut = AddToCollectionViewModelTests
                .makeSUT(addToAlbumsViewModel: addToAlbumsViewModel)
            #expect(sut.showBottomBar == false)
            
            addToAlbumsViewModel.albums = [.init(album: .init(id: 1, type: .user))]
            
            #expect(sut.showBottomBar == true)
        }
    }
    
    @Suite("Add to collection button pressed")
    @MainActor
    struct AddToCollection {
        @Test func addButtonPressed() async throws {
            let album = AlbumEntity(id: 8, type: .user)
            let albumSelection = AlbumSelection(mode: .single)
            albumSelection.setSelectedAlbums([album])
            
            let photos = [NodeEntity(handle: 13)]
            
            let albumModificationUseCase = MockAlbumModificationUseCase()
            let sut = AddToCollectionViewModelTests
                .makeSUT(selectedPhotos: photos,
                         addToAlbumsViewModel: .init(
                            albumModificationUseCase: albumModificationUseCase,
                            albumSelection: albumSelection))
            
            await confirmation("Add to album") { addAlbumItems in
                let photos = [NodeEntity(handle: 13)]
                let invocationTask = Task {
                    for await useCaseInvocation in albumModificationUseCase.invocationSequence {
                        #expect(useCaseInvocation == .addPhotosToAlbum(id: album.id, nodes: photos))
                        addAlbumItems()
                        break
                    }
                }
                sut.addToCollectionTapped()
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
        
        @Test("Ensure title is correct for mode",
              arguments: [(AddToMode.album, Strings.Localizable.Set.AddTo.album),
                          (.collection, Strings.Localizable.Set.addTo)])
        func title(mode: AddToMode, expectedTitle: String) {
            let sut = AddToCollectionViewModelTests
                .makeSUT(mode: mode)
            
            #expect(sut.title == expectedTitle)
        }
    }

    @MainActor
    private static func makeSUT(
        mode: AddToMode = .album,
        selectedPhotos: [NodeEntity] = [],
        addToAlbumsViewModel: AddToAlbumsViewModel = .init(),
        addToPlaylistViewModel: AddToPlaylistViewModel = .init()
    ) -> AddToCollectionViewModel {
        .init(
            mode: mode,
            selectedPhotos: selectedPhotos,
            addToAlbumsViewModel: addToAlbumsViewModel,
            addToPlaylistViewModel: addToPlaylistViewModel)
    }
}

private extension AddToAlbumsViewModel {
    convenience init(
        albumModificationUseCase: MockAlbumModificationUseCase = MockAlbumModificationUseCase(),
        contentLibrariesConfiguration: ContentLibraries.Configuration = .init(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            nodeUseCase: MockNodeUseCase(),
            isAlbumPerformanceImprovementsEnabled: { false }),
        albumSelection: AlbumSelection = AlbumSelection(mode: .single)
    ) {
        self.init(
            monitorAlbumsUseCase: MockMonitorAlbumsUseCase(),
            thumbnailLoader: MockThumbnailLoader(),
            monitorUserAlbumPhotosUseCase: MockMonitorUserAlbumPhotosUseCase(),
            nodeUseCase: MockNodeUseCase(),
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(),
            sensitiveDisplayPreferenceUseCase: MockSensitiveDisplayPreferenceUseCase(),
            albumCoverUseCase: MockAlbumCoverUseCase(),
            albumListUseCase: MockAlbumListUseCase(),
            albumModificationUseCase: albumModificationUseCase,
            addToCollectionRouter: MockAddToCollectionRouter(),
            contentLibrariesConfiguration: contentLibrariesConfiguration,
            albumSelection: albumSelection)
    }
}

private extension AddToPlaylistViewModel {
    convenience init() {
        self.init(
            thumbnailLoader: MockThumbnailLoader(),
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
            router: MockVideoRevampRouter(),
            videoPlaylistsUseCase: MockVideoPlaylistUseCase())
    }
}
