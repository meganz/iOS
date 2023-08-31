import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumListUseCaseTests: XCTestCase {
    private let photos = [
        NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true, mediaType: .image),
        NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true, mediaType: .image),
        NodeEntity(name: "3.cr2", handle: 3, hasThumbnail: false, mediaType: .image),
        NodeEntity(name: "4.dng", handle: 4, hasThumbnail: false, mediaType: .image),
        NodeEntity(name: "5.gif", handle: 5, hasThumbnail: true, mediaType: .image)]
    
    private let emptyFavouritesAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "", coverNode: nil, count: 0, type: .favourite)
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testSystemAlbums_whenLoadingRawSystemAlbum_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isRawImage: true),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .raw)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbum_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: photos),
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .gif)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let favouriteGifPhotos = [
            NodeEntity(name: "1.gif", handle: 2, hasThumbnail: true, isFavourite: true, mediaType: .image)
        ]
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouriteGifPhotos),
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first?.type, AlbumEntityType.favourite)
        XCTAssertEqual(albums.last?.type, AlbumEntityType.gif)
    }
    
    func testSystemAlbums_whenLoadingRawSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let favouriteRawPhotos = try (1...4).map {
            NodeEntity(name: "\($0).raw", handle: $0, hasThumbnail: true, isFavourite: true,
                       modificationTime: try "2022-08-18T22:0\($0):04Z".date, mediaType: .image)
        }
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouriteRawPhotos),
            mediaUseCase: MockMediaUseCase(isRawImage: true),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: favouriteRawPhotos.last, count: favouriteRawPhotos.count, type: .favourite))
        XCTAssertEqual(albums.last?.type, AlbumEntityType.raw)
    }
    
    func testSystemAlbums_whenLoadingFavouritePhotosAndVideos_shouldFilterThumbnailsAndInvalidMediaTypesThenSelectLatestCover() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true,
                                           modificationTime: try "2022-08-19T20:01:04Z".date, mediaType: .video)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date, mediaType: .image),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date, mediaType: .image)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date, mediaType: .video),
            expectedCoverNode,
            NodeEntity(name: "c.mp4", handle: 5, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        ]
        let expectedFavouritesCount = (favouritePhotos + favouriteVideos).filter { $0.hasThumbnail && $0.mediaType != nil && $0.isFavourite }.count
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssertTrue(albums.count == 1)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: expectedCoverNode, count: expectedFavouritesCount, type: .favourite))
    }
    
    func testSystemAlbums_onLoad_verifySharedLinkStatusIsUnavailable() async throws {
        let favouriteImage = NodeEntity(handle: 22, hasThumbnail: true, isFavourite: true, mediaType: .image)
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: [favouriteImage]),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository(),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = try await sut.systemAlbums()
        XCTAssertEqual(albums.first?.sharedLinkStatus, .unavailable)
    }
    
    func testUserAlbums_load_retrieveAlbumCoverSetCountShareLinkAndMetaData() async throws {
        let albumId = HandleEntity(1)
        let albumSetCoverId = HandleEntity(3)
        let albumCoverNodeId = HandleEntity(3)
        let expectedAlbumCover = NodeEntity(handle: albumCoverNodeId, mediaType: .image)
        let setEntity = SetEntity(handle: albumId, coverId: albumSetCoverId,
                                  name: "Album 1")
        let albumElement = SetElementEntity(handle: albumSetCoverId, ownerId: albumId,
                                            nodeId: albumCoverNodeId, name: "Test")
        var albumPhotos = try makeAlbumPhotos()
        albumPhotos.append(AlbumPhotoEntity(photo: expectedAlbumCover, albumPhotoId: albumSetCoverId))
    
        let sut = makeAlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: [expectedAlbumCover]),
            userAlbumRepository: MockUserAlbumRepository(albums: [setEntity],
                                                         albumElement: albumElement),
            albumContentsUseCase: MockAlbumContentUseCase(photos: albumPhotos))
        
        let albums = await sut.userAlbums()
        
        XCTAssertEqual(albums, [
            AlbumEntity(id: albumId,
                        name: setEntity.name,
                        coverNode: expectedAlbumCover,
                        count: albumPhotos.count,
                        type: .user,
                        creationTime: setEntity.creationTime,
                        modificationTime: setEntity.modificationTime,
                        sharedLinkStatus: .exported(setEntity.isExported),
                        metaData: AlbumMetaDataEntity(
                            imageCount: albumPhotos.count(for: .image),
                            videoCount: albumPhotos.count(for: .video))
                       )
        ])
    }
    
    func testUserAlbums_loadAlbumWithoutCover_coverIdIsNil() async {
        let expectedAlbums = [
            SetEntity(handle: 1, userId: HandleEntity(2), coverId: HandleEntity.invalid,
                      modificationTime: Date(), name: "Album 1")
        ]
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = await sut.userAlbums()
        XCTAssertEqual(albums.count, expectedAlbums.count)
        XCTAssertNil(albums.first?.coverNode)
    }
    
    func testUserAlbum_withInvalidCoverId_shouldUseLatestModifiedAlbumElementAsCover() async throws {
        let albumId = HandleEntity(1)
        let setEntity = SetEntity(handle: albumId, coverId: HandleEntity.invalid,
                                  modificationTime: Date(), name: "Album 1")
        let expectedAlbumCoverNode = NodeEntity(name: "Test 4.mov", handle: 4,
                                                modificationTime: try "2023-03-01T06:01:04Z".date,
                                                mediaType: .video)
        var albumPhotos = try makeAlbumPhotos()
        albumPhotos.append(AlbumPhotoEntity(photo: expectedAlbumCoverNode))
        let userRepo = MockUserAlbumRepository(albums: [setEntity],
                                               albumElement: nil)
        let sut = makeAlbumListUseCase(
            userAlbumRepository: userRepo,
            albumContentsUseCase: MockAlbumContentUseCase(photos: albumPhotos))
        
        let albums = await sut.userAlbums()
        
        XCTAssertEqual(albums, [
            AlbumEntity(id: albumId,
                        name: setEntity.name,
                        coverNode: expectedAlbumCoverNode,
                        count: albumPhotos.count,
                        type: .user,
                        creationTime: setEntity.creationTime,
                        modificationTime: setEntity.modificationTime,
                        sharedLinkStatus: .exported(setEntity.isExported),
                        metaData: AlbumMetaDataEntity(
                            imageCount: albumPhotos.count(for: .image),
                            videoCount: albumPhotos.count(for: .video))
                       )
        ])
    }
    
    func testUserAlbum_onSetExported_verifySharedLinkStatusExportedIsSetCorrectly() async {
        let albumId = HandleEntity(1)
        let expectedIsExported = true
        let expectedAlbums = [
            SetEntity(handle: albumId, isExported: expectedIsExported)
        ]
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums),
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        let albums = await sut.userAlbums()
        XCTAssertEqual(albums.first?.sharedLinkStatus, .exported(expectedIsExported))
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
        let albumName = "Custom Album"
        let userAlbumRepository = MockUserAlbumRepository(
            createAlbumResult: .success(SetEntity(name: albumName)))
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(photoNodes: favouritePhotos, videoNodes: favouriteVideos),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: userAlbumRepository,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        
        let result = try await sut.createUserAlbum(with: albumName)
        XCTAssertEqual(result.name, albumName)
        XCTAssertNotNil(result.modificationTime)
    }
    
    func testHasNoPhotosAndVideos_whenCreatingAlbumInFreshNewAccount_shouldReturnEmpty() async throws {
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository(
                photoNodes: [
                    NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
                    NodeEntity(name: "1.png", handle: 1, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
                ]
            ),
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        
        let hasNoPhotosAndVideos = await sut.hasNoPhotosAndVideos()
        XCTAssertTrue(hasNoPhotosAndVideos)
    }
    
    func testAlbumsUpdatedPublisher_onAlbumReload_shouldEmitToPublisher() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let albumContentRepo = MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = AlbumListUseCase(
            fileSearchRepository: MockFilesSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: MockUserAlbumRepository.newRepo,
            albumContentsUpdateRepository: albumContentRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        
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
            fileSearchRepository: MockFilesSearchRepository.newRepo,
            mediaUseCase: MockMediaUseCase(),
            userAlbumRepository: userRepo,
            albumContentsUpdateRepository: MockAlbumContentsUpdateNotifierRepository.newRepo,
            albumContentsUseCase: MockAlbumContentUseCase())
        
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
        setElementsUpdatedPublisher.send([SetElementEntity(handle: 1, ownerId: 2, order: 1, nodeId: 1,
                                                           modificationTime: Date(), name: "Test")])
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeAlbumListUseCase(
        fileSearchRepository: some FilesSearchRepositoryProtocol = MockFilesSearchRepository(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        albumContentsUpdateRepository: some AlbumContentsUpdateNotifierRepositoryProtocol = MockAlbumContentsUpdateNotifierRepository(),
        albumContentsUseCase: some AlbumContentsUseCaseProtocol = MockAlbumContentUseCase()
    ) -> some AlbumListUseCaseProtocol {
        AlbumListUseCase(fileSearchRepository: fileSearchRepository,
                         mediaUseCase: mediaUseCase,
                         userAlbumRepository: userAlbumRepository,
                         albumContentsUpdateRepository: albumContentsUpdateRepository,
                         albumContentsUseCase: albumContentsUseCase)
    }
    
    private func makeAlbumPhotos() throws -> [AlbumPhotoEntity] {
        [AlbumPhotoEntity(photo: NodeEntity(name: "Test 1.jpg", handle: 1,
                                            modificationTime: try "2022-08-18T22:01:04Z".date,
                                            mediaType: .image)),
         AlbumPhotoEntity(photo: NodeEntity(name: "Test 2.mp4", handle: 2,
                                            modificationTime: try "2022-08-18T22:01:04Z".date,
                                            mediaType: .video)),
         AlbumPhotoEntity(photo: NodeEntity(name: "Test 3.png", handle: 3,
                                            modificationTime: try "2022-08-18T22:01:04Z".date,
                                            mediaType: .image))
        ]
    }
}

private extension Sequence where Element == AlbumPhotoEntity {
    func count(for mediaType: MediaTypeEntity) -> Int {
        filter({ $0.photo.mediaType == mediaType }).count
    }
}
