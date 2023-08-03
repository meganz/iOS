import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ImportAlbumViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private var validFullAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.nz/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKas"))
        }
    }
    
    private var requireDecryptionKeyAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.nz/collection/yro2RbQAx"))
        }
    }
    
    func testLoadPublicAlbum_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase())
        
        sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
    }
    
    func testLoadPublicAlbum_onFullAlbumLink_shouldChangeLinkStatusSetAlbumNameAndLoadPhotos() throws {
        let photos = makePhotos()
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2, name: albumName))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: albumUseCase)
        XCTAssertNil(sut.albumName)
        XCTAssertFalse(sut.isPhotosLoaded)
        
        let exp = expectation(description: "link status should change correctly")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .loaded])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.albumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertTrue(sut.isPhotosLoaded)
    }
    
    func testLoadPublicAlbum_onSharedAlbumError_shouldShowCannotAccessAlbumAlert() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase(publicAlbumResult: .failure(SharedAlbumErrorEntity.couldNotBeReadOrDecrypted)))
        XCTAssertEqual(sut.publicLinkStatus, .none)
        XCTAssertFalse(sut.showCannotAccessAlbumAlert)
        
        let exp = expectation(description: "link status should switch to in progress to invalid")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .invalid])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertTrue(sut.showCannotAccessAlbumAlert)
    }
    
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() throws {
        let link = try requireDecryptionKeyAlbumLink
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 5, name: albumName))
        let photos = makePhotos()
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicAlbumUseCase: albumUseCase)
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
        
        let exp = expectation(description: "link status should change correctly")
        sut.$publicLinkStatus
            .dropFirst()
            .collect(2)
            .first()
            .sink {
                XCTAssertEqual($0, [.inProgress, .loaded])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadWithNewDecryptionKey()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(sut.albumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertEqual(sut.publicLink, link)
    }
    
    func testLoadWithNewDecryptionKey_invalidKeyEntered_shouldSetStatusToInvalid() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink, publicAlbumUseCase: MockPublicAlbumUseCase())
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "<<<<"
        
        sut.loadWithNewDecryptionKey()
        
        XCTAssertEqual(sut.publicLinkStatus, .invalid)
    }
    
    func testEnablePhotoLibraryEditMode_onEditModeChange_shouldUpdateisSelectionEnabled() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        XCTAssertFalse(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(true)
        XCTAssertTrue(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(false)
        XCTAssertFalse(sut.isSelectionEnabled)
    }
    
    func testSelectionNavigationTitle_onItemSelectionChange_shouldUpdateSelectionTitle() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        XCTAssertFalse(sut.isSelectionEnabled)
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.selectTitle)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([NodeEntity(handle: 5)])
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.oneItemSelected(1))
        
        let multiplePhotos = makePhotos()
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(multiplePhotos)
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.itemsSelected(multiplePhotos.count))
        
        sut.photoLibraryContentViewModel.selection.allSelected = false
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.selectTitle)
    }
    
    func testIsToolbarButtonsDisabled_onContentLoadAndSelection_shouldEnableAndDisableCorrectly() throws {
        let photos = makePhotos()
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(publicLink: try requireDecryptionKeyAlbumLink,
                                           publicAlbumUseCase: albumUseCase)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
            sut.loadWithNewDecryptionKey()
        }
        XCTAssertFalse(sut.isToolbarButtonsDisabled)
        
        sut.enablePhotoLibraryEditMode(true)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([NodeEntity(handle: 5)])
        XCTAssertFalse(sut.isToolbarButtonsDisabled)
        
        sut.photoLibraryContentViewModel.selection.allSelected = false
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
    }
    
    func testSelectButtonOpacity_onLinkStatusAndSelectionHiddenChange_shouldChangeCorrectly() throws {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: [])
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertEqual(sut.selectButtonOpacity, 0.3, accuracy: 0.1)
        
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = true
        XCTAssertEqual(sut.selectButtonOpacity, 0.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = false
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
    }
    
    func testImportAlbum_onAlbumNameNotInConflict_shouldShowImportLocation() throws {
        let album = SetEntity(handle: 3, name: "valid album name")
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        let exp = expectation(description: "should show import album location")
        sut.$showImportAlbumLocation
            .dropFirst()
            .sink {
                XCTAssertTrue($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.importAlbum()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testImportAlbum_onAlbumNameInConflict_shouldShowRenameAlbumAlert() throws {
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        let exp = expectation(description: "should show rename album alert")
        sut.$showRenameAlbumAlert
            .dropFirst()
            .sink {
                XCTAssertTrue($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.importAlbum()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testImportAlbum_onAccountStorageWillExceed_shouldShowStorageAlert() throws {
        // Arrange
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let accountStorageUseCase = MockAccountStorageUseCase(willStorageQuotaExceed: true)
            
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           accountStorageUseCase: accountStorageUseCase)
        
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        let exp = expectation(description: "should show storage alert")
        var result: [Bool] = []
        sut.$showStorageQuotaWillExceed
            .dropFirst()
            .first()
            .sink(
                receiveCompletion: { _ in exp.fulfill() },
                receiveValue: { result.append($0) })
            .store(in: &subscriptions)
        
        // Act
        sut.importAlbum()
        wait(for: [exp], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(result, [true])
    }
    
    func testImportAlbum_onAccountStorageWillNotExceed_shouldNotShowStorageAlert() throws {
        // Arrange
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let accountStorageUseCase = MockAccountStorageUseCase(willStorageQuotaExceed: false)
            
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           accountStorageUseCase: accountStorageUseCase)
        
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        let exp = expectation(description: "should not show storage alert")
        var result: [Bool] = []
        sut.$showStorageQuotaWillExceed
            .timeout(.seconds(1), scheduler: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in exp.fulfill() },
                receiveValue: { result.append($0) })
            .store(in: &subscriptions)
        
        // Act
        sut.importAlbum()
        wait(for: [exp], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(result, [false])
    }
    
    // MARK: - Private
    
    private func makeImportAlbumViewModel(publicLink: URL,
                                          publicAlbumUseCase: some PublicAlbumUseCaseProtocol = MockPublicAlbumUseCase(),
                                          albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
                                          accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase()
    ) -> ImportAlbumViewModel {
        ImportAlbumViewModel(
            publicLink: publicLink,
            publicAlbumUseCase: publicAlbumUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase)
    }
    
    private func makeSharedAlbumEntity(set: SetEntity = SetEntity(handle: 1),
                                       setElements: [SetElementEntity] = []) -> SharedAlbumEntity {
        SharedAlbumEntity(set: set, setElements: setElements)
    }
    
    private func makePhotos() -> [NodeEntity] {
        [NodeEntity(handle: 1, hasThumbnail: true, mediaType: .image),
         NodeEntity(handle: 4, hasThumbnail: true, mediaType: .video),
         NodeEntity(handle: 7, hasThumbnail: true, mediaType: .image)
        ]
    }
    
    private func waitForLoadedState(linkStatus: AnyPublisher<AlbumPublicLinkStatus, Never>,
                                    action: () -> Void) {
        let exp = expectation(description: "wait for loaded state")
        linkStatus
            .dropFirst()
            .filter { $0 == .loaded }
            .first()
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
}
