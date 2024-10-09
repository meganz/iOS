import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumListUseCaseTests: XCTestCase {
    private let photos = [
        NodeEntity(name: "1.raw", handle: 1, hasThumbnail: true),
        NodeEntity(name: "2.nef", handle: 2, hasThumbnail: true),
        NodeEntity(name: "3.cr2", handle: 3, hasThumbnail: false),
        NodeEntity(name: "4.dng", handle: 4, hasThumbnail: false),
        NodeEntity(name: "5.gif", handle: 5, hasThumbnail: true)]
    
    private let emptyFavouritesAlbum = AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "", coverNode: nil, count: 0, type: .favourite)
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testSystemAlbums_whenLoadingRawSystemAlbum_shouldReturnFavouriteAndRawAlbumEntity() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: photos),
            mediaUseCase: MockMediaUseCase(isRawImage: true))
        
        let albums = try await sut.systemAlbums()
        
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .raw)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbum_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: photos),
            mediaUseCase: MockMediaUseCase(isGifImage: true))
        
        let albums = try await sut.systemAlbums()
        
        XCTAssert(albums.count == 2)
        XCTAssertEqual(albums.first, emptyFavouritesAlbum)
        XCTAssertEqual(albums.last?.type, .gif)
    }
    
    func testSystemAlbums_whenLoadingGifSystemAlbumMarkedAsFavourite_shouldReturnFavouriteAndGifAlbumEntity() async throws {
        let favouriteGifPhotos = [
            NodeEntity(name: "1.gif", handle: 2, hasThumbnail: true, isFavourite: true, mediaType: .image)
        ]
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: favouriteGifPhotos),
            mediaUseCase: MockMediaUseCase(isGifImage: true))
        
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
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: favouriteRawPhotos),
            mediaUseCase: MockMediaUseCase(isRawImage: true))
        
        let albums = try await sut.systemAlbums()
        
        XCTAssertTrue(albums.count == 2)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: favouriteRawPhotos.last, count: favouriteRawPhotos.count, type: .favourite))
        XCTAssertEqual(albums.last?.type, AlbumEntityType.raw)
    }
    
    func testSystemAlbums_whenLoadingFavouritePhotosAndVideos_shouldFilterThumbnailsAndInvalidMediaTypesThenSelectLatestCover() async throws {
        let expectedCoverNode = NodeEntity(name: "a.mp4", handle: 4, hasThumbnail: true, isFavourite: true,
                                           modificationTime: try "2023-08-19T20:01:04Z".date)
        let favouritePhotos = [
            NodeEntity(name: "0.jpg", handle: 0, hasThumbnail: false, isFavourite: true, modificationTime: try "2022-08-18T22:01:04Z".date),
            NodeEntity(name: "1.png", handle: 1, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        ]
        let favouriteVideos = [
            NodeEntity(name: "b.mp4", handle: 3, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date),
            expectedCoverNode,
            NodeEntity(name: "c.mp4", handle: 5, hasThumbnail: true, isFavourite: true, modificationTime: try "2022-08-19T20:01:04Z".date)
        ]
        let expectedFavouritesCount = (favouritePhotos + favouriteVideos)
            .filter { $0.hasThumbnail && $0.name.fileExtensionGroup.isVisualMedia && $0.isFavourite }.count
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: favouritePhotos + favouriteVideos))
        
        let albums = try await sut.systemAlbums()
        
        XCTAssertTrue(albums.count == 1)
        XCTAssertEqual(albums.first, AlbumEntity(id: AlbumIdEntity.favourite.rawValue, name: "",
                                                 coverNode: expectedCoverNode, count: expectedFavouritesCount, type: .favourite))
    }
    
    func testSystemAlbums_onLoad_verifySharedLinkStatusIsUnavailable() async throws {
        let favouriteImage = NodeEntity(name: "1.jpg", handle: 22, hasThumbnail: true, isFavourite: true)
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [favouriteImage]))
        
        let albums = try await sut.systemAlbums()
        
        XCTAssertEqual(albums.first?.sharedLinkStatus, .unavailable)
    }
    
    func testUserAlbums_load_retrieveAlbumCoverSetCountShareLinkAndMetaData() async throws {
        let albumId = HandleEntity(1)
        let albumSetCoverId = HandleEntity(3)
        let albumCoverNodeId = HandleEntity(3)
        let expectedAlbumCover = NodeEntity(name: "1.jpg", handle: albumCoverNodeId)
        let setEntity = SetEntity(handle: albumId, coverId: albumSetCoverId,
                                  name: "Album 1")
        let albumElement = SetElementEntity(handle: albumSetCoverId, ownerId: albumId,
                                            nodeId: albumCoverNodeId, name: "Test")
        var albumPhotos = try makeAlbumPhotos()
        albumPhotos.append(AlbumPhotoEntity(photo: expectedAlbumCover, albumPhotoId: albumSetCoverId))
        let albumContentsUseCase = MockAlbumContentUseCase(photos: albumPhotos)
        let sut = makeAlbumListUseCase(userAlbumRepository: MockUserAlbumRepository(albums: [setEntity],
                                                         albumElement: albumElement),
            albumContentsUseCase: albumContentsUseCase)
        
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
                            imageCount: albumPhotos.imageCount,
                            videoCount: albumPhotos.videoCount)
                       )
        ])
    }
    
    func testUserAlbums_loadAlbumWithoutCover_coverIdIsNil() async {
        let expectedAlbums = [
            SetEntity(handle: 1, userId: HandleEntity(2), coverId: HandleEntity.invalid,
                      modificationTime: Date(), name: "Album 1")
        ]
        let sut = makeAlbumListUseCase(
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums))
        
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
                            imageCount: albumPhotos.imageCount,
                            videoCount: albumPhotos.videoCount)
                       )
        ])
    }
    
    func testUserAlbum_onSetExported_verifySharedLinkStatusExportedIsSetCorrectly() async {
        let albumId = HandleEntity(1)
        let expectedIsExported = true
        let expectedAlbums = [
            SetEntity(handle: albumId, isExported: expectedIsExported)
        ]
        let sut = makeAlbumListUseCase(
            userAlbumRepository: MockUserAlbumRepository(albums: expectedAlbums))
        
        let albums = await sut.userAlbums()
        
        XCTAssertEqual(albums.first?.sharedLinkStatus, .exported(expectedIsExported))
    }
    
    func testUserAlbums_excludeSensitivesAlbumCoverSet_shouldNotUseHiddenPhotoAsCoverAndCount() async {
        let albumId = HandleEntity(65)
        let albumCoverId = HandleEntity(3)
        let album = SetEntity(handle: albumId, coverId: albumCoverId,
                              name: "Test")
        let coverPhoto = NodeEntity(name: "Test 1.jpg", handle: 1, isMarkedSensitive: true)
        let albumElement = SetElementEntity(handle: albumCoverId, ownerId: albumId,
                                            nodeId: coverPhoto.handle, name: "Test")
        let albumPhotos = [
            AlbumPhotoEntity(photo: coverPhoto, albumPhotoId: albumCoverId)]
        let userAlbumRepository = MockUserAlbumRepository(albums: [album],
                                                          albumElement: albumElement)
        let albumContentUseCase = MockAlbumContentUseCase(photos: albumPhotos)
        let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
            excludeSensitives: true)
        
        let sut = makeAlbumListUseCase(
            userAlbumRepository: userAlbumRepository,
            albumContentsUseCase: albumContentUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase)
        
        let albums = await sut.userAlbums()
        
        XCTAssertEqual(albums, [
            AlbumEntity(id: albumId,
                        name: album.name,
                        coverNode: nil,
                        count: 0,
                        type: .user,
                        creationTime: album.creationTime,
                        modificationTime: album.modificationTime,
                        sharedLinkStatus: .exported(album.isExported),
                        metaData: AlbumMetaDataEntity(
                            imageCount: 0,
                            videoCount: 0)
                       )
        ])
    }
    
    func testUserAlbums_showHiddenItemsFalseAlbumCoverNotSet_shouldNotUseHiddenPhotoAsCoverAndCount() async throws {
        let albumId = HandleEntity(65)
        let album = SetEntity(handle: albumId, name: "Test")
        let photo = NodeEntity(name: "Test 1.jpg", handle: 1, isMarkedSensitive: true)
        var albumPhotos = try makeAlbumPhotos()
        albumPhotos.append(AlbumPhotoEntity(photo: photo))
        
        let userAlbumRepository = MockUserAlbumRepository(albums: [album])
        let albumContentUseCase = MockAlbumContentUseCase(photos: albumPhotos)
        let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
            excludeSensitives: true)
        
        let sut = makeAlbumListUseCase(
            userAlbumRepository: userAlbumRepository,
            albumContentsUseCase: albumContentUseCase,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase)
        
        let albums = await sut.userAlbums()
        
        let albumPhotosWithoutHidden = albumPhotos.filter { !$0.photo.isMarkedSensitive }
        XCTAssertEqual(albums, [
            AlbumEntity(id: albumId,
                        name: album.name,
                        coverNode: albumPhotosWithoutHidden.latestModifiedPhoto(),
                        count: albumPhotosWithoutHidden.count,
                        type: .user,
                        creationTime: album.creationTime,
                        modificationTime: album.modificationTime,
                        sharedLinkStatus: .exported(album.isExported),
                        metaData: AlbumMetaDataEntity(
                            imageCount: albumPhotosWithoutHidden.imageCount,
                            videoCount: albumPhotosWithoutHidden.videoCount)
                       )
        ])
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
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: favouritePhotos + favouriteVideos),
            userAlbumRepository: userAlbumRepository)
        
        let result = try await sut.createUserAlbum(with: albumName)
        
        XCTAssertEqual(result.name, albumName)
        XCTAssertNotNil(result.modificationTime)
    }
    
    func testHasNoPhotosAndVideos_noPhotos_shouldReturnTrue() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: []))
        
        let hasNoPhotosAndVideos = await sut.hasNoVisualMedia()
        
        XCTAssertTrue(hasNoPhotosAndVideos)
    }
    
    func testHasNoVisualMedia_photosWithNoThumbnails_shouldReturnTrue() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [
                NodeEntity(name: "1.jpg", handle: 1, hasThumbnail: false),
                NodeEntity(name: "1.mp4", handle: 2, hasThumbnail: false)]))
        
        let hasNoPhotosAndVideos = await sut.hasNoVisualMedia()
        
        XCTAssertTrue(hasNoPhotosAndVideos)
    }
    
    func testHasNoVisualMedia_containsImageWithThumbnail_shouldReturnFalse() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [
                NodeEntity(name: "0.jpg", handle: 1, hasThumbnail: false),
                NodeEntity(name: "1.png", handle: 2, hasThumbnail: true)]))
        
        let hasNoPhotosAndVideos = await sut.hasNoVisualMedia()
        
        XCTAssertFalse(hasNoPhotosAndVideos)
    }
    
    func testHasNoVisualMedia_onlyVideosWithThumbnail_shouldReturnFalse() async throws {
        let sut = makeAlbumListUseCase(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: [
                NodeEntity(name: "0.mp4", handle: 1, hasThumbnail: false),
                NodeEntity(name: "1.mp4", handle: 2, hasThumbnail: true)]))
        
        let hasNoPhotosAndVideos = await sut.hasNoVisualMedia()
        
        XCTAssertFalse(hasNoPhotosAndVideos)
    }
    
    func testAlbumsUpdatedPublisher_onAlbumReload_shouldEmitToPublisher() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let albumContentRepo = MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher())
        let sut = makeAlbumListUseCase(
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
                                               setElementsUpdatedPublisher: setElementsUpdatedPublisher.eraseToAnyPublisher())
        let sut = makeAlbumListUseCase(
            userAlbumRepository: userRepo)
        
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
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        userAlbumRepository: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        albumContentsUpdateRepository: some AlbumContentsUpdateNotifierRepositoryProtocol = MockAlbumContentsUpdateNotifierRepository(),
        albumContentsUseCase: some AlbumContentsUseCaseProtocol = MockAlbumContentUseCase(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase()
    ) -> some AlbumListUseCaseProtocol {
        AlbumListUseCase(photoLibraryUseCase: photoLibraryUseCase,
                         mediaUseCase: mediaUseCase,
                         userAlbumRepository: userAlbumRepository,
                         albumContentsUpdateRepository: albumContentsUpdateRepository,
                         albumContentsUseCase: albumContentsUseCase,
                         sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase)
    }
    
    private func makeAlbumPhotos() throws -> [AlbumPhotoEntity] {
        [AlbumPhotoEntity(photo: NodeEntity(name: "Test 1.jpg", handle: 1,
                                            modificationTime: try "2022-08-18T22:01:04Z".date)),
         AlbumPhotoEntity(photo: NodeEntity(name: "Test 2.mp4", handle: 2,
                                            modificationTime: try "2022-08-18T22:01:04Z".date)),
         AlbumPhotoEntity(photo: NodeEntity(name: "Test 3.png", handle: 3,
                                            modificationTime: try "2022-08-18T22:01:04Z".date))
        ]
    }
}

private extension Sequence where Element == AlbumPhotoEntity {
    var imageCount: Int {
        filter({ $0.photo.name.fileExtensionGroup.isImage }).count
    }
    
    var videoCount: Int {
        filter({ $0.photo.name.fileExtensionGroup.isVideo }).count
    }
}
