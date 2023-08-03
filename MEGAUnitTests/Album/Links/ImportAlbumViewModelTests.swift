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
        let photos = try makePhotos()
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
        exp.expectedFulfillmentCount = 2
        var linkStatusResults = [AlbumPublicLinkStatus]()
        sut.$publicLinkStatus
            .dropFirst()
            .sink {
                linkStatusResults.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
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
        exp.expectedFulfillmentCount = 2
        var linkStatusResults = [AlbumPublicLinkStatus]()
        sut.$publicLinkStatus
            .dropFirst()
            .sink {
                linkStatusResults.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadPublicAlbum()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .invalid])
        XCTAssertTrue(sut.showCannotAccessAlbumAlert)
    }
    
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() throws {
        let link = try requireDecryptionKeyAlbumLink
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 5, name: albumName))
        let photos = try makePhotos()
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicAlbumUseCase: albumUseCase)
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
        
        let exp = expectation(description: "link status should change correctly")
        exp.expectedFulfillmentCount = 2
        var linkStatusResults = [AlbumPublicLinkStatus]()
        sut.$publicLinkStatus
            .dropFirst()
            .sink {
                linkStatusResults.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.loadWithNewDecryptionKey()
        
        wait(for: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
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
        
        let multiplePhotos = try makePhotos()
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(multiplePhotos)
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.itemsSelected(multiplePhotos.count))
        
        sut.photoLibraryContentViewModel.selection.allSelected = false
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.selectTitle)
    }
    
    func testIsToolbarButtonsDisabled_onContentLoadAndSelection_shouldEnableAndDisableCorrectly() throws {
        let photos = try makePhotos()
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
        exp.expectedFulfillmentCount = 2
        var results: [Bool] = []
        sut.$showStorageQuotaWillExceed
            .sink {
                results.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        sut.importAlbum()
        wait(for: [exp], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(results, [false, true])
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
        
        XCTAssertFalse(sut.showStorageQuotaWillExceed)
        
        let exp = expectation(description: "should not show storage alert")
        exp.isInverted = true
        sut.$showStorageQuotaWillExceed
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        // Act
        sut.importAlbum()
        wait(for: [exp], timeout: 1.0)
        
        // Assert
        XCTAssertFalse(sut.showStorageQuotaWillExceed)
    }
    
    func testImportFolderLocation_onFolderSelected_shouldImportAlbumPhotosAndShowSnackbar() throws {
        let albumName = "New Album (1)"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: albumName))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(importAlbumResult: .success)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        waitForLoadingToggleAndShowSnackBar(showLoading: sut.$showLoading.eraseToAnyPublisher(),
                                            showSnackBar: sut.$showSnackBar.eraseToAnyPublisher()) {
            sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        }
        
        XCTAssertEqual(sut.snackBarViewModel().snackBar.message,
                       Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName))
    }
    
    func testImportFolderLocation_onFolderSelectedAndImportFails_shouldShowErrorInSnackbar() throws {
        let albumName = "New Album (1)"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: albumName))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(
            importAlbumResult: .failure(GenericErrorEntity()))
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        waitForLoadedState(linkStatus: sut.$publicLinkStatus.eraseToAnyPublisher()) {
            sut.loadPublicAlbum()
        }
        
        waitForLoadingToggleAndShowSnackBar(showLoading: sut.$showLoading.eraseToAnyPublisher(),
                                            showSnackBar: sut.$showSnackBar.eraseToAnyPublisher()) {
            sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        }
        
        XCTAssertEqual(sut.snackBarViewModel().snackBar.message,
                       Strings.Localizable.AlbumLink.Alert.Message.albumFailedToSaveToCloudDrive(albumName))
    }
    
    func testImportFolderLocation_noAlbumName_shouldDoNothingWhenCalled() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        
        let exp = expectation(description: "Should not show loading")
        exp.isInverted = true
        sut.$showLoading
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        
        wait(for: [exp], timeout: 0.25)
    }
    
    func testShowImportToolbarButton_userNotlLoggedIn_shouldNotShowImportBarButtonAndToggleWithSelection() throws {
        let accountUseCase = MockAccountUseCase(isLoggedIn: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           accountUseCase: accountUseCase)
        XCTAssertFalse(sut.showImportToolbarButton)
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        
        XCTAssertFalse(sut.showImportToolbarButton)
    }
    
    func testShowImportToolbarButton_userLoggedIn_shouldShowImportBarButtonAndHideDuringSelection() throws {
        let accountUseCase = MockAccountUseCase(isLoggedIn: true)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           accountUseCase: accountUseCase)
        XCTAssertTrue(sut.showImportToolbarButton)
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        
        XCTAssertFalse(sut.showImportToolbarButton)
        
        sut.photoLibraryContentViewModel.selection.editMode = .inactive
        
        XCTAssertTrue(sut.showImportToolbarButton)
    }
    
    // MARK: - Private
    
    private func makeImportAlbumViewModel(publicLink: URL,
                                          publicAlbumUseCase: some PublicAlbumUseCaseProtocol = MockPublicAlbumUseCase(),
                                          albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
                                          accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
                                          importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol = MockImportPublicAlbumUseCase(),
                                          accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase()
    ) -> ImportAlbumViewModel {
        ImportAlbumViewModel(
            publicLink: publicLink,
            publicAlbumUseCase: publicAlbumUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase,
            importPublicAlbumUseCase: importPublicAlbumUseCase,
            accountUseCase: accountUseCase)
    }
    
    private func makeSharedAlbumEntity(set: SetEntity = SetEntity(handle: 1),
                                       setElements: [SetElementEntity] = []) -> SharedAlbumEntity {
        SharedAlbumEntity(set: set, setElements: setElements)
    }
    
    private func makePhotos() throws -> [NodeEntity] {
        [NodeEntity(name: "test_image_1.png", handle: 1, hasThumbnail: true,
                    modificationTime: try "2023-01-01T22:05:04Z".date, mediaType: .image),
         NodeEntity(name: "test_video_1.mp4", handle: 4, hasThumbnail: true,
                    modificationTime: try "2023-01-01T22:05:04Z".date, mediaType: .video),
         NodeEntity(name: "test_image_4.jpg", handle: 7, hasThumbnail: true,
                    modificationTime: try "2023-01-01T22:05:04Z".date, mediaType: .image)
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
    
    private func waitForLoadingToggleAndShowSnackBar(showLoading: AnyPublisher<Bool, Never>,
                                                     showSnackBar: AnyPublisher<Bool, Never>,
                                                     action: () -> Void) {
        let loading = expectation(description: "Should toggle loading to show then hide")
        loading.expectedFulfillmentCount = 2
        var showLoadingResult = [Bool]()
        showLoading
            .dropFirst()
            .sink {
                showLoadingResult.append($0)
                loading.fulfill()
            }
            .store(in: &subscriptions)
        
        let snackBar = expectation(description: "Should show snackbar")
        showSnackBar
            .dropFirst()
            .sink {
                XCTAssertTrue($0)
                snackBar.fulfill()
            }
            .store(in: &subscriptions)
        
        action()
        
        wait(for: [loading, snackBar], timeout: 1.0)
        
        XCTAssertEqual(showLoadingResult, [true, false])
    }
}
