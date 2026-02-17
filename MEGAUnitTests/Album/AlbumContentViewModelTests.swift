import Combine
import ContentLibraries
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGASwift
import MEGASwiftUI
import MEGATest
import Testing
import XCTest

final class AlbumContentViewModelTests: XCTestCase {
    private let albumEntity =
    AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    
    @MainActor
    func testIsFavouriteAlbum_isEqualToAlbumEntityType() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
    
    @MainActor
    func testDispatchChangeSortOrder_onSortOrderTheSame_shouldDoNothing() throws {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let exp = expectation(description: "should not call any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.changeSortOrder(.newest))
        wait(for: [exp], timeout: 1.0)
    }
    
    @MainActor
    func testDispatchChangeSortOrder_onSortOrderDifferent_shouldShowAlbumWithNewSortedValue() {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        let expectedSortOrder = SortOrderType.oldest
        let configuration = makeContextConfiguration(
            sortOrder: expectedSortOrder.toSortOrderEntity(),
            albumType: albumEntity.type,
            isEmptyState: true
        )
        
        test(viewModel: sut, action: .changeSortOrder(expectedSortOrder), expectedCommands: [
            .showAlbumPhotos(photos: [], sortOrder: expectedSortOrder),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchChangeFilter_onFilterTheSame_shouldDoNothing() {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let exp = expectation(description: "should not call any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.changeFilter(.allMedia))
        wait(for: [exp], timeout: 1.0)
    }
    
    @MainActor
    func testOnDispatchAddItemsToAlbum_routeToShowAlbumContentPicker() {
        let router = MockAlbumContentRouting()
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            router: router)
        
        sut.dispatch(.addToAlbumTap)
        XCTAssertEqual(router.showAlbumContentPickerCalled, 1)
    }
    
    @MainActor
    func testShowAlbumContentPicker_onCompletion_addNewItems() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let result = AlbumElementsResultEntity(success: UInt(expectedAddedPhotos.count), failure: 0)
        let albumModificationUseCase = MockAlbumModificationUseCase(addPhotosResult: .success(result))
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedAddedPhotos.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        let exp = expectation(description: "Should show completion message after items added")
        exp.expectedFulfillmentCount = 3
        sut.invokeCommand = {
            switch $0 {
            case .startLoading:
                exp.fulfill()
            case .finishLoading:
                exp.fulfill()
            case .showResultMessage(let iconTypeMessage):
                switch iconTypeMessage {
                case .success(let message):
                    XCTAssertEqual(message, "Added 1 item to “\(album.name)”")
                    exp.fulfill()
                default:
                    XCTFail("Invalid message type")
                }
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        sut.dispatch(.addToAlbumTap)
        
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(albumModificationUseCase.addedPhotosToAlbum, expectedAddedPhotos)
    }
    
    @MainActor
    func testRenameAlbum_whenUserRenameAlbum_shouldUpdateAlbumNameAndNavigationTitle() {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: photo)
        let expectedAlertViewModel = TextFieldAlertViewModel(
            textString: album.name,
            title: Strings.Localizable.rename,
            placeholderText: "",
            affirmativeButtonTitle: Strings.Localizable.rename,
            affirmativeButtonInitiallyEnabled: false,
            destructiveButtonTitle: Strings.Localizable.cancel,
            highlightInitialText: true,
            message: Strings.Localizable.renameNodeMessage,
            action: nil,
            validator: nil)
        
        let expectedName = "New Album"
        let sut = makeAlbumContentViewModel(
            album: album,
            albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
            albumNameUseCase: MockAlbumNameUseCase(userAlbumNames: ["User Album"]),
            router: albumContentRouter)
        
        let exp = expectation(description: "Should update navigation title")
        sut.invokeCommand = {
            switch $0 {
            case .showRenameAlbumAlert(let viewModel):
                XCTAssertEqual(viewModel, expectedAlertViewModel)
                viewModel.action?(expectedName)
            case .updateNavigationTitle:
                exp.fulfill()
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        
        sut.dispatch(.renameAlbum)
        
        wait(for: [exp], timeout: 1)
    }
    
    @MainActor
    func testShowAlbumCoverPicker_onChangingNewCoverPic_shouldChangeTheCoverPic() {
        let photos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: nil, count: 2, type: .user)
        
        let albumContentRouter = MockAlbumContentRouting(album: album, albumPhoto: AlbumPhotoEntity(photo: NodeEntity(handle: HandleEntity(1))), photos: photos)
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: photos.map {AlbumPhotoEntity(photo: $0)}),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        test(viewModel: sut, action: .showAlbumCoverPicker,
             expectedCommands: [.showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.albumCoverUpdated))],
             timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchDeleteAlbumActionTap_onSuccessfulRemovalOfAlbum_shouldShowHudOfRemoveAlbum() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: nil, count: 1, type: .user)
        let albumModificationUseCase = MockAlbumModificationUseCase(albums: [album])
        let sut = makeAlbumContentViewModel(album: album,
                                            albumModificationUseCase: albumModificationUseCase)
        
        let message = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(1)
            .replacingOccurrences(of: "[A]", with: album.name)
        
        test(viewModel: sut, action: .deleteAlbumActionTap, expectedCommands: [
            .dismissAlbum,
            .showResultMessage(.custom(MEGAAssets.UIImage.hudMinus, message))
        ], timeout: 1.0, expectationValidation: ==)
        
        XCTAssertEqual(albumModificationUseCase.deletedAlbumsIds, [album.id])
    }
    
    @MainActor
    func testDispatchConfigureContextMenu_onReceived_shouldRebuildContextMenuWithNewSelectHiddenValue() {
        let sut = makeAlbumContentViewModel(album: albumEntity)
        
        let expectedContextConfigurationSelectHidden = true
        let configuration = makeContextConfiguration(
            albumType: albumEntity.type,
            isPhotoSelectionHidden: expectedContextConfigurationSelectHidden,
            isEmptyState: true)
        
        test(viewModel: sut, action: .configureContextMenu(isSelectHidden: expectedContextConfigurationSelectHidden),
             expectedCommands: [.configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)],
             timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchViewWillAppear_onUserAlbumPublisherEmission_shouldDismissIfSetContainsRemoveChangeType() async {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(
            album: userAlbum,
            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
        sut.dispatch(.onViewWillAppear)
        await sut.setupSubscriptionTask?.value
        
        let action = {
            albumUpdatedPublisher.send(SetEntity(handle: userAlbum.id, changeTypes: .removed))
        }
        await test(viewModel: sut, trigger: action, expectedCommands: [.dismissAlbum], timeout: 0.25, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchViewWillAppear_onUserAlbumPublisherEmission_shouldUpdateNavigationTitleNameIfItContainsNameChangeType() async {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(
            album: userAlbum,
            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
        sut.dispatch(.onViewWillAppear)
        await sut.setupSubscriptionTask?.value
        
        let expectedNewName = "The new name"
        let exp = expectation(description: "album name should update")
        sut.invokeCommand = {
            switch $0 {
            case .updateNavigationTitle:
                XCTAssertEqual(sut.albumName, expectedNewName)
                exp.fulfill()
            default:
                XCTFail("Unexpected command returned")
            }
        }
        albumUpdatedPublisher.send(SetEntity(handle: albumEntity.id, name: expectedNewName, changeTypes: .name))
        await fulfillment(of: [exp], timeout: 1.0)
        XCTAssertEqual(sut.albumName, expectedNewName)
    }
    
    @MainActor
    func testDispatch_onShareLink_shouldCallRouterToShareLinkAndTrackAnalyticsEvent() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let router = MockAlbumContentRouting()
        let tracker = MockTracker()
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            router: router,
                                            tracker: tracker)
        
        sut.dispatch(.shareLink)
        XCTAssertEqual(router.showShareLinkCalled, 1)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumContentShareLinkMenuToolbarEvent()
            ]
        )
    }
    
    @MainActor
    func testAction_removeLinkActionTap_shouldShowSuccessAfterRemoved() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            shareCollectionUseCase: MockShareCollectionUseCase(removeSharedCollectionLinkResult: .success))
        
        test(viewModel: sut, action: .removeLinkActionTap, expectedCommands: [
            .showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1)))
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchViewWillAppear_onUserAlbumPublisherEmission_shouldUpdateContextMenuIfAlbumContainsExportedChangeType() async {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(
            album: userAlbum,
            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
        sut.dispatch(.onViewWillAppear)
        await sut.setupSubscriptionTask?.value
        
        let isExported = true
        let action = {
            albumUpdatedPublisher.send(SetEntity(handle: userAlbum.id, isExported: isExported, changeTypes: .exported))
        }
        let configuration = makeContextConfiguration(
            albumType: userAlbum.type,
            isEmptyState: true,
            sharedLinkStatus: .exported(isExported)
        )
        await test(viewModel: sut, trigger: action, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 0.25, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchHideNodes_shouldTrackActionEvent() {
        let tracker = MockTracker()
        let sut = makeAlbumContentViewModel(
            album: albumEntity,
            tracker: tracker)
        
        test(viewModel: sut, action: .hideNodes, expectedCommands: [],
             timeout: 1.0, expectationValidation: ==)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumContentHideNodeMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func testDispatchViewAppear_monitorAlbumPhotosYieldPhotos_shouldUpdatePhotos() async {
        let photoNodes = [
            NodeEntity(handle: 65),
            NodeEntity(handle: 89)
        ]
        let albumPhotos = photoNodes.toAlbumPhotoEntities()
        let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
            item: Result<[AlbumPhotoEntity], any Error>.success(albumPhotos))
        let monitorAlbumPhotosUseCase = MockMonitorAlbumPhotosUseCase(
            monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
        let sut = makeAlbumContentViewModel(
            album: albumEntity,
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase)
        
        let configuration = makeContextConfiguration(albumType: albumEntity.type)
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: photoNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false),
            .showEmptyView(isEmpty: false, isRevampEnabled: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchViewAppear_monitorAlbumPhotosYieldEmpty_shouldDismiss() async {
        let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
            item: Result<[AlbumPhotoEntity], any Error>.success([]))
        let monitorAlbumPhotosUseCase = MockMonitorAlbumPhotosUseCase(
            monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
        let sut = makeAlbumContentViewModel(
            album: albumEntity,
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase)
        
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .dismissAlbum
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testDispatchViewAppear_monitorAlbumPhotosYieldEmptyPhotoLibrayContainsPhotos_shouldShowAddToAlbum() async {
        let album = AlbumEntity(id: 1, type: .user)
        let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
            item: Result<[AlbumPhotoEntity], any Error>.success([]))
        let monitorAlbumPhotosUseCase = MockMonitorAlbumPhotosUseCase(
            monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
        let photoLibraryUseCase = MockPhotoLibraryUseCase(
            allPhotos: [NodeEntity(name: "photo 1.jpg", handle: 1)])
        let sut = makeAlbumContentViewModel(
            album: album,
            photoLibraryUseCase: photoLibraryUseCase,
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase)
        
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true
        )
        
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true),
            .showEmptyView(isEmpty: true, isRevampEnabled: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeAlbumContentViewModel(
        album: AlbumEntity,
        albumContentsUseCase: some AlbumContentsUseCaseProtocol = MockAlbumContentUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        monitorAlbumPhotosUseCase: some MonitorAlbumPhotosUseCaseProtocol = MockMonitorAlbumPhotosUseCase(),
        albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
        router: some AlbumContentRouting = MockAlbumContentRouting(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        tracker: some AnalyticsTracking = MockTracker(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> AlbumContentViewModel {
        AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            albumModificationUseCase: albumModificationUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            shareCollectionUseCase: shareCollectionUseCase,
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
            albumNameUseCase: albumNameUseCase,
            router: router,
            overDiskQuotaChecker: overDiskQuotaChecker,
            newAlbumPhotosToAdd: newAlbumPhotosToAdd,
            tracker: tracker,
            albumCoverUseCase: albumCoverUseCase,
            thumbnailLoader: thumbnailLoader,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            featureFlagProvider: featureFlagProvider)
    }
    
    @MainActor
    private func makeAlertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                affirmativeButtonTitle: Strings.Localizable.rename, destructiveButtonTitle: Strings.Localizable.cancel, message: nil)
    }
    
    private func makeContextConfiguration(
        sortOrder: SortOrderEntity = .modificationDesc,
        filter: FilterEntity = .allMedia,
        albumType: AlbumEntityType = .user,
        isFilterEnabled: Bool = false,
        isPhotoSelectionHidden: Bool = false,
        isEmptyState: Bool = false,
        sharedLinkStatus: SharedLinkStatusEntity = .unavailable
    ) -> CMConfigEntity {
        CMConfigEntity(
            menuType: .menu(type: .album),
            sortType: sortOrder,
            filterType: filter,
            albumType: albumType,
            isFilterEnabled: isFilterEnabled,
            isSelectHidden: isPhotoSelectionHidden,
            isEmptyState: isEmptyState,
            sharedLinkStatus: sharedLinkStatus
        )
    }
    
    private func makeMockMonitorAlbumPhotosUseCase(for photos: [NodeEntity]) -> some MonitorAlbumPhotosUseCaseProtocol {
        let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
            item: Result<[AlbumPhotoEntity], any Error>.success(photos.toAlbumPhotoEntities()))
        return MockMonitorAlbumPhotosUseCase(
            monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
    }
}

@Suite("AlbumContentViewModel Tests")
struct AlbumContentViewModelTestSuite {
    @Suite("Over Disk Quota")
    @MainActor
    struct OverDiskQuota {
        @Test("when account is not paywalled it should call correct command",
              arguments: [
                (true, 0, AlbumContentAction.removeLink, AlbumContentViewModel.Command.showRemoveLinkAlert),
                (false, 1, .removeLink, .showRemoveLinkAlert),
                (true, 0, .deleteAlbum, .showDeleteAlbumAlert),
                (false, 1, .deleteAlbum, .showDeleteAlbumAlert)]
        )
        func paywalled(
            isPaywalled: Bool,
            expectedCount: Int,
            action: AlbumContentAction,
            expectedCommand: AlbumContentViewModel.Command
        ) async throws {
            let sut = makeSUT(
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: isPaywalled))
            
            try await confirmation(expectedCount: expectedCount) { confirmation in
                sut.invokeCommand = { command in
                    #expect(command == expectedCommand)
                    confirmation()
                }
                
                sut.dispatch(action)
                
                try await waitForCommand()
            }
        }
        
        @Test("when paywalled it should invoke correct command",
              arguments: [
                (true, AlbumContentAction.downloadButtonTap, AlbumContentViewModel.Command.endEditingMode),
                (false, .downloadButtonTap, .downloadSelectedItems),
                (true, .sharePhotoLinksTap, .endEditingMode),
                (false, .sharePhotoLinksTap, .showSharePhotoLinks),
                (true, .deletePhotosTap, .endEditingMode),
                (false, .deletePhotosTap, .deletePhotos)]
        )
        func overDiskQuota(
            isPaywalled: Bool,
            action: AlbumContentAction,
            expectedCommand: AlbumContentViewModel.Command
        ) async throws {
            let sut = makeSUT(
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: isPaywalled))
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    #expect(command == expectedCommand)
                    confirmation()
                }
                
                sut.dispatch(action)
                
                try await waitForCommand()
            }
        }
    }
    
    @Suite("Share link")
    @MainActor
    struct ShareLink {
        @Test("when paywalled it should not show the alert",
              arguments: [(true, 0), (false, 1)])
        func overDiskQuota(isPaywalled: Bool, expectedCount: Int) {
            let albumContentRouter = MockAlbumContentRouting()
            let sut = makeSUT(
                router: albumContentRouter,
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: isPaywalled))
            
            sut.dispatch(.shareLink)
            
            #expect(albumContentRouter.showShareLinkCalled  == expectedCount)
        }
    }
    
    @Suite("Album Cover")
    @MainActor
    struct AlbumCover {
        @Test("when paywalled it should not show the alert",
              arguments: [(true, 0), (false, 1)])
        func overDiskQuota(isPaywalled: Bool, expectedCount: Int) {
            let albumContentRouter = MockAlbumContentRouting()
            let sut = makeSUT(
                router: albumContentRouter,
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: isPaywalled))
            
            sut.dispatch(.showAlbumCoverPicker)
            
            #expect(albumContentRouter.showAlbumCoverPickerCalled  == expectedCount)
        }
    }
    
    @Suite("Rename Album")
    @MainActor
    struct RenameAlbum {
        @Test(
            "when paywalled it should not show the alert",
            .disabled("Disabled due to flakiness"),
            arguments: [(true, 0), (false, 1)]
        )
        func overDiskQuota(isPaywalled: Bool, expectedCount: Int) async throws {
            let album = AlbumEntity(id: 1, name: "Test", type: .user)
            let albumContentRouter = MockAlbumContentRouting()
            let sut = makeSUT(
                album: album,
                router: albumContentRouter,
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: isPaywalled))
            
            let expectedAlertViewModel = TextFieldAlertViewModel(
                textString: album.name,
                title: Strings.Localizable.rename,
                placeholderText: "",
                affirmativeButtonTitle: Strings.Localizable.rename,
                affirmativeButtonInitiallyEnabled: false,
                destructiveButtonTitle: Strings.Localizable.cancel,
                highlightInitialText: true,
                message: Strings.Localizable.renameNodeMessage,
                action: nil,
                validator: nil)
            try await confirmation(expectedCount: expectedCount) { confirmation in
                sut.invokeCommand = { command in
                    #expect(command == .showRenameAlbumAlert(viewModel: expectedAlertViewModel))
                    confirmation()
                }
                
                sut.dispatch(.renameAlbum)
                
                try await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
    
    @Suite("Export Files")
    @MainActor
    struct ExportFiles {
        @Test
        func exportFile() async throws {
            let button = UIButton()
            let sut = makeSUT(
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: false))
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    #expect(command == .exportFiles(sender: button))
                    confirmation()
                }
                
                sut.dispatch(.exportFilesTap(sender: button))
                
                try await waitForCommand()
            }
        }
        
        func paywalled() async throws {
            let sut = makeSUT(
                overDiskQuotaChecker: MockOverDiskQuotaChecker(isPaywalled: true))
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    #expect(command == .endEditingMode)
                    confirmation()
                }
                
                sut.dispatch(.exportFilesTap(sender: UIButton()))
                
                try await waitForCommand()
            }
        }
    }
    
    @MainActor
    struct FloatingAddButton {
        @Test(arguments: [
            (AlbumEntityType.favourite, false, false),
            (.favourite, true, false),
            (.user, false, true),
            (.user, true, false)
        ])
        func onViewReady(
            type: AlbumEntityType,
            isMediaRevampEnabled: Bool,
            addBarButton: Bool
        ) async throws {
            let sut = makeSUT(
                album: .init(id: 8, type: type),
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosMediaRevamp: isMediaRevampEnabled]))
            
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    switch command {
                    case .configureRightBarButtons(_, let canAdd):
                        #expect(canAdd == addBarButton)
                        confirmation()
                    default: break
                    }
                }
                
                sut.dispatch(.onViewReady)
                
                try await waitForCommand()
            }
        }
        
        @Test(arguments: [
            (AlbumEntityType.favourite, false),
            (.user, true)
        ])
        func onViewWillAppear(
            type: AlbumEntityType,
            isAddFloatingActionBarButtonVisible: Bool
        ) async throws {
            let photoNodes = [
                NodeEntity(handle: 65),
                NodeEntity(handle: 89)
            ]
            let albumPhotos = photoNodes.toAlbumPhotoEntities()
            let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
                item: Result<[AlbumPhotoEntity], any Error>.success(albumPhotos))
            let photoLibraryUseCase = MockPhotoLibraryUseCase(
                allPhotos: [NodeEntity(name: "photo 1.jpg", handle: 1)])
            let monitorAlbumPhotosUseCase = MockMonitorAlbumPhotosUseCase(
                monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
            let sut = makeSUT(
                album: .init(id: 8, type: type),
                photoLibraryUseCase: photoLibraryUseCase,
                monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosMediaRevamp: true]))
            
            try await confirmation(expectedCount: 2) { confirmation in
                sut.invokeCommand = { command in
                    switch command {
                    case .configureRightBarButtons(_, let canAdd):
                        #expect(canAdd == false)
                        confirmation()
                        
                    case .updateAddToAlbumButton(let isVisible):
                        #expect(isVisible == isAddFloatingActionBarButtonVisible)
                        confirmation()
                    default: break
                    }
                }
                
                sut.dispatch(.onViewWillAppear)
                await sut.setupSubscriptionTask?.value
                
                try await waitForCommand()
            }
        }
        
        @Test(arguments: [
            (AlbumEntityType.favourite, false, false, false),
            (AlbumEntityType.user, false, false, true),
            (AlbumEntityType.favourite, false, true, false),
            (AlbumEntityType.user, false, true, false),
            // Editing
            (AlbumEntityType.favourite, true, false, false),
            (AlbumEntityType.user, true, false, false)
        ])
        func onEditModeChange(
            type: AlbumEntityType,
            isEditing: Bool,
            isPhotosEmpty: Bool,
            isAddFloatingActionBarButtonVisible: Bool
        ) async throws {
            let photoNodes = [
                NodeEntity(handle: 65),
                NodeEntity(handle: 89)
            ]
            let albumPhotos: [AlbumPhotoEntity] = isPhotosEmpty ? [] : photoNodes.toAlbumPhotoEntities()
            let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
                item: Result<[AlbumPhotoEntity], any Error>.success(albumPhotos))
            let monitorAlbumPhotosUseCase = MockMonitorAlbumPhotosUseCase(
                monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
            let sut = makeSUT(
                album: .init(id: 8, type: type),
                monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosMediaRevamp: true]))
            
            sut.dispatch(.onViewWillAppear)
            await sut.setupSubscriptionTask?.value
            
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    switch command {
                    case .updateAddToAlbumButton(let isVisible):
                        #expect(isVisible == isAddFloatingActionBarButtonVisible)
                        confirmation()
                    default: break
                    }
                }
                
                sut.dispatch(.onEditModeChange(isEditing))
                
                try await waitForCommand()
            }
        }
    }
    
    @MainActor
    struct MoreButtonTapped {
        @Test(arguments: [
            (SharedLinkStatusEntity.unavailable, true, [
                Strings.Localizable.rename,
                Strings.Localizable.delete
            ]),
            (SharedLinkStatusEntity.unavailable, false, [
                Strings.Localizable.rename,
                Strings.Localizable.select,
                Strings.Localizable.CameraUploads.Albums.selectAlbumCover,
                Strings.Localizable.delete
            ]),
            (SharedLinkStatusEntity.exported(false), true, [
                Strings.Localizable.rename,
                Strings.Localizable.General.MenuAction.ShareLink.title(1),
                Strings.Localizable.delete
            ]),
            (SharedLinkStatusEntity.exported(true), true, [
                Strings.Localizable.rename,
                Strings.Localizable.General.MenuAction.ManageLink.title(1),
                Strings.Localizable.General.MenuAction.RemoveLink.title(1),
                Strings.Localizable.delete
            ])
        ])
        func userAlbum(
            sharedLinkStatus: SharedLinkStatusEntity,
            isPhotosEmpty: Bool,
            expectedSheetTitles: [String]
        ) async throws {
            let albumName = "Test Album"
            let monitorAlbumPhotosUseCase = makeMockMonitorAlbumPhotosUseCase(isPhotosEmpty: isPhotosEmpty)
            let sut = makeSUT(
                album: .init(id: 8, name: albumName, type: .user, sharedLinkStatus: sharedLinkStatus),
                monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase)
            
            sut.dispatch(.onViewWillAppear)
            await sut.setupSubscriptionTask?.value
            
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    switch command {
                    case .showActions(let viewModel):
                        #expect(viewModel.title == albumName)
                        #expect(viewModel.sheetActions.map(\.title) == expectedSheetTitles)
                        confirmation()
                    default: break
                    }
                }
                
                sut.dispatch(.moreButtonTap)
                
                try await waitForCommand()
            }
        }
        
        @Test(arguments: [
            (false, [Strings.Localizable.select]),
            (true, [])
        ])
        func systemAlbum(
            isPhotoSelectionHidden: Bool,
            expectedSheetTitles: [String]
        ) async throws {
            let albumName = "Test Album"
            let sut = makeSUT(
                album: .init(id: 8, name: albumName, type: .favourite),
                monitorAlbumPhotosUseCase: makeMockMonitorAlbumPhotosUseCase(isPhotosEmpty: false))
            
            sut.dispatch(.onViewWillAppear)
            await sut.setupSubscriptionTask?.value
            
            sut.dispatch(.configureContextMenu(isSelectHidden: isPhotoSelectionHidden))
            await sut.updateRightBarButtonsTask?.value
            
            try await confirmation { confirmation in
                sut.invokeCommand = { command in
                    switch command {
                    case .showActions(let viewModel):
                        #expect(viewModel.title == albumName)
                        #expect(viewModel.sheetActions.map(\.title) == expectedSheetTitles)
                        confirmation()
                    default: break
                    }
                }
                
                sut.dispatch(.moreButtonTap)
                
                try await waitForCommand()
            }
        }
        
        private func makeMockMonitorAlbumPhotosUseCase(isPhotosEmpty: Bool) -> some MonitorAlbumPhotosUseCaseProtocol {
            let albumPhotos: [AlbumPhotoEntity] = isPhotosEmpty ? [] : [NodeEntity(handle: 65)].toAlbumPhotoEntities()
            let monitorPhotosAsyncSequence = SingleItemAsyncSequence(
                item: Result<[AlbumPhotoEntity], any Error>.success(albumPhotos))
            return MockMonitorAlbumPhotosUseCase(
                monitorPhotosAsyncSequence: monitorPhotosAsyncSequence.eraseToAnyAsyncSequence())
        }
    }
    
    @MainActor
    private static func makeSUT(
        album: AlbumEntity = .init(id: 1, type: .user),
        albumContentsUseCase: some AlbumContentsUseCaseProtocol = MockAlbumContentUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        monitorAlbumPhotosUseCase: some MonitorAlbumPhotosUseCaseProtocol = MockMonitorAlbumPhotosUseCase(),
        albumNameUseCase: some AlbumNameUseCaseProtocol = MockAlbumNameUseCase(),
        router: some AlbumContentRouting = MockAlbumContentRouting(),
        overDiskQuotaChecker: some OverDiskQuotaChecking = MockOverDiskQuotaChecker(),
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        tracker: some AnalyticsTracking = MockTracker(),
        albumCoverUseCase: some AlbumCoverUseCaseProtocol = MockAlbumCoverUseCase(),
        thumbnailLoader: some ThumbnailLoaderProtocol = MockThumbnailLoader(),
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> AlbumContentViewModel {
        AlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase,
            albumModificationUseCase: albumModificationUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            shareCollectionUseCase: shareCollectionUseCase,
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
            albumNameUseCase: albumNameUseCase,
            router: router,
            overDiskQuotaChecker: overDiskQuotaChecker,
            newAlbumPhotosToAdd: newAlbumPhotosToAdd,
            tracker: tracker,
            albumCoverUseCase: albumCoverUseCase,
            thumbnailLoader: thumbnailLoader,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            featureFlagProvider: featureFlagProvider)
    }
    
    private static func waitForCommand() async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
}

