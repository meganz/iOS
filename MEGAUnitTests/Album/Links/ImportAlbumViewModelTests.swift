import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
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
    
    func testLoadPublicAlbum_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase())
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
    }
    
    func testLoadPublicAlbum_onFullAlbumLink_shouldChangeLinkStatusSetAlbumNameAndLoadPhotos() async throws {
        let photos = try makePhotos()
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2, name: albumName))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: albumUseCase)
        XCTAssertNil(sut.publicAlbumName)
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
        
        await sut.loadPublicAlbum()
        
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
        XCTAssertEqual(sut.publicAlbumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertTrue(sut.isPhotosLoaded)
    }
    
    func testLoadPublicAlbum_onSharedAlbumError_shouldShowCannotAccessAlbumAlert() async throws {
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
        
        await sut.loadPublicAlbum()
        
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .invalid])
        XCTAssertTrue(sut.showCannotAccessAlbumAlert)
    }
    
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() async throws {
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
        
        await sut.loadWithNewDecryptionKey()
        
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
        XCTAssertEqual(sut.publicAlbumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertEqual(sut.publicLink, link)
    }
    
    func testLoadWithNewDecryptionKey_invalidKeyEntered_shouldSetStatusToInvalid() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink, publicAlbumUseCase: MockPublicAlbumUseCase())
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "<<<<"
        
        await sut.loadWithNewDecryptionKey()
        
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
    
    func testIsToolbarButtonsDisabled_onContentLoadAndSelection_shouldEnableAndDisableCorrectly() async throws {
        let photos = try makePhotos()
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let sut = makeImportAlbumViewModel(publicLink: try requireDecryptionKeyAlbumLink,
                                           publicAlbumUseCase: albumUseCase)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
        await sut.loadWithNewDecryptionKey()

        XCTAssertEqual(sut.publicLinkStatus, .loaded)
        
        XCTAssertFalse(sut.isToolbarButtonsDisabled)
        
        sut.enablePhotoLibraryEditMode(true)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([NodeEntity(handle: 5)])
        XCTAssertFalse(sut.isToolbarButtonsDisabled)
        
        sut.photoLibraryContentViewModel.selection.allSelected = false
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
    }
    
    func testSelectButtonOpacity_onLinkStatusAndSelectionHiddenChange_shouldChangeCorrectly() async throws {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                        nodes: [])
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertEqual(sut.selectButtonOpacity, 0.3, accuracy: 0.1)
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = true
        XCTAssertEqual(sut.selectButtonOpacity, 0.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = false
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
    }
    
    func testImportAlbum_onAlbumNameNotInConflict_shouldShowImportLocation() async throws {
        let album = SetEntity(handle: 3, name: "valid album name")
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showImportAlbumLocation)
    }
    
    func testImportAlbum_onAlbumNameInConflict_shouldShowRenameAlbumAlert() async throws {
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        await sut.loadPublicAlbum()
   
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showRenameAlbumAlert)
    }
    
    func testImportAlbum_onAccountStorageWillExceed_shouldShowStorageAlert() async throws {
        // Arrange
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let accountStorageUseCase = MockAccountStorageUseCase(willStorageQuotaExceed: true)
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           accountStorageUseCase: accountStorageUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showStorageQuotaWillExceed)
    }
    
    func testImportAlbum_onAccountStorageWillNotExceed_shouldNotShowStorageAlert() async throws {
        // Arrange
        let album = SetEntity(handle: 3,
                              name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sharedAlbumEntity = makeSharedAlbumEntity(set: album)
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity))
        let accountStorageUseCase = MockAccountStorageUseCase(willStorageQuotaExceed: false)
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           accountStorageUseCase: accountStorageUseCase)
        await sut.loadPublicAlbum()
        XCTAssertFalse(sut.showStorageQuotaWillExceed)
        
        // Act
        await sut.importAlbum()
        
        // Assert
        XCTAssertFalse(sut.showStorageQuotaWillExceed)
    }
    
    func testImportFolderLocation_onFolderSelected_shouldImportAlbumPhotosAndShowSnackbar() async throws {
        let albumName = "New Album (1)"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: albumName))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(importAlbumResult: .success)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        let exp = expectation(description: "Should toggle loading to show then hide")
        exp.expectedFulfillmentCount = 2
        var showLoadingResult = [Bool]()
        sut.$showLoading
            .dropFirst()
            .sink {
                showLoadingResult.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        
        await sut.importAlbumTask?.value
        await fulfillment(of: [exp], timeout: 1.0)
        
        XCTAssertTrue(sut.showSnackBar)
        XCTAssertEqual(sut.snackBarViewModel().snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName)))
    }
    
    func testImportFolderLocation_onFolderSelectedAndImportFails_shouldShowErrorInSnackbar() async throws {
        let albumName = "New Album (1)"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: albumName))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(
            importAlbumResult: .failure(GenericErrorEntity()))
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertTrue(sut.showSnackBar)
        XCTAssertEqual(sut.snackBarViewModel().snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumFailedToSaveToCloudDrive(albumName)))
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
    
    func testImportFolderLocation_selectedPhotos_shouldImportOnlySelectedPhotosAndShowToastMessage() async throws {
        let selectedPhotos = [NodeEntity(handle: 1),
                              NodeEntity(handle: 76)]
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(
            importAlbumResult: .success)
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: "Test"))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(selectedPhotos)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertTrue(sut.showSnackBar)
        XCTAssertEqual(Set(importPublicAlbumUseCase.photosToImport ?? []),
                       Set(selectedPhotos))
        XCTAssertEqual(sut.snackBarViewModel().snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.filesSaveToCloudDrive(selectedPhotos.count)))
    }
    
    func testShowImportToolbarButton_userNotLoggedIn_shouldNotShowImportBarButtonAndToggleWithSelection() throws {
        let accountUseCase = MockAccountUseCase(isLoggedIn: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           accountUseCase: accountUseCase)
        XCTAssertFalse(sut.showImportToolbarButton)
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        
        XCTAssertFalse(sut.showImportToolbarButton)
    }
    
    func testRenameAlbum_newNameProvided_shouldShowImportAlbumLocationAndUseNewNameDuringImport() async throws {
        let newAlbumName = "The new album name"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: "Test"))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: MockImportPublicAlbumUseCase(
                                            importAlbumResult: .success))
        await sut.loadPublicAlbum()
        
        sut.renameAlbum(newName: newAlbumName)
        XCTAssertTrue(sut.showImportAlbumLocation)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertTrue(sut.showSnackBar)
        XCTAssertEqual(sut.snackBarViewModel().snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(newAlbumName)))
    }
    
    func testReservedAlbumNames_onImportAlbumLoad_shouldContainUserAlbumNames() async throws {
        let userAlbumNames = ["Album 1", "Album 2"]
        let albumNameUseCase = MockAlbumNameUseCase(userAlbumNames: userAlbumNames)
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: "Test"))
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           albumNameUseCase: albumNameUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.reservedAlbumNames?.contains(userAlbumNames) ?? false)
    }
    
    // MARK: - Private
    
    private func makeImportAlbumViewModel(publicLink: URL,
                                          publicAlbumUseCase: some PublicAlbumUseCaseProtocol = MockPublicAlbumUseCase(),
                                          albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
                                          accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
                                          importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol = MockImportPublicAlbumUseCase(),
                                          accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase()
    ) -> ImportAlbumViewModel {
        let sut = ImportAlbumViewModel(
            publicLink: publicLink,
            publicAlbumUseCase: publicAlbumUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase,
            importPublicAlbumUseCase: importPublicAlbumUseCase,
            accountUseCase: accountUseCase)
        trackForMemoryLeaks(on: sut)
        return sut
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
}
