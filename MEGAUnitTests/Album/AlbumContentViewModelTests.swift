import XCTest
import Combine
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AlbumContentViewModelTests: XCTestCase {
    private let albumEntity =
    AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif)
    
    
    private lazy var router = AlbumContentRouter(album: albumEntity, messageForNewAlbum: nil)
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldReturnNodesForAlbum() {
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1),
                             NodeEntity(name: "sample2.gif", handle: 2)]
        
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
    }
    
    func testDispatchViewReady_onLoadedNodesSuccessfully_shouldSortAndThenReturnNodesForFavouritesAlbum() throws {
        let expectedNodes = [NodeEntity(name: "sample2.gif", handle: 4, modificationTime: try "2022-12-15T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 3, modificationTime: try "2022-12-3T20:01:04Z".date),
                             NodeEntity(name: "sample1.gif", handle: 2, modificationTime: try "2022-08-19T20:01:04Z".date),
                             NodeEntity(name: "sample2.gif", handle: 1, modificationTime: try "2022-08-19T20:01:04Z".date)]
        
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
    }
    
    func testDispatchViewReady_onLoadedNodesEmptyForFavouritesAlbum_shouldShowEmptyAlbum() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: [], sortOrder: .newest)])
        XCTAssertNil(sut.contextMenuConfiguration)
    }
    
    func testDispatchViewReady_onLoadedNodesEmpty_albumNilShouldDismiss() {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.dismissAlbum])
    }
    
    func testDispatchViewReady_onNewlyCreatedAlbum_messageForNewAlbumWillBeNil() {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        messageForNewAlbum: "Hey there",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        
        XCTAssertNotNil(sut.messageForNewAlbum)
        test(viewModel: sut, action: .onViewDidAppear, expectedCommands: [.showHud("Hey there")])
        XCTAssertNil(sut.messageForNewAlbum)
    }
    
    func testSubscription_onAlbumContentUpdated_shouldShowAlbumWithNewNodes() throws {
        let updatePublisher = PassthroughSubject<Void, Never>()
        let expectedNodes = [NodeEntity(name: "sample1.gif", handle: 1)]
        let useCase = MockAlbumContentUseCase(nodes: expectedNodes, updatePublisher: updatePublisher.eraseToAnyPublisher())
        let sut = AlbumContentViewModel(album: albumEntity,
                                        albumContentsUseCase: useCase,
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        let exp = expectation(description: "show album nodes after update publisher triggered")
        sut.invokeCommand = { command in
            switch command {
            case .showAlbumPhotos(let nodes, let sortOrder):
                XCTAssertEqual(nodes, expectedNodes)
                XCTAssertEqual(sortOrder, .newest)
                exp.fulfill()
            case .dismissAlbum:
                XCTFail()
            case .showHud:
                XCTFail()
            }
        }
        updatePublisher.send()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testIsFavouriteAlbum_isEqualToAlbumEntityType() {
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
        XCTAssertTrue(sut.isFavouriteAlbum)
    }
    
    func testContextMenuConfiguration_onFavouriteAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let imageName = "sample1.gif"
        let videoName = "sample2.mp4"
        let expectedNodes = [NodeEntity(name: imageName, handle: 1),
                             NodeEntity(name: videoName, handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: NodeEntity(handle: 1), count: 2, type: .favourite),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: [imageName], videoFileNames: [videoName]),
                                        router: router)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }
    
    func testContextMenuConfiguration_onOnlyImagesLoaded_shouldShowImagesAndHideFilter() throws {
        let images = [NodeEntity(name: "test.jpg", handle: 1)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: images),
                                        mediaUseCase: MockMediaUseCase(isStringImage: true),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: images, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onOnlyVideosLoaded_shouldShowVideosAndHideFilter() throws {
        let videos = [NodeEntity(name: "test.mp4", handle: 1)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Favourites", coverNode: nil, count: 0, type: .favourite),
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: videos),
                                        mediaUseCase: MockMediaUseCase(isStringVideo: true),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: videos, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onUserAlbumContentLoadedWithItems_shouldShowFilterAndNotInEmptyState() throws {
        let imageName = "sample1.gif"
        let videoName = "sample2.mp4"
        let expectedNodes = [NodeEntity(name: imageName, handle: 1),
                             NodeEntity(name: videoName, handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: [imageName], videoFileNames: [videoName]),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertTrue(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onRawAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let imageName = "sample1.gif"
        let videoName = "sample2.mp4"
        let expectedNodes = [NodeEntity(name: imageName, handle: 1),
                             NodeEntity(name: videoName, handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 2, type: .raw),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: [imageName], videoFileNames: [videoName]),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onGifAlbumContentLoadedWithItems_shouldNotShowFilterAndNotInEmptyState() throws {
        let imageName = "sample1.gif"
        let videoName = "sample2.mp4"
        let expectedNodes = [NodeEntity(name: imageName, handle: 1),
                             NodeEntity(name: videoName, handle: 2)]
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "Gif", coverNode: NodeEntity(handle: 1), count: 2, type: .gif),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: [imageName], videoFileNames: [videoName]),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedNodes, sortOrder: .newest)])
        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onImagesOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let imageNames: [FileNameEntity] = ["image1.png", "image2.png", "image3.heic"]
        let expectedImages = imageNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1))
        }
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedImages),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: imageNames),
                                        router: router)
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])

        test(viewModel: sut, action: .changeFilter(.images), expectedCommands: [.showAlbumPhotos(photos: expectedImages, sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testContextMenuConfiguration_onVideosOnlyLoadedForUserAlbum_shouldNotEnableFilter() throws {
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideos = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + 1))
        }
        let sut = AlbumContentViewModel(album: AlbumEntity(id: 1, name: "User Album", coverNode: NodeEntity(handle: 1), count: 2, type: .user),
                                        messageForNewAlbum: "Test",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedVideos),
                                        mediaUseCase: MockMediaUseCase(videoFileNames: videoNames),
                                        router: router)
        
        test(viewModel: sut, action: .onViewReady, expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])

        test(viewModel: sut, action: .changeFilter(.videos), expectedCommands: [.showAlbumPhotos(photos: expectedVideos, sortOrder: .newest)])

        let config = try XCTUnwrap(sut.contextMenuConfiguration)
        XCTAssertNotNil(config.albumType)
        XCTAssertFalse(config.isFilterEnabled)
        XCTAssertFalse(config.isEmptyState)
    }

    func testDispatchChangeSortOrder_onSortOrderTheSame_shouldDoNothing() throws {
        let sut = AlbumContentViewModel(album: albumEntity,
                                        messageForNewAlbum: "New Album",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
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
                                        messageForNewAlbum: "New Album",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
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
                                        messageForNewAlbum: "New Album",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: expectedNodes),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
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
                                        messageForNewAlbum: "New Album",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: []),
                                        mediaUseCase: MockMediaUseCase(),
                                        router: router)
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
            NodeEntity(name: name, handle: UInt64(index + 1))
        }
        let videoNames: [FileNameEntity] = ["video1.mp4", "video2.avi", "video3.mov"]
        let expectedVideo = videoNames.enumerated().map { (index: Int, name: String) in
            NodeEntity(name: name, handle: UInt64(index + imageNames.count + 1))
        }
        let allMedia = expectedImages + expectedVideo
        let sut = AlbumContentViewModel(album: albumEntity,
                                        messageForNewAlbum: "New Album",
                                        albumContentsUseCase: MockAlbumContentUseCase(nodes: allMedia),
                                        mediaUseCase: MockMediaUseCase(imageFileNames: imageNames, videoFileNames: videoNames),
                                        router: router)
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
}
