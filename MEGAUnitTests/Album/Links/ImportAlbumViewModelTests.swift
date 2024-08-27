import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
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
    
    @MainActor
    func testLoadPublicAlbum_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() async throws {
        let tracker = MockTracker()

        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase(),
            tracker: tracker)
        
        sut.onViewAppear()
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportScreenEvent(),
                AlbumImportInputDecryptionKeyDialogEvent()
            ]
        )
    }
    
    @MainActor
    func testLoadPublicAlbum_onFullAlbumLink_shouldChangeLinkStatusSetAlbumNameAndLoadPhotos() async throws {
        let photos = try makePhotos()
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2, name: albumName))
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: albumUseCase,
            tracker: tracker)

        sut.onViewAppear()

        XCTAssertNil(sut.publicAlbumName)
        XCTAssertFalse(sut.shouldShowPhotoLibraryContent)
        
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
        XCTAssertTrue(sut.shouldShowPhotoLibraryContent)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportScreenEvent(),
                ImportAlbumContentLoadedEvent()
            ]
        )
    }
    
    @MainActor
    func testLoadPublicAlbum_onSharedAlbumError_shouldShowCannotAccessAlbumAlert() async throws {
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase(publicAlbumResult: .failure(SharedCollectionErrorEntity.couldNotBeReadOrDecrypted)),
            tracker: tracker)

        sut.onViewAppear()

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
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [AlbumImportScreenEvent()]
        )
    }
    
    @MainActor
    func testLoadPublicAlbum_onTaskCancellationError_shouldNotSetStatusToInvalid() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicAlbumUseCase: MockPublicAlbumUseCase(publicAlbumResult: .failure(CancellationError())))
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.publicLinkStatus != .invalid)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() async throws {
        let link = try requireDecryptionKeyAlbumLink
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 5, name: albumName))
        let photos = try makePhotos()
        let albumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicAlbumUseCase: albumUseCase,
            tracker: tracker)
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
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportInputDecryptionKeyDialogEvent(),
                ImportAlbumContentLoadedEvent()
            ]
        )
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
        XCTAssertEqual(sut.publicAlbumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .newest))
        XCTAssertEqual(sut.publicLink, link)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_invalidKeyEntered_shouldSetStatusToInvalid() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink, publicAlbumUseCase: MockPublicAlbumUseCase())
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "<<<<"
        
        await sut.loadWithNewDecryptionKey()
        
        XCTAssertEqual(sut.publicLinkStatus, .invalid)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_noInternetConnection_shouldShowNoInternetConnection() async throws {
        let networkMonitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            monitorUseCase: networkMonitorUseCase)
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "valid-key"
        XCTAssertFalse(sut.showNoInternetConnection)
        
        await sut.loadWithNewDecryptionKey()
        
        XCTAssertTrue(sut.showNoInternetConnection)
    }
    
    @MainActor
    func testEnablePhotoLibraryEditMode_onEditModeChange_shouldUpdateisSelectionEnabled() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        XCTAssertFalse(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(true)
        XCTAssertTrue(sut.isSelectionEnabled)
        
        sut.enablePhotoLibraryEditMode(false)
        XCTAssertFalse(sut.isSelectionEnabled)
    }
    
    @MainActor
    func testSelectionNavigationTitle_onItemSelectionChange_shouldUpdateSelectionTitle() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink)
        XCTAssertFalse(sut.isSelectionEnabled)
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.selectTitle)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([NodeEntity(handle: 5)])
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.General.Format.itemsSelected(1))
        
        let multiplePhotos = try makePhotos()
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(multiplePhotos)
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.General.Format.itemsSelected(multiplePhotos.count))
        
        sut.photoLibraryContentViewModel.selection.allSelected = false
        XCTAssertEqual(sut.selectionNavigationTitle, Strings.Localizable.selectTitle)
    }
    
    @MainActor
    func testIsToolbarButtonsDisabled_photosLoadedAndSelection_shouldEnableAndDisableCorrectly() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())

        let sut = makeImportAlbumViewModel(publicLink: try requireDecryptionKeyAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
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
    
    @MainActor
    func testIsToolbarButtonDisabled_noPhotosLoaded_shouldDisable() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase()

        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
    }
    
    @MainActor
    func testSelectButtonOpacity_onPhotosLoadedAndSelectionHiddenChange_shouldChangeCorrectly() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())
        
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
    
    @MainActor
    func testSelectButtonOpacity_noPhotos_shouldUseCorrectOpacity() async throws {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let publicAlbumUseCase = MockPublicAlbumUseCase(
            publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertEqual(sut.selectButtonOpacity, 0.3, accuracy: 0.1)
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.selectButtonOpacity, 0.3, accuracy: 0.1)
    }
    
    @MainActor
    func testImportAlbum_onAlbumNameNotInConflict_shouldShowImportLocation() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(
            handle: 3,
            name: "valid album name")
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showImportAlbumLocation)
    }
    
    @MainActor
    func testImportAlbum_onAlbumNameInConflict_shouldShowRenameAlbumAlert() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(
            handle: 3,
            name: Strings.Localizable.CameraUploads.Albums.Favourites.title)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        await sut.loadPublicAlbum()
   
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showRenameAlbumAlert)
    }
    
    @MainActor
    func testImportAlbum_onAccountStorageWillExceed_shouldShowStorageAlert() async throws {
        // Arrange
        let publicAlbumUseCase = makePublicAlbumUseCase(
            handle: 3,
            name: Strings.Localizable.CameraUploads.Albums.Favourites.title)

        let accountStorageUseCase = MockAccountStorageUseCase(willStorageQuotaExceed: true)
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           accountStorageUseCase: accountStorageUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showStorageQuotaWillExceed)
    }
    
    @MainActor
    func testImportAlbum_onAccountStorageWillNotExceed_shouldNotShowStorageAlert() async throws {
        // Arrange
        let publicAlbumUseCase = makePublicAlbumUseCase(
            handle: 3,
            name: Strings.Localizable.CameraUploads.Albums.Favourites.title)

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
    
    @MainActor
    func testImportAlbum_internetNotConnected_shouldToggleShowNoInternetConnection() async throws {
        let monitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        await sut.loadPublicAlbum()
        XCTAssertFalse(sut.showNoInternetConnection)
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.showNoInternetConnection)
    }
    
    @MainActor
    func testImportAlbum_onCalled_shouldLogAnalyticsEvent() async throws {
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           tracker: tracker)
        
        await sut.importAlbum()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportSaveToCloudDriveButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testImportFolderLocation_onFolderSelected_shouldImportAlbumPhotosAndShowSnackbar() async throws {
        let albumName = "New Album (1)"
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: albumName, nodes: try makePhotos())

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
        
        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName)))
    }
    
    @MainActor
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
        
        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumFailedToSaveToCloudDrive(albumName)))
    }
    
    @MainActor
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
    
    @MainActor
    func testImportFolderLocation_selectedPhotos_shouldImportOnlySelectedPhotosAndShowToastMessage() async throws {
        let selectedPhotos = [NodeEntity(handle: 1),
                              NodeEntity(handle: 76)]
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(
            importAlbumResult: .success)
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: "Test", nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(selectedPhotos)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertEqual(Set(importPublicAlbumUseCase.photosToImport ?? []),
                       Set(selectedPhotos))
        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.filesSaveToCloudDrive(selectedPhotos.count)))
    }
    
    @MainActor
    func testImportFolderLocation_noInternetConnection_shouldToggleShowNoInternetConnection() throws {
        let monitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        XCTAssertFalse(sut.showNoInternetConnection)
        
        sut.importFolderLocation = NodeEntity(handle: 24, isFolder: true)
        
        XCTAssertTrue(sut.showNoInternetConnection)
    }
    
    @MainActor
    func testShowImportToolbarButton_userNotLoggedIn_shouldNotShowImportBarButtonAndToggleWithSelection() throws {
        let accountUseCase = MockAccountUseCase(isLoggedIn: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           accountUseCase: accountUseCase)
        XCTAssertFalse(sut.showImportToolbarButton)
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        
        XCTAssertFalse(sut.showImportToolbarButton)
    }
    
    @MainActor
    func testRenameAlbum_newNameProvided_shouldShowImportAlbumLocationAndUseNewNameDuringImport() async throws {
        let newAlbumName = "The new album name"
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: "Test", nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: MockImportPublicAlbumUseCase(
                                            importAlbumResult: .success))
        await sut.loadPublicAlbum()
        
        sut.renameAlbum(newName: newAlbumName)
        XCTAssertTrue(sut.showImportAlbumLocation)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(newAlbumName)))
    }
    
    @MainActor
    func testReservedAlbumNames_onImportAlbumLoad_shouldContainUserAlbumNames() async throws {
        let userAlbumNames = ["Album 1", "Album 2"]
        let albumNameUseCase = MockAlbumNameUseCase(userAlbumNames: userAlbumNames)
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: "Test", nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           albumNameUseCase: albumNameUseCase)
        await sut.loadPublicAlbum()
        
        await sut.importAlbum()
        
        XCTAssertTrue(sut.reservedAlbumNames?.contains(userAlbumNames) ?? false)
    }
    
    @MainActor
    func testRenameAlbumAlertViewModel_albumLoadeded_isConfiguredCorrectly() throws {
        let albumName = "Test"
        let publicAlbumUseCase = makePublicAlbumUseCase(name: albumName, nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        let expectedAlertViewModel = TextFieldAlertViewModel(title: Strings.Localizable.AlbumLink.Alert.RenameAlbum.title,
                                                             affirmativeButtonTitle: Strings.Localizable.rename,
                                                             affirmativeButtonInitiallyEnabled: false,
                                                             destructiveButtonTitle: Strings.Localizable.cancel,
                                                             message: Strings.Localizable.AlbumLink.Alert.RenameAlbum.message(albumName))
        
        let alertViewModel = sut.renameAlbumAlertViewModel()
        
        XCTAssertEqual(alertViewModel, expectedAlertViewModel)
    }
    
    @MainActor
    func testRenameAlbum_noInternetConnection_shouldToggleNoInternetConnection() throws {
        let monitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        XCTAssertFalse(sut.showNoInternetConnection)
        
        sut.renameAlbum(newName: "Album name")
        
        XCTAssertTrue(sut.showNoInternetConnection)
    }
    
    @MainActor
    func testsShouldShowEmptyAlbumView_noPhotos_shouldReturnTrue() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 1)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertFalse(sut.shouldShowEmptyAlbumView)
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.shouldShowEmptyAlbumView)
        XCTAssertTrue(sut.isAlbumEmpty)
    }
    
    @MainActor
    func testsShouldShowEmptyAlbumView_photosLoaded_shouldReturnFalse() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        
        await sut.loadPublicAlbum()
        
        XCTAssertFalse(sut.shouldShowEmptyAlbumView)
        XCTAssertFalse(sut.isAlbumEmpty)
    }
    
    @MainActor
    func testIsShareLinkButtonDisabled_onAlbumLoaded_shouldEnableShareButtonEvenIfNoPhotosLoaded() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase)
        XCTAssertTrue(sut.isShareLinkButtonDisabled)
        
        await sut.loadPublicAlbum()
        
        XCTAssertFalse(sut.isShareLinkButtonDisabled)
    }
    
    @MainActor
    func testSaveToPhotos_whenSelectionModeIsActive_shouldSaveSelectedItems() async throws {
        // Arrange
        let transferWidgetResponder = MockTransferWidgetResponder()
        let permissionHandler = MockDevicePermissionHandler(
            photoAuthorization: .authorized,
            audioAuthorized: false,
            videoAuthorized: false,
            requestPhotoLibraryAccessPermissionsGranted: true)
        let publicAlbumUseCase = makePublicAlbumUseCase()
        let saveToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success(()))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           saveMediaUseCase: saveToPhotosUseCase,
                                           transferWidgetResponder: transferWidgetResponder,
                                           permissionHandler: permissionHandler)
        await sut.loadPublicAlbum()

        let multiplePhotos = try makePhotos()
        sut.enablePhotoLibraryEditMode(true)
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(multiplePhotos)
        
        // Act
        await sut.saveToPhotos()
        
        // Assert
        XCTAssertEqual(transferWidgetResponder.setProgressViewInKeyWindowCalled, 1)
        XCTAssertEqual(transferWidgetResponder.bringProgressToFrontKeyWindowIfNeededCalled, 1)
        XCTAssertEqual(transferWidgetResponder.updateProgressViewCalled, 1)
        XCTAssertEqual(transferWidgetResponder.showWidgetIfNeededCalled, 1)

        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.General.SaveToPhotos.started(multiplePhotos.count)))
    }
    
    @MainActor
    func testSaveToPhotos_whenSelectionModeNotActive_shouldSaveAllItemsInAlbum() async throws {
        // Arrange
        let transferWidgetResponder = MockTransferWidgetResponder()
        let permissionHandler = MockDevicePermissionHandler(
            photoAuthorization: .authorized,
            audioAuthorized: false,
            videoAuthorized: false,
            requestPhotoLibraryAccessPermissionsGranted: true)
        let multiplePhotos = try makePhotos()
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: multiplePhotos)
        let saveToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success(()))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           saveMediaUseCase: saveToPhotosUseCase,
                                           transferWidgetResponder: transferWidgetResponder,
                                           permissionHandler: permissionHandler)
        
        await sut.loadPublicAlbum()

        // Act
        await sut.saveToPhotos()
        
        // Assert
        XCTAssertEqual(transferWidgetResponder.setProgressViewInKeyWindowCalled, 1)
        XCTAssertEqual(transferWidgetResponder.bringProgressToFrontKeyWindowIfNeededCalled, 1)
        XCTAssertEqual(transferWidgetResponder.updateProgressViewCalled, 1)
        XCTAssertEqual(transferWidgetResponder.showWidgetIfNeededCalled, 1)
        XCTAssertEqual(sut.snackBarViewModel?.snackBar,
                       SnackBar(message: Strings.Localizable.General.SaveToPhotos.started(multiplePhotos.count)))
    }
    
    @MainActor
    func testSaveToPhotos_whenPhotosLibraryPermissionRequired_shouldShowAlert() async throws {
        // Arrange
        let transferWidgetResponder = MockTransferWidgetResponder()
        let permissionHandler = MockDevicePermissionHandler(
            photoAuthorization: .denied,
            audioAuthorized: false,
            videoAuthorized: false,
            requestPhotoLibraryAccessPermissionsGranted: false)
        let publicAlbumUseCase = makePublicAlbumUseCase()
        let saveToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success(()))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           saveMediaUseCase: saveToPhotosUseCase,
                                           transferWidgetResponder: transferWidgetResponder,
                                           permissionHandler: permissionHandler)
        await sut.loadPublicAlbum()

        let multiplePhotos = try makePhotos()
        sut.enablePhotoLibraryEditMode(true)
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(multiplePhotos)
        
        // Act
        await sut.saveToPhotos()
        
        // Assert
        XCTAssertEqual(transferWidgetResponder.setProgressViewInKeyWindowCalled, 0)
        XCTAssertEqual(transferWidgetResponder.bringProgressToFrontKeyWindowIfNeededCalled, 0)
        XCTAssertNil(sut.snackBarViewModel?.snackBar)
        XCTAssertTrue(sut.showPhotoPermissionAlert)
    }
    
    @MainActor
    func testSaveToPhotos_noInterNetConnection_shouldToggleNoInternetConnection() async throws {
        let monitorUseCase = MockNetworkMonitorUseCase(connected: false)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        XCTAssertFalse(sut.showNoInternetConnection)
        
        await sut.saveToPhotos()
        
        XCTAssertTrue(sut.showNoInternetConnection)
    }
    
    @MainActor
    func testSaveToPhotos_onCalled_shouldLogAnalyticsEvent() async throws {
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           tracker: tracker)
        
        await sut.saveToPhotos()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportSaveToDeviceButtonEvent()
            ]
        )
    }
    
    @MainActor
    func testStopAlbumLinkPreview_deinit_shouldBeCalled() async throws {
        let publicAlbumUseCase = MockPublicAlbumUseCase()
        var sut: ImportAlbumViewModel? = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                                                  publicAlbumUseCase: publicAlbumUseCase)
        await sut?.loadPublicAlbum()
        
        sut = nil
        
        XCTAssertEqual(publicAlbumUseCase.stopAlbumLinkPreviewCalled, 1)
    }
    
    @MainActor
    func testMonitorNetworkConnection_onConnectionChanges_updatesCorrectly() async throws {
        var results = [false, true, false, true]
        let connectionStream = makeConnectionMonitorStream(statuses: results)
        let monitorUseCase = MockNetworkMonitorUseCase(connectionChangedStream: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink {
                XCTAssertEqual($0, results.removeFirst())
            }
            .store(in: &subscriptions)
        
        await sut.monitorNetworkConnection()
    }
    
    @MainActor
    func testMonitorNetworkConnection_onAlbumLoaded_shouldNotUpdateConnection() async throws {
        let connectionStream = makeConnectionMonitorStream(statuses: [false, true, false])
        let monitorUseCase = MockNetworkMonitorUseCase(connectionChangedStream: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink { _ in
                XCTFail("Should not have updated")
            }
            .store(in: &subscriptions)
        
        await sut.loadPublicAlbum()
        await sut.monitorNetworkConnection()
    }
    
    @MainActor
    func testMonitorNetworkConnection_onAlbumInvalidAlbum_shouldNotUpdateConnection() async throws {
        let connectionStream = makeConnectionMonitorStream(statuses: [false, true, false])
        let publicAlbumUseCase = MockPublicAlbumUseCase(publicAlbumResult: .failure(GenericErrorEntity()))
        let monitorUseCase = MockNetworkMonitorUseCase(connectionChangedStream: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicAlbumUseCase: publicAlbumUseCase,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink { _ in
                XCTFail("Should not have updated")
            }
            .store(in: &subscriptions)
        
        await sut.loadPublicAlbum()
        await sut.monitorNetworkConnection()
    }
    
    // MARK: - Private
    
    @MainActor
    private func makeImportAlbumViewModel(publicLink: URL,
                                          publicAlbumUseCase: some PublicAlbumUseCaseProtocol = MockPublicAlbumUseCase(),
                                          albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
                                          accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
                                          importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol = MockImportPublicAlbumUseCase(),
                                          accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
                                          saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
                                          transferWidgetResponder: some TransferWidgetResponderProtocol = MockTransferWidgetResponder(),
                                          permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
                                          tracker: some AnalyticsTracking = MockTracker(),
                                          monitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
                                          file: StaticString = #file,
                                          line: UInt = #line
    ) -> ImportAlbumViewModel {
        let sut = ImportAlbumViewModel(
            publicLink: publicLink,
            publicAlbumUseCase: publicAlbumUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase,
            importPublicAlbumUseCase: importPublicAlbumUseCase,
            accountUseCase: accountUseCase,
            saveMediaUseCase: saveMediaUseCase,
            transferWidgetResponder: transferWidgetResponder,
            permissionHandler: permissionHandler,
            tracker: tracker,
            monitorUseCase: monitorUseCase)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    private func makeSharedAlbumEntity(set: SetEntity = SetEntity(handle: 1),
                                       setElements: [SetElementEntity] = []) -> SharedCollectionEntity {
        SharedCollectionEntity(set: set, setElements: setElements)
    }
    
    private func makeSetElements() -> [SetElementEntity] {
        [
            SetElementEntity(handle: 1),
            SetElementEntity(handle: 4),
            SetElementEntity(handle: 7)
        ]
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
    
    private func makePublicAlbumUseCase(handle: HandleEntity = 1, name: String = "valid album name", nodes: [NodeEntity] = []) -> some PublicAlbumUseCaseProtocol {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 1, name: name))
        return MockPublicAlbumUseCase(publicAlbumResult: .success(sharedAlbumEntity), nodes: nodes)
    }
    
    private func makeConnectionMonitorStream(statuses: [Bool]) -> AnyAsyncSequence<Bool> {
        AsyncStream { continuation in
            statuses.forEach {
                continuation.yield($0)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
}
