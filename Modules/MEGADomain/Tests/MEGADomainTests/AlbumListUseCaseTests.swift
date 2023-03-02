import XCTest
import Combine
import MEGADomain
import MEGADomainMock

final class AlbumListUseCaseTests: XCTestCase {
    private let photos = [
        NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
        NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true),
        NodeEntity(name: "3.cr2", handle: 3, hasThumbnail: false),
        NodeEntity(name: "4.dng", handle: 4, hasThumbnail: false),
        NodeEntity(name: "5.gif", handle: 5, hasThumbnail: true)]
    
    private let emptyFavouritesAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "", coverNode: nil, count: 0, type: .favourite)
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadCameraUploadNode_whenLoadingFavouriteAlbum_shouldReturnOneRootNode() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let rootNode = try await sut.loadCameraUploadNode()
        XCTAssertNotNil(rootNode)
    }
    
    func testSystemAlbums_whenLoadingRawSystemAlbum_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isRawImage: true),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = try await sut.systemAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .raw)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbum_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = try await sut.systemAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .gif)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let favouriteGifPhotos = [
            NodeEntity(name: "1.gif", handle: 2, hasThumbnail: true, isFavourite: true),
        ]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouriteGifPhotos),
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first?.type, AlbumEntityType.favourite)
        XCTAssertEqual(albums.last?.type, AlbumEntityType.gif)
    }
    
    func testSystemAlbums_whenLoadingRawSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let favouriteRawPhotos = try (1...4).map {
            NodeEntity(name: "\($0).raw", handle: $0, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:0\($0):04Z".date)
        }
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouriteRawPhotos),
            mediaUseCase: MockMediaUseCase(isRawImage: true),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: favouriteRawPhotos.last, count: UInt(favouriteRawPhotos.count), type: .favourite))
        XCTAssertEqual(albums.last?.type, AlbumEntityType.raw)
    }
    
    func testSystemAlbums_whenLoadingFavouritePhotosAndVideos_shouldFilterThumbnailsAndSelectLatestCover() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date),
            expectedCoverNode
        ]
        let expectedFavouritesCount = UInt((favouritePhotos + favouriteVideos).filter { $0.hasThumbnail && $0.isFavourite }.count)
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 1)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: expectedCoverNode, count: expectedFavouritesCount, type: .favourite))
    }
    
    func testUserAlbums_loadAndRetrieveAlbumCover() async {
        let albumId = HandleEntity(1)
        let albumSetCoverId = HandleEntity(3)
        let albumCoverNodeId = HandleEntity(3)
        let expectedAlbumCover = NodeEntity(handle: albumCoverNodeId)
        let expectedAlbums = [
            SetEntity(handle: albumId, userId: HandleEntity(2), coverId: albumSetCoverId,
                      modificationTime: Date(), name: "Album 1"),
        ]
        let expectedAlbumContents = [albumId:
                                        [SetElementEntity(handle: albumSetCoverId, order: 2, nodeId: albumCoverNodeId, modificationTime: Date(), name: "Test")]]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums, albumContent: expectedAlbumContents),
            fileSearchRepository: MockFilesSearchRepository(photoNodes: [expectedAlbumCover]),
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = await sut.userAlbums()
        XCTAssertEqual(albums.count, expectedAlbums.count)
        XCTAssertFalse(albums.contains { $0.type != .user})
        XCTAssertEqual(albums.first?.coverNode, expectedAlbumCover)
    }
    
    func testUserAlbums_loadAlbumWithoutCover_coverIdIsNil() async {
        let expectedAlbums = [
            SetEntity(handle: 1, userId: HandleEntity(2), coverId: HandleEntity.invalid,
                      modificationTime: Date(), name: "Album 1"),
        ]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums),
            fileSearchRepository: MockFilesSearchRepository(),
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let albums = await sut.userAlbums()
        XCTAssertEqual(albums.count, expectedAlbums.count)
        XCTAssertNil(albums.first?.coverNode)
    }
    
    func testCreateUserAlbum_shouldCreateAlbumWithName() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date),
            expectedCoverNode
        ]
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        let result = try await sut.createUserAlbum(with: "Custom Album")
        XCTAssertEqual(result.name, "Custom Album")
        XCTAssertNotNil(result.modificationTime)
    }
    
    func testHasNoPhotosAndVideos_whenCreatingAlbumInFreshNewAccount_shouldReturnEmpty() async throws {
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository(
                photoNodes: [
                    NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
                    NodeEntity(name: "1.png", handle: 1, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
                ]
            ),
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        
        let hasNoPhotosAndVideos = await sut.hasNoPhotosAndVideos()
        XCTAssertTrue(hasNoPhotosAndVideos)
    }
    
    func testAlbumsUpdatedPublisher_onAlbumReload_shouldEmitToPublisher() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let albumContentRepo = MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            fileSearchRepository: MockFilesSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: albumContentRepo)
        
        let exp = expectation(description: "album update publisher should emit")
        sut.albumsUpdatedPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumReloadPublisher.send()
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAlbumsUpdatedPublisher_onAnySetUpdates_shouldEmitToPublisher() {
        let setsUpdatedPublisher = PassthroughSubject<[SetEntity], Never>()
        let setElementsUpdatedPublisher = PassthroughSubject<[SetElementEntity], Never>()
        let userRepo = MockUserAlbumRepository(setsUpdatedPublisher: setsUpdatedPublisher.eraseToAnyPublisher(),
                                               setElemetsUpdatedPublisher: setElementsUpdatedPublisher.eraseToAnyPublisher())
        let sut = AlbumListUseCase(
            albumRepository: MockAlbumRepository.newRepo,
            userAlbumRepository: userRepo,
            fileSearchRepository: MockFilesSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo)
        
        let exp = expectation(description: "album update publisher should emit multiple times")
        exp.expectedFulfillmentCount = 2
        sut.albumsUpdatedPublisher
            .sink {
                exp.fulfill()
            }.store(in: &subscriptions)
        
        setsUpdatedPublisher.send([])
        setsUpdatedPublisher.send([SetEntity(handle: 1, userId: 1, coverId: 1,
                                             modificationTime: Date(), name: "Test")])
        setElementsUpdatedPublisher.send([])
        setElementsUpdatedPublisher.send([SetElementEntity(handle: 1, order: 1, nodeId: 1,
                                                           modificationTime: Date(), name: "Test")])
        wait(for: [exp], timeout: 1.0)
    }
}
