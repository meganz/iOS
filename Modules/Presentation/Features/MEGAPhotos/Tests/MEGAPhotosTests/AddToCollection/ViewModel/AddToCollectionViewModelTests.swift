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
        
        @Test("When collection is selected for tab it should enable the add button")
        func addButtonDisabled() {
            let albumSelection = AlbumSelection(mode: .single)
            let setSelection = SetSelection(mode: .single)
            
            let sut = makeSUT(
                addToAlbumsViewModel: .init(albumSelection: albumSelection),
                addToPlaylistViewModel: .init(setSelection: setSelection))
            sut.selectedTab = .albums
            
            #expect(sut.isAddButtonDisabled == true)
            
            albumSelection.setSelectedAlbums([.init(id: 1, type: .user)])
            
            #expect(sut.isAddButtonDisabled == false)
            
            sut.selectedTab = .videoPlaylists
            
            #expect(sut.isAddButtonDisabled == true)
            
            setSelection.toggle(.init(handle: 5))
            
            #expect(sut.isAddButtonDisabled == false)
        }
        
        @Test("When items are not empty it should show bottom bar")
        func showBottomBar() {
            let addToAlbumsViewModel = AddToAlbumsViewModel()
            let addToPlaylistVieModel = AddToPlaylistViewModel()
            let sut = makeSUT(
                addToAlbumsViewModel: addToAlbumsViewModel,
                addToPlaylistViewModel: addToPlaylistVieModel)
            sut.selectedTab = .albums
            
            #expect(sut.showBottomBar == false)
            
            addToAlbumsViewModel.albums = [.init(album: .init(id: 1, type: .user))]
            
            #expect(sut.showBottomBar == true)
            
            sut.selectedTab = .videoPlaylists
            #expect(sut.showBottomBar == false)
            
            addToPlaylistVieModel.videoPlaylists = [.init(setIdentifier: .init(handle: 4))]
            
            #expect(sut.showBottomBar == true)
        }
    }
    
    @Suite("Add to collection button pressed")
    @MainActor
    struct AddToCollection {
        @Test("when add button pressed when album tab is active then it should add to album")
        func addButtonPressedAlbumMode() async throws {
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
        
        @Test("When add button pressed when playlist tab then add to playlist ")
        func addButtonPressedForPlaylistMode() async throws {
            let videoPlaylist = VideoPlaylistEntity(
                setIdentifier: SetIdentifier(handle: 5), name: "My Playlist")
            let setSelection = SetSelection()
            setSelection.toggle(videoPlaylist.setIdentifier)
            
            let videoPlaylistModificationUseCase = MockVideoPlaylistModificationUseCase()
            let addToPlaylistViewModel = AddToPlaylistViewModel(
                setSelection: setSelection,
                videoPlaylistModificationUseCase: videoPlaylistModificationUseCase)
            addToPlaylistViewModel.videoPlaylists = [videoPlaylist]
            let videos = [NodeEntity(handle: 10)]
            
            let sut = AddToCollectionViewModelTests
                .makeSUT(selectedPhotos: videos,
                         addToPlaylistViewModel: addToPlaylistViewModel)
            sut.selectedTab = .videoPlaylists
            
            await confirmation("Add to video playlist") { addVideoItems in
                let invocationTask = Task {
                    for await useCaseInvocation in videoPlaylistModificationUseCase.invocationSequence {
                        #expect(useCaseInvocation == .addVideoToPlaylist(id: videoPlaylist.id, nodes: videos))
                        addVideoItems()
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
    convenience init(
        setSelection: SetSelection = SetSelection(
            mode: .single, editMode: .active),
        videoPlaylistModificationUseCase: some VideoPlaylistModificationUseCaseProtocol = MockVideoPlaylistModificationUseCase()
    ) {
        self.init(
            thumbnailLoader: MockThumbnailLoader(),
            videoPlaylistContentUseCase: MockVideoPlaylistContentUseCase(),
            sortOrderPreferenceUseCase: MockSortOrderPreferenceUseCase(sortOrderEntity: .none),
            router: MockVideoRevampRouter(),
            setSelection: setSelection,
            videoPlaylistsUseCase: MockVideoPlaylistUseCase(),
            videoPlaylistModificationUseCase: videoPlaylistModificationUseCase,
            addToCollectionRouter: MockAddToCollectionRouter()
        )
    }
}
