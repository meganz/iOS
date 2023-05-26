import XCTest
import Combine
import MEGADomain
import MEGADomainMock

final class AlbumContentUseCaseTests: XCTestCase {
    private let albumContentsRepo = MockAlbumContentsUpdateNotifierRepository()
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_shouldReturnGifNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "sample3.gif", handle: 7, hasThumbnail: false, mediaType: .image),
            NodeEntity(name: "test.raw", handle: 3, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test3.png", handle: 5, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test3.mp4", handle: 6, hasThumbnail: true, mediaType: .video),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true, mediaType: .image)
        ]
        let gifNodes = nodes.filter { $0.name.contains(".gif") }
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(gifImageFiles: gifNodes.map(\.name),
                                           allPhotos: nodes),
            fileSearchRepo: MockFilesSearchRepository.newRepo,
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif))
        let expectedResult = gifNodes.filter { $0.hasThumbnail }.map { AlbumPhotoEntity(photo: $0) }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_shouldReturnRawNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false, mediaType: .image),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true, mediaType: .video)
        ]
        let rawImageNodes = nodes.filter { $0.name.contains(".raw") }
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(rawImageFiles: rawImageNodes.map(\.name),
                                           allPhotos: nodes),
            fileSearchRepo: MockFilesSearchRepository.newRepo,
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 1, type: .raw))
        let expectedResult = rawImageNodes.filter { $0.hasThumbnail }.map { AlbumPhotoEntity(photo: $0) }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_onlyFavouritesAreReturned() async throws {
        let expectedPhotoNode = NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, isFavourite: true, mediaType: .image)
        let expectedVideoNode = NodeEntity(name: "test.mp4", handle: 1, hasThumbnail: true, isFavourite: true, mediaType: .video)
        let photoNodes = [
            expectedPhotoNode,
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true, mediaType: .image),
            NodeEntity(name: "sample3.gif", handle: 2, hasThumbnail: false, mediaType: .image)
        ]
        let videoNodes = [
            NodeEntity(name: "test-2.mp4", handle: 2, hasThumbnail: true, mediaType: .video),
            expectedVideoNode,
            NodeEntity(name: "test-3.mp4", handle: 2, hasThumbnail: false, mediaType: .video)
        ]
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(allPhotos: photoNodes,
                                           allVideos: videoNodes),
            fileSearchRepo: MockFilesSearchRepository.newRepo,
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "Fav", coverNode: NodeEntity(handle: 2), count: 1, type: .favourite))
        XCTAssertEqual(result, [AlbumPhotoEntity(photo: expectedPhotoNode),
                                AlbumPhotoEntity(photo: expectedVideoNode)])
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_onlyUserAlbumContentsShouldReturn() async throws {
        let handle1 = HandleEntity(1)
        let handle2 = HandleEntity(2)
        let name1 = "sample1.png"
        let name2 = "sample2.mp4"
        let albumId = HandleEntity(1)
        let albumName = "New Album"
        
        let set = SetEntity(handle: albumId, userId: 1, coverId: handle1, modificationTime: Date(), name: albumName)
        let element1 = SetElementEntity(handle: handle1, ownerId: albumId, order: 1, nodeId: handle1, modificationTime: Date(), name: name1)
        let element2 = SetElementEntity(handle: handle2, ownerId: albumId, order: 2, nodeId: handle2, modificationTime: Date(), name: name2)
        
        let album = AlbumEntity(id: albumId, name: albumName, coverNode: NodeEntity(handle: 1), count: 1, type: .user)
        let node1 = NodeEntity(name: name1, handle: handle1, hasThumbnail: true, mediaType: .image)
        let node2 = NodeEntity(name: name2, handle: handle2, hasThumbnail: true, mediaType: .video)
        
        let userAlbumRepo = MockUserAlbumRepository(albums: [set], albumContent: [1 : [element1, element2]])
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [node1, node2]),
            userAlbumRepo: userAlbumRepo
        )
        
        let result = try await sut.photos(in: album)
            .sorted(by: { $0.albumPhotoId ?? .invalid < $1.albumPhotoId ?? .invalid })
        XCTAssertEqual(result, [
            AlbumPhotoEntity(photo: node1, albumPhotoId: handle1),
            AlbumPhotoEntity(photo: node2, albumPhotoId: handle2)
        ])
    }
    
    func testAlbumReloadPublisher_onNonUserAlbum_shouldOnlyReloadOnAlbumReloadPublisher() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let setElemetsUpdatedPublisher = PassthroughSubject<[SetElementEntity], Never>()
        let sut = AlbumContentsUseCase(
            albumContentsRepo: MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher()),
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository.newRepo,
            userAlbumRepo: MockUserAlbumRepository(setElemetsUpdatedPublisher: setElemetsUpdatedPublisher.eraseToAnyPublisher())
        )
        let favouriteAlbum = AlbumEntity(id: 1, name: "Favourites", coverNode: nil,
                                    count: 1, type: .favourite)
        let exp = expectation(description: "Should reload once")
        sut.albumReloadPublisher(forAlbum: favouriteAlbum)
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumReloadPublisher.send()
        setElemetsUpdatedPublisher.send([SetElementEntity(handle: 1, ownerId: favouriteAlbum.id,
                                                          order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAlbumReloadPublisher_onUserAlbum_shouldReloadOnAlbumReloadPublisherAndSetElementsUpdated() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let setElemetsUpdatedPublisher = PassthroughSubject<[SetElementEntity], Never>()
        let sut = AlbumContentsUseCase(
            albumContentsRepo: MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher()),
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository.newRepo,
            userAlbumRepo: MockUserAlbumRepository(setElemetsUpdatedPublisher: setElemetsUpdatedPublisher.eraseToAnyPublisher())
        )
        let albumId = HandleEntity(6)
        let userAlbum = AlbumEntity(id: albumId, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let exp = expectation(description: "Should reload twice")
        exp.expectedFulfillmentCount = 2
        
        sut.albumReloadPublisher(forAlbum: userAlbum)
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumReloadPublisher.send()
        setElemetsUpdatedPublisher.send([])
        setElemetsUpdatedPublisher.send([SetElementEntity(handle: 1, ownerId: 2, order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        setElemetsUpdatedPublisher.send([SetElementEntity(handle: 2, ownerId: albumId, order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUserAlbumPhotos_onAlbumContentLoaded_shouldReturnNodes() async {
        let albumId: HandleEntity = 5
        let handle1 = HandleEntity(1)
        let handle2 = HandleEntity(2)
        let element1 = SetElementEntity(handle: handle1, ownerId: albumId,
                                        order: 1, nodeId: handle1, modificationTime: Date(), name: "")
        let element2 = SetElementEntity(handle: handle2, ownerId: albumId,
                                        order: 2, nodeId: handle2, modificationTime: Date(), name: "")
        let setElements = [element1, element2]
        let imageNode =  NodeEntity(name: "Test.jpg", handle: handle1, mediaType: .image)
        let videoNode =   NodeEntity(name: "Test.mp4", handle: handle2, mediaType: .video)
        let userAlbumRepo = MockUserAlbumRepository(albumContent: [albumId: setElements])
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [imageNode, videoNode]),
            userAlbumRepo: userAlbumRepo
        )
        let expectedResult = [
            AlbumPhotoEntity(photo: imageNode, albumPhotoId: element1.id),
            AlbumPhotoEntity(photo: videoNode, albumPhotoId: element2.id)
        ]
        let result = await sut.userAlbumPhotos(by: albumId)
            .sorted(by: { $0.albumPhotoId ?? .invalid < $1.albumPhotoId ?? .invalid })
        XCTAssertEqual(result, expectedResult)
    }
    
    func testUserAlbumUpdatedPublisher_onNonUserAlbum_shouldReturnNil() throws {
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(),
            userAlbumRepo: MockUserAlbumRepository()
        )
        let nonUserAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                       count: 1, type: .favourite)
        XCTAssertNil(sut.userAlbumUpdatedPublisher(for: nonUserAlbum))
    }
    
    func testUserAlbumUpdatedPublisher_onSetChangedForUserAlbum_shouldReturnSetElement() throws {
        let albumId = HandleEntity(65)
        
        let setsUpdatedPublisher = PassthroughSubject<[SetEntity], Never>()
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(),
            userAlbumRepo: MockUserAlbumRepository(setsUpdatedPublisher: setsUpdatedPublisher.eraseToAnyPublisher())
        )
        let userAlbum = AlbumEntity(id: albumId, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        
        let expectedSetUpdate = SetEntity(handle: albumId, changeTypes: .name)
        
        let exp = expectation(description: "Update received")
        try XCTUnwrap(sut.userAlbumUpdatedPublisher(for: userAlbum))
            .sink {
                XCTAssertEqual($0, expectedSetUpdate)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        setsUpdatedPublisher.send([])
        setsUpdatedPublisher.send([SetEntity(handle: 5)])
        setsUpdatedPublisher.send([expectedSetUpdate])
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUserAlbumCoverPhoto_onAlbumElementNotFound_shouldReturnNil() async {
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(),
            userAlbumRepo: MockUserAlbumRepository()
        )
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: HandleEntity(2))
        XCTAssertNil(coverPhoto)
    }
    
    func testUserAlbumCoverPhoto_onUserAlbumElementFound_shouldReturnNode() async {
        let albumId = HandleEntity(25)
        let photoId = HandleEntity(42)
        let expectedCoverPhoto = NodeEntity(handle: 15, mediaType: .image)
        let coverSetElement = SetElementEntity(handle: photoId, ownerId: albumId,
                                               order: 1, nodeId: expectedCoverPhoto.handle, modificationTime: Date(), name: "")
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [expectedCoverPhoto]),
            userAlbumRepo: MockUserAlbumRepository(albumElement: coverSetElement)
        )
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: photoId)
        XCTAssertEqual(coverPhoto, expectedCoverPhoto)
    }
    
    func testUserAlbumCoverPhoto_onUserAlbumElementFoundWithNoMediaType_shouldReturnNil() async {
        let albumId = HandleEntity(25)
        let photoId = HandleEntity(42)
        let expectedCoverPhoto = NodeEntity(handle: 15)
        let coverSetElement = SetElementEntity(handle: photoId, ownerId: albumId,
                                               order: 1, nodeId: expectedCoverPhoto.handle, modificationTime: Date(), name: "")
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [expectedCoverPhoto]),
            userAlbumRepo: MockUserAlbumRepository(albumElement: coverSetElement)
        )
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: photoId)
        XCTAssertNil(coverPhoto)
    }
}
