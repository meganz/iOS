import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGASwift
import MEGASwiftUI
import MEGATest
import XCTest

final class AlbumContentViewModelTests: XCTestCase {
    private let albumEntity =
    AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    
    @MainActor func testDispatchViewReady_onLoadedNodesSuccessfully_shouldReturnNodesForAlbumAndTrackScreenEvent() {
        let tracker = MockTracker()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                            tracker: tracker)
        let expectedConfiguration = makeContextConfiguration(
            albumType: albumEntity.type
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumContentScreenEvent()
            ]
        )
    }
    
    @MainActor func testDispatchViewReady_onLoadedNodesSuccessfully_shouldSortAndThenReturnNodesForFavouritesAlbum() throws {
        let expectedNodes = [NodeEntity(name: "sample2.gif", handle: 4, modificationTime: try "2022-12-15T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 3, modificationTime: try "2022-12-3T20:01:04Z".date),
                             NodeEntity(name: "sample1.gif", handle: 2, modificationTime: try "2022-08-19T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 1, modificationTime: try "2022-08-19T20:01:04Z".date)]
        let album = AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor func testDispatchViewReady_onLoadedNodesEmptyForFavouritesAlbum_shouldShowEmptyAlbum() {
        let album = AlbumEntity(id: 1, name: "Favourites", type: .favourite)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor func testDispatchViewReady_onLoadedNodesEmpty_albumNilShouldDismiss() {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .dismissAlbum
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor func testDispatchViewReady_onNewPhotosToAdd_shouldShowAlbumsToShowEmptyAlbumsThenAddPhotosThenLoadAlbumContent() {
        let nodesToAdd = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let resultEntity = AlbumElementsResultEntity(success: UInt(nodesToAdd.count), failure: 0)
        let albumModificationUseCase = MockAlbumModificationUseCase(addPhotosResult: .success(resultEntity))
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: nodesToAdd.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase,
                                            newAlbumPhotosToAdd: nodesToAdd)
        let expectedConfiguration = makeContextConfiguration(
            albumType: albumEntity.type
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .startLoading,
            .finishLoading,
            .showResultMessage(.success("Added 2 items to “\(self.albumEntity.name)”")),
            .showAlbumPhotos(photos: nodesToAdd, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        XCTAssertEqual(albumModificationUseCase.addedPhotosToAlbum, nodesToAdd)
    }

    @MainActor
    func testDispatchViewWillAppear_onAlbumContentUpdated_shouldShowAlbumWithNewNodes() async {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1)]
        let useCase = MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities(),
                                              albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: useCase)
        
        sut.dispatch(.onViewWillAppear)
        await sut.setupSubscriptionTask?.value
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: albumEntity.type
        )
        await test(viewModel: sut, trigger: { albumReloadPublisher.send() }, expectedCommands: [
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testIsFavouriteAlbum_isEqualToAlbumEntityType() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
    
    @MainActor
    func testContextMenuConfiguration_onFavouriteAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let album = AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: true,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testContextMenuConfiguration_onOnlyImagesLoaded_shouldShowImagesAndHideFilter() {
        let images = [NodeEntity(name: "test.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, type: .favourite)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: images.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: images, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testContextMenuConfiguration_onOnlyVideosLoaded_shouldShowVideosAndHideFilter() {
        let videos = [NodeEntity(name: "test.mp4", handle: 1)]
        let album = AlbumEntity(id: 1, type: .favourite)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: videos.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: videos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testContextMenuConfiguration_onUserAlbumContentLoadedWithItems_shouldShowFilterAndNotInEmptyState() {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: true,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testContextMenuConfiguration_onRawAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() {
        let expectedNodes = [NodeEntity(name: "sample1.cr2", handle: 1),
                             NodeEntity(name: "sample2.nef", handle: 2)]
        let album = AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 2, type: .raw)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testContextMenuConfiguration_onGifAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let album = AlbumEntity(id: 1, name: "Gif", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedConfiguration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: expectedConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testContextMenuConfiguration_onImagesOnlyLoadedForUserAlbum_shouldNotEnableFilter() {
        let imageNames: [FileNameEntity] = ["image1.png", "image2.png", "image3.heic"]
        let expectedImages = imageNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .image)
        }
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedImages.toAlbumPhotoEntities()))
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: expectedImages, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        test(viewModel: sut, action: .changeFilter(.images), expectedCommands: [
            .showAlbumPhotos(photos: expectedImages, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testContextMenuConfiguration_onVideosOnlyLoadedForUserAlbum_shouldNotEnableFilter() {
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideos = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .video)
        }
        let album = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedVideos.toAlbumPhotoEntities()))
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isFilterEnabled: false,
            isEmptyState: false
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: expectedVideos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        test(viewModel: sut, action: .changeFilter(.videos), expectedCommands: [
            .showAlbumPhotos(photos: expectedVideos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testContextMenuConfiguration_onAlbumSharedLinkTurnedOn_shouldSetCorrectStatusInContext() {
        let expectedAlbumShareLinkStatus = SharedLinkStatusEntity.exported(true)
        let album = AlbumEntity(id: 1, type: .user, sharedLinkStatus: expectedAlbumShareLinkStatus)
        let sut = makeAlbumContentViewModel(
            album: album, albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true,
            sharedLinkStatus: album.sharedLinkStatus
        )
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
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
    func testDispatchChangeSortOrder_onSortOrderDifferentWithLoadedContents_shouldShowAlbumWithNewSortedValueAndExistingAlbumContents() {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let expectedSortOrderAfterChange = SortOrderType.oldest
        var expectedSortOrders = [SortOrderType.newest, expectedSortOrderAfterChange]
        
        let initialConfiguration = makeContextConfiguration(
            albumType: albumEntity.type
        )
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: expectedNodes, sortOrder: expectedSortOrders.removeFirst()),
            .configureRightBarButtons(contextMenuConfiguration: initialConfiguration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        let updatedConfiguration = makeContextConfiguration(
            sortOrder: expectedSortOrderAfterChange.toSortOrderEntity(),
            albumType: albumEntity.type
        )
        
        test(viewModel: sut, action: .changeSortOrder(expectedSortOrderAfterChange), expectedCommands: [
            .showAlbumPhotos(photos: expectedNodes, sortOrder: expectedSortOrders.removeFirst()),
            .configureRightBarButtons(contextMenuConfiguration: updatedConfiguration, canAddPhotosToAlbum: false)
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
    func testDispatchChangeFilter_onPhotosLoaded_shouldReturnCorrectNodesForFilterTypeAndSetCorrectMenuConfiguration() {
        let imageNames: [FileNameEntity] = ["image1.png", "image2.png", "image3.heic"]
        let expectedImages = imageNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .image)
        }
        let loadedImages = expectedImages.toAlbumPhotoEntities()
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideo = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + imageNames.count + 1), mediaType: .video)
        }
        let loadedVideos = expectedVideo.toAlbumPhotoEntities()
        let allMedia = expectedImages + expectedVideo
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: loadedImages + loadedVideos))
        
        let configuration = makeContextConfiguration(albumType: albumEntity.type)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: allMedia, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        let testCases = [
            (FilterType.images, expectedImages),
            (FilterType.videos, expectedVideo),
            (FilterType.allMedia, allMedia)
        ]
         
        for (filter, expectedNodes) in testCases {
            let filterConfiguration = makeContextConfiguration(
                filter: filter.toFilterEntity(),
                albumType: albumEntity.type
            )
            
            test(viewModel: sut, action: .changeFilter(filter), expectedCommands: [
                .showAlbumPhotos(photos: expectedNodes, sortOrder: .newest),
                .configureRightBarButtons(contextMenuConfiguration: filterConfiguration, canAddPhotosToAlbum: false)
            ], timeout: 1.0, expectationValidation: ==)
        }
    }
    
    @MainActor 
    func testShouldShowAddToAlbumButton_onPhotoLibraryNotEmptyOnUserAlbum_shouldReturnTrue() {
        let album = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [NodeEntity(name: "photo 1.jpg", handle: 1)]))
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true
        )
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testShouldShowAddToAlbumButton_onPhotoLibraryEmptyOnUserAlbum_shouldReturnFalse() {
        let album = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true
        )
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor
    func testOnDispatchAddItemsToAlbum_routeToShowAlbumContentPicker() {
        let router = MockAlbumContentRouting()
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            router: router)
        
        sut.showAlbumContentPicker()
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
        sut.showAlbumContentPicker()
        
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(albumModificationUseCase.addedPhotosToAlbum, expectedAddedPhotos)
    }
    
    @MainActor func testShowAlbumContentPicker_onCompletionWithExistingItems_shouldNotAddExistingItems() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedAddedPhotos.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        let configuration = makeContextConfiguration(albumType: album.type)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: expectedAddedPhotos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        let exp = expectation(description: "Should not show added message or add items")
        exp.isInverted = true
        sut.invokeCommand = {
            switch $0 {
            case .showResultMessage:
                exp.fulfill()
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        sut.showAlbumContentPicker()
        
        wait(for: [exp], timeout: 1)
        XCTAssertNil(albumModificationUseCase.addedPhotosToAlbum)
    }
    
    @MainActor 
    func testShowAlbumContentPicker_onErrorThrown_shouldFinishLoading() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let albumModificationUseCase = MockAlbumModificationUseCase(addPhotosResult: .failure(AlbumErrorEntity.generic))
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        let exp = expectation(description: "Should only show loading then finish loading")
        exp.expectedFulfillmentCount = 2
        sut.invokeCommand = {
            switch $0 {
            case .startLoading:
                exp.fulfill()
            case .finishLoading:
                exp.fulfill()
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        sut.showAlbumContentPicker()
        
        wait(for: [exp], timeout: 2)
        XCTAssertNil(albumModificationUseCase.addedPhotosToAlbum)
    }
    
    @MainActor
    func testRenameAlbum_whenUserRenameAlbum_shouldUpdateAlbumNameAndNavigationTitle() {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase)
        
        let exp = expectation(description: "Should update navigation title")
        sut.invokeCommand = {
            switch $0 {
            case .updateNavigationTitle:
                exp.fulfill()
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        
        let expectedName = "Hey there"
        sut.renameAlbum(with: expectedName)
        
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.albumName, expectedName)
    }
    
    @MainActor
    func testUpdateAlertViewModel_whenUserRenamesStaysSamePageAndRenameAgain_shouldShowLatestRenamedAlbumName() {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: photo)
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let alertViewModel = TextFieldAlertViewModel(textString: "Old Album", title: "Hey there", placeholderText: "",
                                                     affirmativeButtonTitle: "Rename", affirmativeButtonInitiallyEnabled: true,
                                                     destructiveButtonTitle: Strings.Localizable.cancel,
                                                     message: "", action: nil, validator: nil)
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter,
                                            alertViewModel: alertViewModel)
        
        let expectedName = "New Album"
        let exp = expectation(description: "Should update navigation title")
        sut.invokeCommand = {
            switch $0 {
            case .updateNavigationTitle:
                sut.updateAlertViewModel()
                exp.fulfill()
            default:
                XCTFail("Invoked unexpected command: \($0)")
            }
        }
        sut.renameAlbum(with: expectedName)
        
        wait(for: [exp], timeout: 1)
        XCTAssertEqual(sut.alertViewModel.textString, "New Album")
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
    func testDispatchDeletePhotos_onSuccessfulRemovalOfPhotos_shouldShowHudOfNumberOfRemovedItems() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let nodesToRemove = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let albumPhotos = nodesToRemove.enumerated().map { AlbumPhotoEntity(photo: $0.element, albumPhotoId: UInt64($0.offset + 1))}
        let resultEntity = AlbumElementsResultEntity(success: UInt(nodesToRemove.count), failure: 0)
        let albumModificationUseCase = MockAlbumModificationUseCase(resultEntity: resultEntity)
        
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: albumPhotos),
                                            albumModificationUseCase: albumModificationUseCase)
        let configuration = makeContextConfiguration(albumType: album.type)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: nodesToRemove, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        let message = Strings.Localizable.CameraUploads.Albums.removedItemFrom(Int(resultEntity.success))
            .replacingOccurrences(of: "[A]", with: "\(album.name)")
        test(viewModel: sut, action: .deletePhotos(nodesToRemove),
             expectedCommands: [.showResultMessage(.custom(UIImage.hudMinus, message))],
             timeout: 1.0, expectationValidation: ==)
        XCTAssertEqual(albumModificationUseCase.deletedPhotos, albumPhotos)
    }
    
    @MainActor 
    func testDispatchDeletePhotos_onPhotosAlreadyRemoved_shouldDoNothing() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let nodesToRemove = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            albumModificationUseCase: albumModificationUseCase)
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
        ], timeout: 1.0, expectationValidation: ==)
        
        let exp = expectation(description: "Should not invoke any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.deletePhotos(nodesToRemove))
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(albumModificationUseCase.deletedPhotos)
    }
    
    @MainActor 
    func testShowAlbumPhotos_onImagesRemovedWithImageFilter_shouldSwitchToShowVideos() async {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let expectedImages = [NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)]
        let expectedVideos = [NodeEntity(name: "sample1.mp4", handle: 1, mediaType: .video)]
        let allPhotos = expectedImages + expectedVideos
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let albumContentsUseCase = MockAlbumContentUseCase(photos: allPhotos.toAlbumPhotoEntities(),
                                                           albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = makeAlbumContentViewModel(
            album: album,
            albumContentsUseCase: albumContentsUseCase)
        
        let configuration = makeContextConfiguration(albumType: album.type,
                                                     isFilterEnabled: true)
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: allPhotos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        await sut.setupSubscriptionTask?.value
        
        let imageFilterConfiguration = makeContextConfiguration(
            filter: .images,
            albumType: album.type,
            isFilterEnabled: true)
        await test(viewModel: sut, actions: [.changeFilter(.images)], expectedCommands: [
            .showAlbumPhotos(photos: expectedImages, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: imageFilterConfiguration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
        
        await albumContentsUseCase.state.update(photos: expectedVideos.toAlbumPhotoEntities())
        
        let videoFilterConfiguration = makeContextConfiguration(
            filter: .allMedia,
            albumType: album.type,
            isFilterEnabled: false)
        
        await test(viewModel: sut, trigger: { albumReloadPublisher.send() }, expectedCommands: [
            .showAlbumPhotos(photos: expectedVideos, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: videoFilterConfiguration, canAddPhotosToAlbum: true)
        ], timeout: 1.0, expectationValidation: ==)
    }
    
    @MainActor 
    func testDispatchDeleteAlbum_onSuccessfulRemovalOfAlbum_shouldShowHudOfRemoveAlbum() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: nil, count: 1, type: .user)
        let albumModificationUseCase = MockAlbumModificationUseCase(albums: [album])
        let sut = makeAlbumContentViewModel(album: album,
                                            albumModificationUseCase: albumModificationUseCase)
        
        let message = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(1)
            .replacingOccurrences(of: "[A]", with: album.name)
        
        test(viewModel: sut, action: .deleteAlbum, expectedCommands: [
            .dismissAlbum,
            .showResultMessage(.custom(UIImage.hudMinus, message))
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
    func testAction_removeLink_shouldShowSuccessAfterRemoved() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            shareCollectionUseCase: MockShareCollectionUseCase(removeSharedCollectionLinkResult: .success))
        
        test(viewModel: sut, action: .removeLink, expectedCommands: [
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
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
            albumRemoteFeatureFlagProvider: MockAlbumRemoteFeatureFlagProvider(isEnabled: true))
        
        let configuration = makeContextConfiguration(albumType: albumEntity.type)
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: false),
            .showAlbumPhotos(photos: photoNodes, sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: false)
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
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
            albumRemoteFeatureFlagProvider: MockAlbumRemoteFeatureFlagProvider(isEnabled: true))
        
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
            monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
            albumRemoteFeatureFlagProvider: MockAlbumRemoteFeatureFlagProvider(isEnabled: true))
        
        let configuration = makeContextConfiguration(
            albumType: album.type,
            isEmptyState: true
        )
        
        await test(viewModel: sut, actions: [.onViewReady, .onViewWillAppear], expectedCommands: [
            .configureRightBarButtons(contextMenuConfiguration: nil, canAddPhotosToAlbum: true),
            .showAlbumPhotos(photos: [], sortOrder: .newest),
            .configureRightBarButtons(contextMenuConfiguration: configuration, canAddPhotosToAlbum: true)
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
        router: some AlbumContentRouting = MockAlbumContentRouting(),
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        alertViewModel: TextFieldAlertViewModel? = nil,
        tracker: some AnalyticsTracking = MockTracker(),
        albumRemoteFeatureFlagProvider: some AlbumRemoteFeatureFlagProviderProtocol = MockAlbumRemoteFeatureFlagProvider()
    ) -> AlbumContentViewModel {
        AlbumContentViewModel(album: album,
                              albumContentsUseCase: albumContentsUseCase,
                              albumModificationUseCase: albumModificationUseCase,
                              photoLibraryUseCase: photoLibraryUseCase,
                              shareCollectionUseCase: shareCollectionUseCase,
                              monitorAlbumPhotosUseCase: monitorAlbumPhotosUseCase,
                              router: router,
                              newAlbumPhotosToAdd: newAlbumPhotosToAdd,
                              alertViewModel: alertViewModel ?? makeAlertViewModel(),
                              tracker: tracker,
                              albumRemoteFeatureFlagProvider: albumRemoteFeatureFlagProvider)
    }
    
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
        case (.dismissAlbum, .dismissAlbum),
            (.updateNavigationTitle, .updateNavigationTitle),
            (.startLoading, .startLoading),
             (.finishLoading, .finishLoading):
            true
        default:
            false
        }
    }
}