private extension Sequence where Element == NodeEntity {
    func toAlbumPhotoEntities() -> [AlbumPhotoEntity] {
        map {
            AlbumPhotoEntity(photo: $0)
        }
    }
}

private final class MockAlbumContentRouting: AlbumContentRouting {
    let album: AlbumEntity?
    let albumPhoto: AlbumPhotoEntity?
    let photos: [NodeEntity]
    
    var showAlbumContentPickerCalled = 0
    var showAlbumCoverPickerCalled = 0
    var albumCoverPickerPhotoCellCalled = 0
    var showShareLinkCalled = 0
    
    nonisolated init(album: AlbumEntity? = nil,
                     albumPhoto: AlbumPhotoEntity? = nil,
                     photos: [NodeEntity] = []) {
        self.album = album
        self.albumPhoto = albumPhoto
        self.photos = photos
    }
    
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        showAlbumContentPickerCalled += 1
        completion(self.album ?? album, photos)
    }
    
    func showAlbumCoverPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, AlbumPhotoEntity) -> Void) {
        showAlbumCoverPickerCalled += 1
        
        guard let albumPhoto else { return }
        
        completion(album, AlbumPhotoEntity(photo: albumPhoto.photo))
    }
    
    func albumCoverPickerPhotoCell(albumPhoto: AlbumPhotoEntity, photoSelection: AlbumCoverPickerPhotoSelection) -> AlbumCoverPickerPhotoCell {
        albumCoverPickerPhotoCellCalled += 1
        return AlbumCoverPickerPhotoCell(
            viewModel: AlbumCoverPickerPhotoCellViewModel(
                albumPhoto: albumPhoto,
                photoSelection: AlbumCoverPickerPhotoSelection(),
                viewModel: PhotoLibraryModeAllViewModel(libraryViewModel: PhotoLibraryContentViewModel(library: PhotoLibrary())),
                thumbnailLoader: MockThumbnailLoader(),
                nodeUseCase: MockNodeDataUseCase(),
                sensitiveNodeUseCase: MockSensitiveNodeUseCase()
            )
        )
    }
    
    func showShareLink(album: AlbumEntity) {
        showShareLinkCalled += 1
    }
}

