import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumContentViewModelTests: XCTestCase {
    private let albumEntity =
    AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    
    private let router = MockAlbumContentRouting()
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldReturnNodesForAlbum() {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
    }
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldSortAndThenReturnNodesForFavouritesAlbum() throws {
        let expectedNodes = [NodeEntity(name: "sample2.gif", handle: 4, modificationTime: try "2022-12-15T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 3, modificationTime: try "2022-12-3T20:01:04Z".date),
                             NodeEntity(name: "sample1.gif", handle: 2, modificationTime: try "2022-08-19T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 1, modificationTime: try "2022-08-19T20:01:04Z".date)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
    }
    
    func testDispatchViewReady_onLoadedNodesEmptyForFavouritesAlbum_shouldShowEmptyAlbum() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertNil(sut.contextMenuConfiguration)
    }
    
    func testDispatchViewReady_onLoadedNodesEmpty_albumNilShouldDismiss() {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.dismissAlbum])
    }
    
    func testDispatchViewReady_onNewPhotosToAdd_shouldAddPhotosThenLoadAlbumContent() {
        let nodesToAdd = [NodeEntity(handle: 1), NodeEntity(handle: 2)]
        let resultEntity = AlbumElementsResultEntity(success: UInt(nodesToAdd.count), failure: 0)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase(resultEntity: resultEntity)
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: nodesToAdd.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router,
                                        newAlbumPhotosToAdd: nodesToAdd, alertViewModel: alertViewModel())
        
        
        let exp = expectation(description: "Show photos added then loaded contents")
        exp.expectedFulfillmentCount = 2
        sut.invokeCommand = { command in
            switch command {
            case .showAlbumPhotos(let nodes, let sortOrder):
                XCTAssertEqual(nodes, nodesToAdd)
                XCTAssertEqual(sortOrder, .newest)
                exp.fulfill()
            case .showHud(let message):
                XCTAssertEqual(message, "Added 2 items to “\(self.albumEntity.name)”")
                exp.fulfill()
            default:
                XCTFail("Unexpected command")
            }
        }
        sut.dispatch(.onViewReady)
        
        wait(for: [exp], timeout: 2.0)
        XCTAssertEqual(albumContentModificationUseCase.addedPhotosToAlbum, nodesToAdd)
    }
    
    func testSubscription_onAlbumContentUpdated_shouldShowAlbumWithNewNodes() throws {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1)]
        let useCase = MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities(),
                                              albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: useCase,
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
    
    func testContextMenuConfiguration_onFavouriteAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    func testContextMenuConfiguration_onOnlyImagesLoaded_shouldShowImagesAndHideFilter() throws {
        let images = [NodeEntity(name: "test.jpg", handle: 1)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: images.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: images, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onOnlyVideosLoaded_shouldShowVideosAndHideFilter() throws {
        let videos = [NodeEntity(name: "test.mp4", handle: 1)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: videos.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: videos, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onUserAlbumContentLoadedWithItems_shouldShowFilterAndNotInEmptyState() throws {
        let image = NodeEntity(name: "sample1.gif", handle: 1, mediaType: .image)
        let video = NodeEntity(name: "sample2.mp4", handle: 2, mediaType: .video)
        let expectedNodes = [image, video]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [image, video], sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onRawAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let expectedNodes = [NodeEntity(name: "sample1.cr2", handle: 1),
                             NodeEntity(name: "sample2.nef", handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 2, type: .raw),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onGifAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Gif", coverNode: NodeEntity(handle: 1), count: 2, type: .gif),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onImagesOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let imageNames: [FileNameEntity] = ["image1.png", "image2.png", "image3.heic"]
        let expectedImages = imageNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .image)
        }
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedImages.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])

        test(viewModel: sut, action: .changeFilter(.images),
             expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onVideosOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideos = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1), mediaType: .video)
        }
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedVideos.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])

        test(viewModel: sut, action: .changeFilter(.videos),
             expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testDispatchChangeSortOrder_onSortOrderTheSame_shouldDoNothing() throws {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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

    func testDispatchChangeSortOrder_onSortOrderDifferent_shouldShowAlbumWithNewSortedValue() throws {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedNodes.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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

    func testDispatchChangeFilter_onPhotosLoaded_shouldReturnCorrectNodesForFilterTypeAndSetCorrectMenuConfiguration() throws {
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
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: loadedImages + loadedVideos),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
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
    
    func testShouldShowAddToAlbumButton_onPhotoLibraryNotEmptyOnUserAlbum_shouldReturnTrue() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [NodeEntity(name: "photo 1.jpg", handle: 1)]),
                                        router: router, alertViewModel: alertViewModel())
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertTrue(sut.canAddPhotosToAlbum)
    }
    
    func testShouldShowAddToAlbumButton_onPhotoLibraryEmptyOnUserAlbum_shouldReturnFalse() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertFalse(sut.canAddPhotosToAlbum)
    }
    
    func testOnDispatchAddItemsToAlbum_routeToShowAlbumContentPicker() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: []),
                                        albumContentModificationUseCase: MockAlbumContentModificationUseCase(),
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: router, alertViewModel: alertViewModel())
        sut.showAlbumContentPicker()
        XCTAssertEqual(router.showAlbumContentPickerCalled, 1)
    }
    
    func testShowAlbumContentPicker_onCompletion_addNewItems() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let result = AlbumElementsResultEntity(success: UInt(expectedAddedPhotos.count), failure: 0)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase(resultEntity: result)
        let sut = AlbumContentViewModel(album: album,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedAddedPhotos.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: albumContentRouter, alertViewModel: alertViewModel())
        
        let exp = expectation(description: "Should show completion message after items added")
        sut.invokeCommand = {
            switch $0 {
            case .showHud(let message):
                XCTAssertEqual(message, "Added 1 item to “\(album.name)”")
                exp.fulfill()
            default:
                XCTFail()
            }
        }
        sut.showAlbumContentPicker()
        
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(albumContentModificationUseCase.addedPhotosToAlbum, expectedAddedPhotos)
    }
    
    func testShowAlbumContentPicker_onCompletionWithExistingItems_shouldNotAddExistingItems() {
        let expectedAddedPhotos = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: expectedAddedPhotos)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase()
        let sut = AlbumContentViewModel(album: album,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: expectedAddedPhotos.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: albumContentRouter, alertViewModel: alertViewModel())
        
        test(viewModel: sut, action: .onViewReady,
             expectedCommands: [.showAlbumPhotos(photos: expectedAddedPhotos, sortOrder: .newest)])
        
        let exp = expectation(description: "Should not show added message or add items")
        exp.isInverted = true
        sut.invokeCommand = {
            switch $0 {
            case .showHud:
                exp.fulfill()
            default:
                XCTFail()
            }
        }
        sut.showAlbumContentPicker()
        
        wait(for: [exp], timeout: 1)
        XCTAssertNil(albumContentModificationUseCase.addedPhotosToAlbum)
    }
    
    func testRenameAlbum_whenUserRenameAlbum_shouldUpdateAlbumName() async {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: photo)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase()
        let sut = AlbumContentViewModel(album: album,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: albumContentRouter, alertViewModel: alertViewModel())
        
        
        let expectedName = "Hey there"
        sut.renameAlbum(with: expectedName)
        await sut.renameAlbumTask?.value
        
        XCTAssertEqual(sut.albumName, expectedName)
    }
    
    func testUpdateNavigationTitle_whenUserRenameAlbum_shouldUpdateNavigationTitle() async {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: photo)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase()
        let sut = AlbumContentViewModel(album: album,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: albumContentRouter, alertViewModel: alertViewModel())
        
        
        let exp = expectation(description: "Should update navigation title")
        sut.invokeCommand = {
            switch $0 {
            case .updateNavigationTitle:
                exp.fulfill()
            default:
                XCTFail()
            }
        }
        
        let expectedName = "Hey there"
        sut.renameAlbum(with: expectedName)
        await sut.renameAlbumTask?.value

        wait(for: [exp], timeout: 1)
    }
    
    func testUpdateAlertViewModel_whenUserRenamesStaysSamePageAndRenameAgain_shouldShowLatestRenamedAlbumName() async {
        let photo = [NodeEntity(name: "a.jpg", handle: 1)]
        let album = AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user)
        let albumContentRouter = MockAlbumContentRouting(album: album, photos: photo)
        let albumContentModificationUseCase = MockAlbumContentModificationUseCase()
        let alertViewModel = TextFieldAlertViewModel(textString: "Old Album", title: "Hey there", placeholderText: "",
                                                     affirmativeButtonTitle: "Rename", affirmativeButtonInitiallyEnabled: true,
                                                     message: "", action: nil, validator: nil)
        let sut = AlbumContentViewModel(album: album,
                                        albumContentsUseCase: MockAlbumContentUseCase(photos: photo.toAlbumPhotoEntities()),
                                        albumContentModificationUseCase: albumContentModificationUseCase,
                                        photoLibraryUseCase: MockPhotoLibraryUseCase(),
                                        router: albumContentRouter,
                                        alertViewModel: alertViewModel)
        
        sut.albumName = "New Album"
        sut.updateAlertViewModel()
        
        XCTAssertEqual(sut.alertViewModel.textString, "New Album")
    }
    
    private func alertViewModel() -> TextFieldAlertViewModel {
        TextFieldAlertViewModel(title: Strings.Localizable.CameraUploads.Albums.Create.Alert.title, placeholderText: Strings.Localizable.CameraUploads.Albums.Create.Alert.placeholder, affirmativeButtonTitle: Strings.Localizable.rename, message: nil)
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
    let photos: [NodeEntity]
    
    var showAlbumContentPickerCalled = 0
    
    init(album: AlbumEntity? = nil,
         photos: [NodeEntity] = []) {
        self.album = album
        self.photos = photos
    }
    
    func showAlbumContentPicker(album: AlbumEntity, completion: @escaping (AlbumEntity, [NodeEntity]) -> Void) {
        showAlbumContentPickerCalled += 1
        completion(self.album ?? album, photos)
    }
}
