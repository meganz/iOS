import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
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
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        
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
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
    }
    
    @MainActor func testDispatchViewReady_onLoadedNodesEmptyForFavouritesAlbum_shouldShowEmptyAlbum() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertNil(sut.contextMenuConfiguration)
    }
    
    @MainActor func testDispatchViewReady_onLoadedNodesEmpty_albumNilShouldDismiss() {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.dismissAlbum])
    }
    
    @MainActor func testDispatchViewReady_onNewPhotosToAdd_shouldShowAlbumsToShowEmptyAlbumsThenAddPhotosThenLoadAlbumContent() {
        let nodesToAdd = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let resultEntity = AlbumElementsResultEntity(success: UInt(nodesToAdd.count), failure: 0)
        let albumModificationUseCase = MockAlbumModificationUseCase(addPhotosResult: .success(resultEntity))
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: nodesToAdd.toAlbumPhotoEntities()),
                                            albumModificationUseCase: albumModificationUseCase,
                                            newAlbumPhotosToAdd: nodesToAdd)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest),
                                                                      .startLoading,
                                                                      .finishLoading,
                                                                      .showResultMessage(.success("Added 2 items to “\(self.albumEntity.name)”")),
                                                                      .showAlbumPhotos(photos: nodesToAdd, sortOrder: .newest)])
        
        XCTAssertEqual(albumModificationUseCase.addedPhotosToAlbum, nodesToAdd)
    }
    
    func testSubscription_onAlbumContentUpdated_shouldShowAlbumWithNewNodes() throws {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1)]
        let useCase = MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities(),
                                              albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: useCase)
        
        let exp = expectation(description: "show album nodes after update publisher triggered")
        sut.invokeCommand = { command in
            switch command {
            case .showAlbumPhotos(let nodes, let sortOrder):
                XCTAssertEqual(nodes, expectedNodes)
                XCTAssertEqual(sortOrder, .newest)
                exp.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        albumReloadPublisher.send()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testIsFavouriteAlbum_isEqualToAlbumEntityType() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
    
    @MainActor func testContextMenuConfiguration_onFavouriteAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onOnlyImagesLoaded_shouldShowImagesAndHideFilter() throws {
        let images = [NodeEntity(name: "test.jpg", handle: 1)]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: images.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: images, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onOnlyVideosLoaded_shouldShowVideosAndHideFilter() throws {
        let videos = [NodeEntity(name: "test.mp4", handle: 1)]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: videos.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: videos, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onUserAlbumContentLoadedWithItems_shouldShowFilterAndNotInEmptyState() throws {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [image, video], sortOrder: .newest)])
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onRawAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let expectedNodes = [NodeEntity(name: "sample1.cr2", handle: 1),
                             NodeEntity(name: "sample2.nef", handle: 2)]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 2, type: .raw),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onGifAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "Gif", coverNode: NodeEntity(handle: 1), count: 2, type: .gif),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onImagesOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let imageNames: [FileNameEntity] = ["image1.png", "image2.png", "image3.heic"]
        let expectedImages = imageNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .image)
        }
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedImages.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])
        
        test(viewModel: sut, action: .changeFilter(.images),
             expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    @MainActor func testContextMenuConfiguration_onVideosOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideos = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .video)
        }
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedVideos.toAlbumPhotoEntities()))
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])
        
        test(viewModel: sut, action: .changeFilter(.videos),
             expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    func testContextMenuConfiguration_onAlbumShareLinkTurnedOff_shouldSetShareLinkStatusToUnavailble() throws {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, type: .user))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sharedLinkStatus, .unavailable)
    }
    
    func testContextMenuConfiguration_onAlbumSharedLinkTurnedOn_shouldSetCorrectStatusInContext() throws {
        let expectedAlbumShareLinkStatus = SharedLinkStatusEntity.exported(true)
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, type: .user, sharedLinkStatus: expectedAlbumShareLinkStatus))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sharedLinkStatus, expectedAlbumShareLinkStatus)
    }
    
    func testDispatchChangeSortOrder_onSortOrderTheSame_shouldDoNothing() throws {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sortType, .modificationDesc)
        let exp = expectation(description: "should not call any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.changeSortOrder(.newest))
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(config.sortType, .modificationDesc)
    }
    
    @MainActor func testDispatchChangeSortOrder_onSortOrderDifferent_shouldShowAlbumWithNewSortedValue() throws {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sortType, .modificationDesc)
        let expectedSortOrder = SortOrderType.oldest
        test(viewModel: sut, action: .changeSortOrder(expectedSortOrder),
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: expectedSortOrder)])
        let configAfter = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(configAfter.sortType, expectedSortOrder.toSortOrderEntity())
    }
    
    func DispatchChangeSortOrder_onSortOrderDifferentWithLoadedContents_shouldShowAlbumWithNewSortedValueAndExistingAlbumContents() throws {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sortType, .modificationDesc)
        
        let exp = expectation(description: "should show album twice with different sort orders")
        exp.expectedFulfillmentCount = 2
        let expectedSortOrderAfterChange = SortOrderType.oldest
        var expectedSortOrder = [SortOrderType.newest, expectedSortOrderAfterChange]
        
        sut.invokeCommand = { command in
            switch command {
            case .showAlbumPhotos(let nodes, let sortOrder):
                XCTAssertEqual(nodes, expectedNodes)
                XCTAssertEqual(sortOrder, expectedSortOrder.first)
                expectedSortOrder.removeFirst()
                exp.fulfill()
            default:
                XCTFail("Unexpected command returned")
            }
        }
        sut.dispatch(.onViewReady)
        sut.dispatch(.changeSortOrder(expectedSortOrderAfterChange))
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(config.sortType, expectedSortOrderAfterChange.toSortOrderEntity())
        XCTAssertTrue(expectedSortOrder.isEmpty)
    }
    
    func testDispatchChangeFilter_onFilterTheSame_shouldDoNothing() throws {
        let sut = makeAlbumContentViewModel(album: albumEntity,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.filterType, .allMedia)
        let exp = expectation(description: "should not call any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.changeFilter(.allMedia))
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(config.filterType, .allMedia)
    }
    
    @MainActor func testDispatchChangeFilter_onPhotosLoaded_shouldReturnCorrectNodesForFilterTypeAndSetCorrectMenuConfiguration() throws {
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
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.filterType, .allMedia)
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: allMedia, sortOrder: .newest)])
        
        test(viewModel: sut, action: .changeFilter(.images),
             expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)],
             timeout: 0.25)
        let configAfter = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(configAfter.filterType, .images)
        
        test(viewModel: sut, action: .changeFilter(.videos),
             expectedCommands: [.showAlbumPhotos(photos: expectedVideo, sortOrder: .newest)],
             timeout: 0.25)
        let configAfter1 = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(configAfter1.filterType, .videos)
        
        test(viewModel: sut, action: .changeFilter(.allMedia),
             expectedCommands: [.showAlbumPhotos(photos: allMedia, sortOrder: .newest)],
             timeout: 0.25)
        let configAfter2 = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(configAfter2.filterType, .allMedia)
    }
    
    @MainActor func testShouldShowAddToAlbumButton_onPhotoLibraryNotEmptyOnUserAlbum_shouldReturnTrue() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [NodeEntity(name: "photo 1.jpg", handle: 1)]))
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertTrue(sut.canAddPhotosToAlbum)
    }
    
    @MainActor func testShouldShowAddToAlbumButton_onPhotoLibraryEmptyOnUserAlbum_shouldReturnFalse() {
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []))
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertFalse(sut.canAddPhotosToAlbum)
    }
    
    func testOnDispatchAddItemsToAlbum_routeToShowAlbumContentPicker() {
        let router = MockAlbumContentRouting()
        let sut = makeAlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            router: router)
        
        sut.showAlbumContentPicker()
        XCTAssertEqual(router.showAlbumContentPickerCalled, 1)
    }
    
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
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedAddedPhotos, sortOrder: .newest)])
        
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
    
    @MainActor func testShowAlbumContentPicker_onErrorThrown_shouldFinishLoading() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let albumModificationUseCase = MockAlbumModificationUseCase(addPhotosResult: .failure(AlbumErrorEntity.generic))
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        
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
    
    @MainActor func testShowAlbumCoverPicker_onChangingNewCoverPic_shouldChangeTheCoverPic() {
        let photos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: nil, count: 2, type: .user)
        
        let albumContentRouter = MockAlbumContentRouting(album: album, albumPhoto: AlbumPhotoEntity(photo: NodeEntity(handle: HandleEntity(1))), photos: photos)
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: photos.map {AlbumPhotoEntity(photo: $0)}),
                                            albumModificationUseCase: albumModificationUseCase,
                                            router: albumContentRouter)
        
        test(viewModel: sut, action: .showAlbumCoverPicker,
             expectedCommands: [.showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.albumCoverUpdated))])
    }
    
    @MainActor func testDispatchDeletePhotos_onSuccessfulRemovalOfPhotos_shouldShowHudOfNumberOfRemovedItems() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let nodesToRemove = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let albumPhotos = nodesToRemove.enumerated().map { AlbumPhotoEntity(photo: $0.element, albumPhotoId: UInt64($0.offset + 1))}
        let resultEntity = AlbumElementsResultEntity(success: UInt(nodesToRemove.count), failure: 0)
        let albumModificationUseCase = MockAlbumModificationUseCase(resultEntity: resultEntity)
        
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: albumPhotos),
                                            albumModificationUseCase: albumModificationUseCase)
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: nodesToRemove, sortOrder: .newest)])
        
        let message = Strings.Localizable.CameraUploads.Albums.removedItemFrom(Int(resultEntity.success))
            .replacingOccurrences(of: "[A]", with: "\(album.name)")
        test(viewModel: sut, action: .deletePhotos(nodesToRemove),
             expectedCommands: [.showResultMessage(.custom(UIImage.hudMinus, message))])
        XCTAssertEqual(albumModificationUseCase.deletedPhotos, albumPhotos)
    }
    
    @MainActor func testDispatchDeletePhotos_onPhotosAlreadyRemoved_shouldDoNothing() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let nodesToRemove = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let albumModificationUseCase = MockAlbumModificationUseCase()
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                            albumModificationUseCase: albumModificationUseCase)
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        let exp = expectation(description: "Should not invoke any commands")
        exp.isInverted = true
        sut.invokeCommand = { _ in
            exp.fulfill()
        }
        sut.dispatch(.deletePhotos(nodesToRemove))
        wait(for: [exp], timeout: 1.0)
        XCTAssertNil(albumModificationUseCase.deletedPhotos)
    }
    
    @MainActor func testShowAlbumPhotos_onImagesRemovedWithImageFilter_shouldSwitchToShowVideos() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let expectedImages = [NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)]
        let expectedVideos = [NodeEntity(name: "sample1.mp4", handle: 1, mediaType: .video)]
        let allPhotos = expectedImages + expectedVideos
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        var albumContentsUseCase = MockAlbumContentUseCase(photos: allPhotos.toAlbumPhotoEntities(),
                                                           albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = makeAlbumContentViewModel(album: album,
                                            albumContentsUseCase: albumContentsUseCase)
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: allPhotos, sortOrder: .newest)])
        
        test(viewModel: sut, action: .changeFilter(.images),
             expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)],
             timeout: 0.25)
        
        albumContentsUseCase.photos = expectedVideos.toAlbumPhotoEntities()
        let exp = expectation(description: "should show only videos")
        sut.invokeCommand = { command in
            switch command {
            case .showAlbumPhotos(let nodes, let sortOrder):
                XCTAssertEqual(nodes, expectedVideos)
                XCTAssertEqual(sortOrder, .newest)
                exp.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        albumReloadPublisher.send()
        wait(for: [exp], timeout: 1.0)
    }
    
    @MainActor func testDispatchDeleteAlbum_onSuccessfulRemovalOfAlbum_shouldShowHudOfRemoveAlbum() {
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: nil, count: 1, type: .user)
        let albumModificationUseCase = MockAlbumModificationUseCase(albums: [album])
        let sut = makeAlbumContentViewModel(album: album,
                                            albumModificationUseCase: albumModificationUseCase)
        
        let message = Strings.Localizable.CameraUploads.Albums.deleteAlbumSuccess(1)
            .replacingOccurrences(of: "[A]", with: album.name)
        
        test(viewModel: sut, action: .deleteAlbum, expectedCommands: [
            .dismissAlbum,
            .showResultMessage(.custom(UIImage.hudMinus, message))
        ])
        
        XCTAssertEqual(albumModificationUseCase.deletedAlbumsIds, [album.id])
    }
    
    @MainActor func testDispatchConfigureContextMenu_onReceived_shouldRebuildContextMenuWithNewSelectHiddenValue() {
        let sut = makeAlbumContentViewModel(album: albumEntity)
        
        let expectedContextConfigurationSelectHidden = true
        test(viewModel: sut, action: .configureContextMenu(isSelectHidden: expectedContextConfigurationSelectHidden),
             expectedCommands: [.rebuildContextMenu])
        XCTAssertEqual(sut.contextMenuConfiguration?.isSelectHidden, expectedContextConfigurationSelectHidden)
    }
    
    func testSubscription_onUserAlbumPublisherEmission_shouldDismissIfSetContainsRemoveChangeType() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
        let exp = expectation(description: "album dismissal")
        sut.invokeCommand = {
            switch $0 {
            case .dismissAlbum:
                exp.fulfill()
            default:
                XCTFail("Unexpected command returned")
            }
        }
        albumUpdatedPublisher.send(SetEntity(handle: albumEntity.id, changeTypes: .removed))
        wait(for: [exp], timeout: 1.0)
    }
    
    func testSubscription_onUserAlbumPublisherEmission_shouldUpdateNavigationTitleNameIfItContainsNameChangeType() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
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
        wait(for: [exp], timeout: 1.0)
    }
    
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
    
    @MainActor func testAction_removeLink_shouldShowSuccessAfterRemoved() {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            shareCollectionUseCase: MockShareCollectionUseCase(removeSharedCollectionLinkResult: .success))
        
        test(viewModel: sut, action: .removeLink, expectedCommands: [
            .showResultMessage(.success(Strings.Localizable.CameraUploads.Albums.removeShareLinkSuccessMessage(1)))
        ])
    }
    
    func testSubscription_onUserAlbumPublisherEmission_shouldUpdateContextMenuIfAlbumContainsExportedChangeType() throws {
        let userAlbum = AlbumEntity(id: 1, type: .user)
        let albumUpdatedPublisher = PassthroughSubject<SetEntity, Never>()
        let sut = makeAlbumContentViewModel(album: userAlbum,
                                            albumContentsUseCase: MockAlbumContentUseCase(albumUpdatedPublisher: albumUpdatedPublisher.eraseToAnyPublisher()))
        
        let exp = expectation(description: "context menu should rebuild")
        sut.invokeCommand = {
            switch $0 {
            case .rebuildContextMenu:
                exp.fulfill()
            default:
                XCTFail("Unexpected command returned")
            }
        }
        let isExported = true
        albumUpdatedPublisher.send(SetEntity(handle: albumEntity.id, isExported: isExported, changeTypes: .exported))
        wait(for: [exp], timeout: 1.0)
        
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertEqual(config.sharedLinkStatus, .exported(isExported))
    }
    
    func testDispatchHideNodes_shouldTrackActionEvent() {
        let tracker = MockTracker()
        let sut = makeAlbumContentViewModel(
            album: albumEntity,
            tracker: tracker)
        
        test(viewModel: sut, action: .hideNodes, expectedCommands: [])
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                AlbumContentHideNodeMenuItemEvent()
            ]
        )
    }
    
    // MARK: - Helpers
    
    private func makeAlbumContentViewModel(
        album: AlbumEntity,
        albumContentsUseCase: some AlbumContentsUseCaseProtocol = MockAlbumContentUseCase(),
        albumModificationUseCase: some AlbumModificationUseCaseProtocol = MockAlbumModificationUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        router: some AlbumContentRouting = MockAlbumContentRouting(),
        newAlbumPhotosToAdd: [NodeEntity]? = nil,
        alertViewModel: TextFieldAlertViewModel? = nil,
        tracker: some AnalyticsTracking = MockTracker()
    ) -> AlbumContentViewModel {
        AlbumContentViewModel(album: album,
                              albumContentsUseCase: albumContentsUseCase,
                              albumModificationUseCase: albumModificationUseCase,
                              photoLibraryUseCase: photoLibraryUseCase,
                              shareCollectionUseCase: shareCollectionUseCase,
                              router: router,
                              newAlbumPhotosToAdd: newAlbumPhotosToAdd,
                              alertViewModel: alertViewModel ?? makeAlertViewModel(),
                              tracker: tracker)
    }
    
    private func makeAlertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title,
                                placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder,
                                affirmativeButtonTitle: Strings.Localizable.rename, destructiveButtonTitle: Strings.Localizable.cancel, message: nil)
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
    
    init(album: AlbumEntity? = nil,
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
                nodeUseCase: MockNodeDataUseCase()
            )
        )
    }
    
    func showShareLink(album: AlbumEntity) {
        showShareLinkCalled += 1
    }
}