private extension AlbumContentViewModel.Command {
    static func == (lhs: AlbumContentViewModel.Command, rhs: AlbumContentViewModel.Command) -> Bool {
        switch (lhs, rhs) {
        case (.showAlbumPhotos(let lhsPhotos, let lhsSortOrder), .showAlbumPhotos(let rhsPhotos, let rhsSortOrder)):
            lhsPhotos == rhsPhotos && lhsSortOrder == rhsSortOrder
        case (.showResultMessage(let lhsMessage), .showResultMessage(let rhsMessage)):
            lhsMessage == rhsMessage
        case (.configureRightBarButtons(let lhsContextMenuConfiguration, let lhsCanAddPhotosToAlbum),
              .configureRightBarButtons(let rhsContextMenuConfiguration, let rhsCanAddPhotosToAlbum)):
            lhsContextMenuConfiguration?.menuType == rhsContextMenuConfiguration?.menuType &&
            lhsContextMenuConfiguration?.sortType == rhsContextMenuConfiguration?.sortType &&
            lhsContextMenuConfiguration?.filterType == rhsContextMenuConfiguration?.filterType &&
            lhsContextMenuConfiguration?.albumType == rhsContextMenuConfiguration?.albumType &&
            lhsContextMenuConfiguration?.isFilterEnabled == rhsContextMenuConfiguration?.isFilterEnabled &&
            lhsContextMenuConfiguration?.isEmptyState == rhsContextMenuConfiguration?.isEmptyState &&
            lhsContextMenuConfiguration?.sharedLinkStatus == rhsContextMenuConfiguration?.sharedLinkStatus &&
                lhsCanAddPhotosToAlbum == rhsCanAddPhotosToAlbum
        case (.showRenameAlbumAlert(let lhsViewModel), .showRenameAlbumAlert(let rhsViewModel)):
            lhsViewModel == rhsViewModel
        case (.showEmptyView(let lhsIsEmpty, let lshIsRevampEnabled), .showEmptyView(let rhsIsEmpty, let rshIsRevampEnabled)):
            lhsIsEmpty == rhsIsEmpty && lshIsRevampEnabled == rshIsRevampEnabled
        case (.dismissAlbum, .dismissAlbum),
            (.updateNavigationTitle, .updateNavigationTitle),
            (.startLoading, .startLoading),
            (.finishLoading, .finishLoading),
            (.showRemoveLinkAlert, .showRemoveLinkAlert),
            (.showDeleteAlbumAlert, .showDeleteAlbumAlert),
            (.downloadSelectedItems, .downloadSelectedItems),
            (.showSharePhotoLinks, .showSharePhotoLinks),
            (.endEditingMode, .endEditingMode),
            (.deletePhotos, .deletePhotos),
            (.exportFiles, .exportFiles):
            true
        default:
            false
        }
    }
}
