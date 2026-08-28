import Combine
import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGASwift
import MEGASwiftUI
import MEGATest
import Testing
import XCTest

final class ImportAlbumViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    private var validFullAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.app/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKas"))
        }
    }
    
    private var requireDecryptionKeyAlbumLink: URL {
        get throws {
            try XCTUnwrap(URL(string: "https://mega.app/collection/yro2RbQAx"))
        }
    }
    
    @MainActor
    func testLoadPublicAlbum_onCollectionLinkOpen_publicLinkStatusShouldBeNeedsDescryptionKey() async throws {
        let tracker = MockTracker()

        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(),
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
        let albumUseCase = MockPublicCollectionUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: albumUseCase,
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
                       photos.toPhotoLibrary(withSortType: .modificationDesc))
        XCTAssertTrue(sut.shouldShowPhotoLibraryContent)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumImportScreenEvent(),
                ShareLinkOpenedEvent(linkType: .album, authStatus: .loggedin),
                ImportAlbumContentLoadedEvent()
            ]
        )
    }
    
    @MainActor
    func testLoadPublicAlbum_onSharedAlbumError_shouldShowCannotAccessAlbumAlert() async throws {
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(publicAlbumResult: .failure(SharedCollectionErrorEntity.couldNotBeReadOrDecrypted)),
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
            publicCollectionUseCase: MockPublicCollectionUseCase(publicAlbumResult: .failure(CancellationError())))
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.publicLinkStatus != .invalid)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_validKeyEntered_shouldSetAlbumNameLoadAlbumContentsAndPreserveOrignalURL() async throws {
        let link = try requireDecryptionKeyAlbumLink
        let albumName = "New album (5)"
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 5, name: albumName))
        let photos = try makePhotos()
        let albumUseCase = MockPublicCollectionUseCase(publicAlbumResult: .success(sharedAlbumEntity),
                                                  nodes: photos)
        let tracker = MockTracker()
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicCollectionUseCase: albumUseCase,
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
                ShareLinkOpenedEvent(linkType: .album, authStatus: .loggedin),
                ImportAlbumContentLoadedEvent()
            ]
        )
        
        XCTAssertEqual(linkStatusResults, [.inProgress, .loaded])
        XCTAssertEqual(sut.publicAlbumName, albumName)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .modificationDesc))
        XCTAssertEqual(sut.publicLink, link)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_invalidKeyEntered_shouldSetStatusToInvalid() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink, publicCollectionUseCase: MockPublicCollectionUseCase())
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
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase)
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.isToolbarButtonsDisabled)
    }
    
    @MainActor
    func testSelectButtonOpacity_onPhotosLoadedAndSelectionHiddenChange_shouldChangeCorrectly() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase)
        XCTAssertEqual(sut.selectButtonOpacity, 0.3, accuracy: 0.1)
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = true
        XCTAssertEqual(sut.selectButtonOpacity, 0.0, accuracy: 0.1)
        
        sut.photoLibraryContentViewModel.selection.isHidden = false
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
    }
    
    @MainActor
    func testSelectButtonOpacity_onViewModeChange_shouldOnlyShowTheButtonInTheAllPhotosView() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase)
        await sut.loadPublicAlbum()
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
        
        for viewMode in [PhotoLibraryViewMode.year, .month, .day] {
            sut.photoLibraryContentViewModel.selectedMode = viewMode
            XCTAssertEqual(sut.selectButtonOpacity, 0.0, accuracy: 0.1,
                           "Selection is not available in the \(viewMode) view")
        }
        
        sut.photoLibraryContentViewModel.selectedMode = .all
        XCTAssertEqual(sut.selectButtonOpacity, 1.0, accuracy: 0.1)
    }
    
    @MainActor
    func testSelectButtonOpacity_noPhotos_shouldUseCorrectOpacity() async throws {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 2))
        let publicAlbumUseCase = MockPublicCollectionUseCase(
            publicAlbumResult: .success(sharedAlbumEntity))
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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
        
        XCTAssertEqual(sut.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(albumName)))
    }
    
    @MainActor
    func testImportFolderLocation_onFolderSelectedAndImportFails_shouldShowErrorInSnackbar() async throws {
        let albumName = "New Album (1)"
        let album = makeSharedAlbumEntity(set: SetEntity(handle: 24, name: albumName))
        let publicAlbumUseCase = MockPublicCollectionUseCase(publicAlbumResult: .success(album),
                                                        nodes: try makePhotos())
        let importPublicAlbumUseCase = MockImportPublicAlbumUseCase(
            importAlbumResult: .failure(GenericErrorEntity()))
        
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertEqual(sut.snackBar,
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
                                           publicCollectionUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: importPublicAlbumUseCase)
        await sut.loadPublicAlbum()
        
        sut.photoLibraryContentViewModel.selection.editMode = .active
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(selectedPhotos)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertEqual(Set(importPublicAlbumUseCase.photosToImport ?? []),
                       Set(selectedPhotos))
        XCTAssertEqual(sut.snackBar,
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
    func testImportAlbum_userNotLoggedIn_shouldShowOnboardingInsteadOfTheDestinationPicker() async throws {
        let onboardingRouter = MockAlbumLinkImportOnboardingRouter()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           accountUseCase: MockAccountUseCase(isLoggedIn: false),
                                           onboardingRouter: onboardingRouter)

        await sut.importAlbum()

        XCTAssertEqual(onboardingRouter.showOnboardingCalled, 1)
        XCTAssertFalse(sut.showImportAlbumLocation)
    }

    @MainActor
    func testImportAlbum_userLoggedIn_shouldNotShowOnboarding() async throws {
        let onboardingRouter = MockAlbumLinkImportOnboardingRouter()
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 3, name: "valid album name")
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase,
                                           accountUseCase: MockAccountUseCase(isLoggedIn: true),
                                           onboardingRouter: onboardingRouter)
        await sut.loadPublicAlbum()

        await sut.importAlbum()

        XCTAssertEqual(onboardingRouter.showOnboardingCalled, 0)
        XCTAssertTrue(sut.showImportAlbumLocation)
    }

    @MainActor
    func testShowsAnchoredButtons_linkRevampEnabled_shouldOnlyShowOutsideSelection() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        XCTAssertTrue(sut.showsAnchoredButtons)

        sut.photoLibraryContentViewModel.selection.editMode = .active

        XCTAssertFalse(sut.showsAnchoredButtons)
    }

    @MainActor
    func testShowsAnchoredButtons_linkRevampDisabled_shouldKeepTheBottomToolbar() throws {
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: false]))

        XCTAssertFalse(sut.showsAnchoredButtons)
    }

    @MainActor
    func testRenameAlbum_newNameProvided_shouldShowImportAlbumLocationAndUseNewNameDuringImport() async throws {
        let newAlbumName = "The new album name"
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: "Test", nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase,
                                           importPublicAlbumUseCase: MockImportPublicAlbumUseCase(
                                            importAlbumResult: .success))
        await sut.loadPublicAlbum()
        
        sut.renameAlbum(newName: newAlbumName)
        XCTAssertTrue(sut.showImportAlbumLocation)
        
        sut.importFolderLocation = NodeEntity(handle: 64, isFolder: true)
        await sut.importAlbumTask?.value
        
        XCTAssertEqual(sut.snackBar,
                       SnackBar(message: Strings.Localizable.AlbumLink.Alert.Message.albumSavedToCloudDrive(newAlbumName)))
    }
    
    @MainActor
    func testReservedAlbumNames_onImportAlbumLoad_shouldContainUserAlbumNames() async throws {
        let userAlbumNames = ["Album 1", "Album 2"]
        let albumNameUseCase = MockAlbumNameUseCase(userAlbumNames: userAlbumNames)
        let publicAlbumUseCase = makePublicAlbumUseCase(handle: 24, name: "Test", nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase,
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
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase)
        XCTAssertFalse(sut.shouldShowEmptyAlbumView)
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.shouldShowEmptyAlbumView)
        XCTAssertTrue(sut.isAlbumEmpty)
    }
    
    @MainActor
    func testsShouldShowEmptyAlbumView_photosLoaded_shouldReturnFalse() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase(nodes: try makePhotos())
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase)
        
        await sut.loadPublicAlbum()
        
        XCTAssertFalse(sut.shouldShowEmptyAlbumView)
        XCTAssertFalse(sut.isAlbumEmpty)
    }
    
    @MainActor
    func testIsShareLinkButtonDisabled_onAlbumLoaded_shouldEnableShareButtonEvenIfNoPhotosLoaded() async throws {
        let publicAlbumUseCase = makePublicAlbumUseCase()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase)
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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

        XCTAssertEqual(sut.snackBar,
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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
        XCTAssertEqual(sut.snackBar,
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
                                           publicCollectionUseCase: publicAlbumUseCase,
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
        XCTAssertNil(sut.snackBar)
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
    func testExportPhotos_whenSelectionModeIsActive_shouldExportSelectedItems() async throws {
        let exportRouter = MockAlbumLinkExportRouter()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: makePublicAlbumUseCase(nodes: try makePhotos()),
                                           exportRouter: exportRouter)
        await sut.loadPublicAlbum()
        
        let selectedPhotos = try Array(makePhotos().prefix(2))
        sut.enablePhotoLibraryEditMode(true)
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos(selectedPhotos)
        
        await sut.exportPhotos()
        
        XCTAssertEqual(exportRouter.exportedPhotos.map { Set($0) }, [Set(selectedPhotos)])
    }
    
    @MainActor
    func testExportPhotos_whenSelectionModeNotActive_shouldExportAllItemsInAlbum() async throws {
        let photos = try makePhotos()
        let exportRouter = MockAlbumLinkExportRouter()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: makePublicAlbumUseCase(nodes: photos),
                                           exportRouter: exportRouter)
        await sut.loadPublicAlbum()
        
        await sut.exportPhotos()
        
        XCTAssertEqual(exportRouter.exportedPhotos.map { Set($0) }, [Set(photos)])
    }
    
    @MainActor
    func testExportPhotos_emptyAlbum_shouldNotStartAnExport() async throws {
        let exportRouter = MockAlbumLinkExportRouter()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           exportRouter: exportRouter)
        await sut.loadPublicAlbum()
        
        await sut.exportPhotos()
        
        XCTAssertTrue(exportRouter.exportedPhotos.isEmpty)
    }
    
    @MainActor
    func testExportPhotos_noInterNetConnection_shouldToggleNoInternetConnectionAndNotExport() async throws {
        let exportRouter = MockAlbumLinkExportRouter()
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: MockNetworkMonitorUseCase(connected: false),
                                           exportRouter: exportRouter)
        XCTAssertFalse(sut.showNoInternetConnection)
        
        await sut.exportPhotos()
        
        XCTAssertTrue(sut.showNoInternetConnection)
        XCTAssertTrue(exportRouter.exportedPhotos.isEmpty)
    }
    
    @MainActor
    func testStopAlbumLinkPreview_deinit_shouldBeCalled() async throws {
        let publicAlbumUseCase = MockPublicCollectionUseCase()
        var sut: ImportAlbumViewModel? = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                                                  publicCollectionUseCase: publicAlbumUseCase)
        await sut?.loadPublicAlbum()
        
        sut = nil
        
        XCTAssertEqual(publicAlbumUseCase.stopCollectionLinkPreviewCalled, 1)
    }
    
    @MainActor
    func testMonitorNetworkConnection_onConnectionChanges_updatesCorrectly() throws {
        var results = [false, true, false, true]
        let connectionStream = makeConnectionMonitorStream(statuses: results)
        let monitorUseCase = MockNetworkMonitorUseCase(connectionSequence: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink {
                XCTAssertEqual($0, results.removeFirst())
            }
            .store(in: &subscriptions)
        
        sut.monitorNetworkConnection()
    }
    
    @MainActor
    func testMonitorNetworkConnection_onAlbumLoaded_shouldNotUpdateConnection() async throws {
        let connectionStream = makeConnectionMonitorStream(statuses: [false, true, false])
        let monitorUseCase = MockNetworkMonitorUseCase(connectionSequence: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink { _ in
                XCTFail("Should not have updated")
            }
            .store(in: &subscriptions)
        
        await sut.loadPublicAlbum()
        sut.monitorNetworkConnection()
    }
    
    @MainActor
    func testMonitorNetworkConnection_onAlbumInvalidAlbum_shouldNotUpdateConnection() async throws {
        let connectionStream = makeConnectionMonitorStream(statuses: [false, true, false])
        let publicAlbumUseCase = MockPublicCollectionUseCase(publicAlbumResult: .failure(GenericErrorEntity()))
        let monitorUseCase = MockNetworkMonitorUseCase(connectionSequence: connectionStream)
        let sut = makeImportAlbumViewModel(publicLink: try validFullAlbumLink,
                                           publicCollectionUseCase: publicAlbumUseCase,
                                           monitorUseCase: monitorUseCase)
        
        sut.$isConnectedToNetworkUntilContentLoaded
            .dropFirst()
            .sink { _ in
                XCTFail("Should not have updated")
            }
            .store(in: &subscriptions)
        
        await sut.loadPublicAlbum()
        sut.monitorNetworkConnection()
    }
    
    // MARK: - Private
    
    // MARK: - Link revamp
    
    @MainActor
    func testDecryptionKeyAlertCopy_onLinkRevampEnabled_shouldUseTheSharedRevampedCopy() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        XCTAssertEqual(sut.decryptionKeyAlertMessage, Strings.Localizable.Link.DecryptionKey.Alert.message)
        XCTAssertEqual(sut.decryptionKeyAlertPlaceholder, Strings.Localizable.decryptionKey)
    }
    
    @MainActor
    func testDecryptionKeyAlertCopy_onLinkRevampDisabled_shouldUseTheLegacyCopy() throws {
        let sut = makeImportAlbumViewModel(publicLink: try requireDecryptionKeyAlbumLink)
        
        XCTAssertEqual(sut.decryptionKeyAlertMessage, Strings.Localizable.decryptionKeyAlertMessageForAlbum)
        XCTAssertEqual(sut.decryptionKeyAlertPlaceholder, "")
    }
    
    @MainActor
    func testLoadPublicAlbum_onLinkRevampEnabledAndSharedAlbumError_shouldShowUnavailablePageInsteadOfAlert() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .failure(SharedCollectionErrorEntity.couldNotBeReadOrDecrypted)),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.publicLinkStatus, .invalid)
        XCTAssertTrue(sut.shouldShowLinkUnavailable)
        XCTAssertFalse(sut.showCannotAccessAlbumAlert)
        XCTAssertFalse(sut.showInvalidDecryptionKeyAlert)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_onLinkRevampEnabledAndKeyNotAccepted_shouldNotifyInvalidDecryptionKey() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .failure(SharedCollectionErrorEntity.malformed)),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "invalid-key"
        
        await sut.loadWithNewDecryptionKey()
        
        XCTAssertTrue(sut.showInvalidDecryptionKeyAlert)
        XCTAssertFalse(sut.shouldShowLinkUnavailable)
        XCTAssertNotEqual(sut.publicLinkStatus, .invalid)
        XCTAssertEqual(sut.publicLinkDecryptionKey, "")
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_onLinkRevampEnabledAndAlbumNotFound_shouldShowUnavailablePage() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .failure(SharedCollectionErrorEntity.resourceNotFound)),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "Nt8-bopPB8em4cOlKas"
        
        await sut.loadWithNewDecryptionKey()
        
        XCTAssertTrue(sut.shouldShowLinkUnavailable)
        XCTAssertFalse(sut.showInvalidDecryptionKeyAlert)
    }
    
    @MainActor
    func testLoadWithNewDecryptionKey_onLinkRevampDisabledAndKeyNotAccepted_shouldSetStatusToInvalid() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .failure(SharedCollectionErrorEntity.malformed)))
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "invalid-key"
        
        await sut.loadWithNewDecryptionKey()
        
        XCTAssertEqual(sut.publicLinkStatus, .invalid)
        XCTAssertTrue(sut.showCannotAccessAlbumAlert)
        XCTAssertFalse(sut.showInvalidDecryptionKeyAlert)
    }
    
    @MainActor
    func testAcknowledgeInvalidDecryptionKey_onLinkRevampEnabled_shouldAskForTheKeyAgain() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try requireDecryptionKeyAlbumLink,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .failure(SharedCollectionErrorEntity.malformed)),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = "invalid-key"
        await sut.loadWithNewDecryptionKey()
        
        sut.acknowledgeInvalidDecryptionKey()
        
        XCTAssertEqual(sut.publicLinkStatus, .requireDecryptionKey)
        XCTAssertTrue(sut.showingDecryptionKeyAlert)
    }
    
    @MainActor
    func testGlobalHeaderType_linkRevampEnabled_shouldBeSortAndZoomHeader() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        guard case .sortAndZoom = sut.photoLibraryContentViewModel.globalHeaderType else {
            XCTFail("Expected the sort and zoom global header, got \(sut.photoLibraryContentViewModel.globalHeaderType)")
            return
        }
    }
    
    @MainActor
    func testGlobalHeaderType_linkRevampDisabled_shouldKeepDateAndZoomHeader() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: false]))
        
        XCTAssertEqual(sut.photoLibraryContentViewModel.globalHeaderType, .dateAndZoom)
    }
    
    @MainActor
    func testUpdateSortOrder_onOldestFirst_shouldRemapLoadedPhotos() async throws {
        let photos = try makePhotosWithDistinctModificationTimes()
        let albumUseCase = MockPublicCollectionUseCase(
            publicAlbumResult: .success(makeSharedAlbumEntity(set: SetEntity(handle: 2, name: "Lisbon"))),
            nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: albumUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        await sut.loadPublicAlbum()
        
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .modificationDesc))
        
        sut.updateSortOrder(.modificationAsc)
        
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .modificationAsc))
    }
    
    @MainActor
    func testUpdateSortOrder_onUnchangedSortOrder_shouldLeaveLibraryUntouched() async throws {
        let photos = try makePhotosWithDistinctModificationTimes()
        let albumUseCase = MockPublicCollectionUseCase(
            publicAlbumResult: .success(makeSharedAlbumEntity(set: SetEntity(handle: 2, name: "Lisbon"))),
            nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: albumUseCase,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        await sut.loadPublicAlbum()
        
        // Watched for a new emission rather than compared by value: re-mapping the same sort order
        // produces an equal library, so only the absence of an emission shows the call was turned away.
        let exp = expectation(description: "Should not re-map the library")
        exp.isInverted = true
        sut.photoLibraryContentViewModel.$library
            .dropFirst()
            .sink { _ in
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.updateSortOrder(.modificationDesc)
        
        await fulfillment(of: [exp], timeout: 0.25)
        XCTAssertEqual(sut.photoLibraryContentViewModel.library,
                       photos.toPhotoLibrary(withSortType: .modificationDesc))
    }
    
    @MainActor
    func testShareableLink_onKeyTypedIn_shouldCarryTheDecryptionKey() async throws {
        let link = try requireDecryptionKeyAlbumLink
        let key = "Nt8-bopPB8em4cOlKas"
        let sut = makeImportAlbumViewModel(
            publicLink: link,
            publicCollectionUseCase: MockPublicCollectionUseCase(
                publicAlbumResult: .success(makeSharedAlbumEntity(set: SetEntity(handle: 5)))))
        
        XCTAssertEqual(sut.shareableLink, link)
        
        sut.publicLinkStatus = .requireDecryptionKey
        sut.publicLinkDecryptionKey = key
        await sut.loadWithNewDecryptionKey()
        
        // Sharing the link the screen was opened with would hand the recipient one they cannot open.
        XCTAssertEqual(sut.shareableLink, try XCTUnwrap(URL(string: link.absoluteString + "#" + key)))
    }
    
    @MainActor
    func testShouldShowMoreOptionsButton_onLinkRevampFlag_shouldFollowIt() throws {
        for isEnabled in [true, false] {
            let sut = makeImportAlbumViewModel(
                publicLink: try validFullAlbumLink,
                featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: isEnabled]))
            
            XCTAssertEqual(sut.shouldShowMoreOptionsButton, isEnabled)
        }
    }
    
    /// Save to MEGA is deliberately absent: the anchored button carries it wherever the sheet can be
    /// opened, so the rows no longer depend on whether there is a session.
    @MainActor
    func testMoreOptions_whetherLoggedInOrOut_shouldOfferSelectAndShareLink() throws {
        for isLoggedIn in [true, false] {
            let sut = makeImportAlbumViewModel(
                publicLink: try validFullAlbumLink,
                accountUseCase: MockAccountUseCase(isLoggedIn: isLoggedIn),
                featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
            
            XCTAssertEqual(sut.moreOptions, [.select, .shareLink], "logged in: \(isLoggedIn)")
        }
    }
    
    @MainActor
    func testDisabledMoreOptions_beforeTheAlbumLoads_shouldDisableEveryRow() throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        XCTAssertEqual(sut.disabledMoreOptions, [.select, .shareLink])
        XCTAssertTrue(sut.isMoreOptionsButtonDisabled)
    }
    
    @MainActor
    func testDisabledMoreOptions_onLoadedAlbumWithPhotos_shouldEnableEveryRow() async throws {
        let photos = try makePhotos()
        let albumUseCase = MockPublicCollectionUseCase(
            publicAlbumResult: .success(makeSharedAlbumEntity(set: SetEntity(handle: 2, name: "Lisbon"))),
            nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: albumUseCase,
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        await sut.loadPublicAlbum()
        
        XCTAssertTrue(sut.disabledMoreOptions.isEmpty)
        XCTAssertFalse(sut.isMoreOptionsButtonDisabled)
    }
    
    @MainActor
    func testDisabledMoreOptions_outsideTheAllPhotosView_shouldDisableOnlySelect() async throws {
        let photos = try makePhotos()
        let albumUseCase = MockPublicCollectionUseCase(
            publicAlbumResult: .success(makeSharedAlbumEntity(set: SetEntity(handle: 2, name: "Lisbon"))),
            nodes: photos)
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            publicCollectionUseCase: albumUseCase,
            accountUseCase: MockAccountUseCase(isLoggedIn: true),
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        await sut.loadPublicAlbum()
        
        for viewMode in [PhotoLibraryViewMode.year, .month, .day] {
            sut.photoLibraryContentViewModel.selectedMode = viewMode
            XCTAssertEqual(sut.disabledMoreOptions, [.select],
                           "Selection is not available in the \(viewMode) view")
        }
        
        sut.photoLibraryContentViewModel.selectedMode = .all
        XCTAssertTrue(sut.disabledMoreOptions.isEmpty)
    }
    
    @MainActor
    func testHandleMoreOption_onSelect_shouldEnterSelectionMode() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        sut.handle(moreOption: .select)
        
        XCTAssertTrue(sut.photoLibraryContentViewModel.selection.editMode.isEditing)
    }
    
    @MainActor
    func testHandleMoreOption_onShareLink_shouldLeaveTheSharingToTheSheet() async throws {
        let sut = makeImportAlbumViewModel(
            publicLink: try validFullAlbumLink,
            featureFlagProvider: MockFeatureFlagProvider(list: [.linkRevamp: true]))
        
        sut.handle(moreOption: .shareLink)
        
        XCTAssertFalse(sut.showShareLink)
    }
    
    @MainActor
    private func makeImportAlbumViewModel(
        publicLink: URL,
        publicCollectionUseCase: some PublicCollectionUseCaseProtocol = MockPublicCollectionUseCase(),
        albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
        accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
        importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol = MockImportPublicAlbumUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
        transferWidgetResponder: some TransferWidgetResponderProtocol = MockTransferWidgetResponder(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        tracker: some AnalyticsTracking = MockTracker(),
        monitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        appDelegateRouter: some AppDelegateRouting = MockAppDelegateRouter(),
        thumbnailLoader: any ThumbnailLoaderProtocol = MockThumbnailLoader(),
        exportRouter: some AlbumLinkExportRouting = MockAlbumLinkExportRouter(),
        onboardingRouter: some AlbumLinkImportOnboardingRouting = MockAlbumLinkImportOnboardingRouter(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> ImportAlbumViewModel {
        let sut = ImportAlbumViewModel(
            publicLink: publicLink,
            publicCollectionUseCase: publicCollectionUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase,
            importPublicAlbumUseCase: importPublicAlbumUseCase,
            accountUseCase: accountUseCase,
            saveMediaUseCase: saveMediaUseCase,
            transferWidgetResponder: transferWidgetResponder,
            permissionHandler: permissionHandler,
            tracker: tracker,
            monitorUseCase: monitorUseCase,
            appDelegateRouter: appDelegateRouter,
            thumbnailLoader: thumbnailLoader,
            exportRouter: exportRouter,
            onboardingRouter: onboardingRouter,
            featureFlagProvider: featureFlagProvider)
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
    
    private func makePhotosWithDistinctModificationTimes() throws -> [NodeEntity] {
        [NodeEntity(name: "test_image_1.png", handle: 1, hasThumbnail: true,
                    modificationTime: try "2023-01-01T22:05:04Z".date, mediaType: .image),
         NodeEntity(name: "test_video_1.mp4", handle: 4, hasThumbnail: true,
                    modificationTime: try "2023-02-14T10:00:00Z".date, mediaType: .video),
         NodeEntity(name: "test_image_4.jpg", handle: 7, hasThumbnail: true,
                    modificationTime: try "2023-03-30T08:30:00Z".date, mediaType: .image)
        ]
    }
    
    private func makePublicAlbumUseCase(handle: HandleEntity = 1, name: String = "valid album name", nodes: [NodeEntity] = []) -> some PublicCollectionUseCaseProtocol {
        let sharedAlbumEntity = makeSharedAlbumEntity(set: SetEntity(handle: 1, name: name))
        return MockPublicCollectionUseCase(publicAlbumResult: .success(sharedAlbumEntity), nodes: nodes)
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

@Suite("ImportAlbumViewModel Tests")
struct ImportAlbumViewModelTestSuite {
    @Suite("Import Photos")
    @MainActor
    struct ImportPhotos {
        @Test
        func overDiskQuota() async {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: true)
            let appDelegateRouter = MockAppDelegateRouter()
            let sut = makSUT(
                accountStorageUseCase: accountStorageUseCase,
                appDelegateRouter: appDelegateRouter)
            
            await sut.importAlbum()
            
            #expect(appDelegateRouter.showOverDiskQuotaCalled == 1)
        }
    }
    
    @Suite("Save to Photos")
    @MainActor
    struct SaveToPhotos {
        @Test
        func overDiskQuota() async {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: true)
            let appDelegateRouter = MockAppDelegateRouter()
            let sut = makSUT(
                accountStorageUseCase: accountStorageUseCase,
                appDelegateRouter: appDelegateRouter)
            
            await sut.saveToPhotos()
            
            #expect(appDelegateRouter.showOverDiskQuotaCalled == 1)
        }
    }
    
    @Suite("Export Photos")
    @MainActor
    struct ExportPhotos {
        @Test
        func overDiskQuota() async {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: true)
            let appDelegateRouter = MockAppDelegateRouter()
            let exportRouter = MockAlbumLinkExportRouter()
            let sut = makSUT(
                accountStorageUseCase: accountStorageUseCase,
                appDelegateRouter: appDelegateRouter,
                exportRouter: exportRouter)
            
            await sut.exportPhotos()
            
            #expect(appDelegateRouter.showOverDiskQuotaCalled == 1)
            #expect(exportRouter.exportedPhotos.isEmpty)
        }
    }
    
    @Suite("Share Link")
    @MainActor
    struct ShareLinkView {
        @Test
        func overDiskQuota() {
            let accountStorageUseCase = MockAccountStorageUseCase(isPaywalled: true)
            let appDelegateRouter = MockAppDelegateRouter()
            let sut = makSUT(
                accountStorageUseCase: accountStorageUseCase,
                appDelegateRouter: appDelegateRouter)
            
            sut.shareLinkTapped()
            
            #expect(appDelegateRouter.showOverDiskQuotaCalled == 1)
        }
    }
    
    @MainActor
    private static func makSUT(
        publicLink: URL = URL(string: "https://mega.app/collection/p3IBQCiZ#Nt8-bopPB8em4cOlKas")!,
        publicCollectionUseCase: some PublicCollectionUseCaseProtocol = MockPublicCollectionUseCase(),
        albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
        accountStorageUseCase: some AccountStorageUseCaseProtocol = MockAccountStorageUseCase(),
        importPublicAlbumUseCase: some ImportPublicAlbumUseCaseProtocol = MockImportPublicAlbumUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        saveMediaUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
        transferWidgetResponder: some TransferWidgetResponderProtocol = MockTransferWidgetResponder(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        tracker: some AnalyticsTracking = MockTracker(),
        monitorUseCase: some NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        appDelegateRouter: some AppDelegateRouting = MockAppDelegateRouter(),
        thumbnailLoader: any ThumbnailLoaderProtocol = MockThumbnailLoader(),
        exportRouter: some AlbumLinkExportRouting = MockAlbumLinkExportRouter(),
        onboardingRouter: some AlbumLinkImportOnboardingRouting = MockAlbumLinkImportOnboardingRouter(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> ImportAlbumViewModel {
        .init(
            publicLink: publicLink,
            publicCollectionUseCase: publicCollectionUseCase,
            albumNameUseCase: albumNameUseCase,
            accountStorageUseCase: accountStorageUseCase,
            importPublicAlbumUseCase: importPublicAlbumUseCase,
            accountUseCase: accountUseCase,
            saveMediaUseCase: saveMediaUseCase,
            transferWidgetResponder: transferWidgetResponder,
            permissionHandler: permissionHandler,
            tracker: tracker,
            monitorUseCase: monitorUseCase,
            appDelegateRouter: appDelegateRouter,
            thumbnailLoader: thumbnailLoader,
            exportRouter: exportRouter,
            onboardingRouter: onboardingRouter,
            featureFlagProvider: featureFlagProvider)
    }
}

private final class MockAlbumLinkExportRouter: AlbumLinkExportRouting {
    /// One entry per call, so a run that exported nothing is told apart from one that never started.
    private(set) var exportedPhotos: [[NodeEntity]] = []
    
    func export(photos: [NodeEntity]) async {
        exportedPhotos.append(photos)
    }
}

private final class MockAlbumLinkImportOnboardingRouter: AlbumLinkImportOnboardingRouting {
    private(set) var showOnboardingCalled = 0
    
    nonisolated init() {}
    
    func showOnboarding() {
        showOnboardingCalled += 1
    }
}
