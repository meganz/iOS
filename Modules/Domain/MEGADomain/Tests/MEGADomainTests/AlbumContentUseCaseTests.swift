import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class AlbumContentUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_shouldReturnGifNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample3.gif", handle: 7, hasThumbnail: false),
            NodeEntity(name: "test.raw", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 5, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 6, hasThumbnail: true),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true)
        ]
        let gifNodes = nodes.filter { $0.name.contains(".gif") && $0.hasThumbnail }
        
        let sut = makeSUT(
            mediaUseCase: MockMediaUseCase(gifImageFiles: gifNodes.map(\.name)),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: nodes))
        
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif))
        let expectedResult = gifNodes.filter { $0.hasThumbnail }.map { AlbumPhotoEntity(photo: $0) }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_shouldReturnRawNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true)
        ]
        let rawImageNodes = nodes.filter { $0.name.contains(".raw") && $0.hasThumbnail }
        
        let sut = makeSUT(
            mediaUseCase: MockMediaUseCase(rawImageFiles: rawImageNodes.map(\.name)),
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: nodes))
        
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 1, type: .raw))
        let expectedResult = rawImageNodes.filter { $0.hasThumbnail }.map { AlbumPhotoEntity(photo: $0) }
        XCTAssertEqual(result, expectedResult)
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_onlyFavouritesAreReturned() async throws {
        let expectedPhotoNode = NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, isFavourite: true)
        let expectedVideoNode = NodeEntity(name: "test.mp4", handle: 1, hasThumbnail: true, isFavourite: true)
        let photoNodes = [
            expectedPhotoNode,
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "sample3.gif", handle: 2, hasThumbnail: false)
        ]
        let videoNodes = [
            NodeEntity(name: "test-2.mp4", handle: 2, hasThumbnail: true),
            expectedVideoNode,
            NodeEntity(name: "test-3.mp4", handle: 2, hasThumbnail: false)
        ]
        
        let sut = makeSUT(
            photoLibraryUseCase: MockPhotoLibraryUseCase(allPhotos: photoNodes + videoNodes)
        )
        
        let result = try await sut.photos(in: AlbumEntity(id: 1, name: "Fav", coverNode: NodeEntity(handle: 2), count: 1, type: .favourite))
        XCTAssertEqual(result, [AlbumPhotoEntity(photo: expectedPhotoNode),
                                AlbumPhotoEntity(photo: expectedVideoNode)])
    }
    
    func testPhotosForAlbum_onThumbnailPhotosReturned_onlyUserAlbumContentsShouldReturn() async throws {
        let photoHandle1 = HandleEntity(1)
        let photoHandle2 = HandleEntity(2)
        let name1 = "sample1.png"
        let name2 = "sample2.mp4"
        let albumId = HandleEntity(1)
        let albumName = "New Album"
        
        let set = SetEntity(handle: albumId, userId: 1, coverId: photoHandle1, modificationTime: Date(), name: albumName)
        
        let albumPhotoId1 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 45, nodeId: photoHandle1)
        let albumPhotoId2 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 23, nodeId: photoHandle2)
        
        let album = AlbumEntity(id: albumId, name: albumName, coverNode: NodeEntity(handle: 1), count: 1, type: .user)
        let node1 = NodeEntity(name: name1, handle: photoHandle1, hasThumbnail: true)
        let node2 = NodeEntity(name: name2, handle: photoHandle2, hasThumbnail: true)
        
        let userAlbumRepo = MockUserAlbumRepository(albums: [set],
                                                    albumElementIds: [albumId: [albumPhotoId1, albumPhotoId2]])
        
        let sut = makeSUT(
            fileSearchRepo: MockFilesSearchRepository(nodesForHandle: [1: [node1, node2]]),
            userAlbumRepo: userAlbumRepo
        )
        
        let result = try await sut.photos(in: album)
        
        XCTAssertEqual(Set(result), Set([
            AlbumPhotoEntity(photo: node1, albumPhotoId: albumPhotoId1.id),
            AlbumPhotoEntity(photo: node2, albumPhotoId: albumPhotoId2.id)
        ]))
    }
    
    func testPhotosForAlbum_forUserAlbumShowHiddenNodes_shouldShowAllNodes() async throws {
        let albumId: HandleEntity = 5
        let hiddenNodeHandle = HandleEntity(1)
        let visibleNodeHandle = HandleEntity(2)
        let inheritHiddenNodeHandle = HandleEntity(3)
        
        let albumPhotoId1 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 5, nodeId: hiddenNodeHandle)
        let albumPhotoId2 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 8, nodeId: visibleNodeHandle)
        let albumPhotoId3 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 12, nodeId: inheritHiddenNodeHandle)
        
        let hiddenNode = NodeEntity(name: "hide.jpg", handle: hiddenNodeHandle, isMarkedSensitive: true)
        let visibleNode = NodeEntity(name: "vis.jpg", handle: visibleNodeHandle, isMarkedSensitive: false)
        let hiddenInheritNode = NodeEntity(name: "hide_inherit.jpg", handle: inheritHiddenNodeHandle, isMarkedSensitive: false)
        
        let allPhotos = Set([
            AlbumPhotoEntity(photo: visibleNode, albumPhotoId: albumPhotoId2.id),
            AlbumPhotoEntity(photo: hiddenNode, albumPhotoId: albumPhotoId1.id),
            AlbumPhotoEntity(photo: hiddenInheritNode, albumPhotoId: albumPhotoId3.id)
        ])
        let nonSensitivePhotos = Set([
            AlbumPhotoEntity(photo: visibleNode, albumPhotoId: albumPhotoId2.id)
        ])
        let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [
            visibleNodeHandle: .success(false),
            inheritHiddenNodeHandle: .success(true)
        ]
    
        let testCase = [(excludeSensitive: false, expectedResult: allPhotos),
                        (excludeSensitive: true, expectedResult: nonSensitivePhotos)]
        
        let userAlbumRepo = MockUserAlbumRepository(albumElementIds: [albumId: [albumPhotoId1, albumPhotoId2, albumPhotoId3]])
        let userAlbum = AlbumEntity(id: albumId, name: "", coverNode: nil, count: 0, type: .user)
        let fileSearchRepo = MockFilesSearchRepository(nodesForHandle: [1: [hiddenNode, visibleNode, hiddenInheritNode]])
        for (excludeSensitive, expectedResult) in testCase {
            let sensitiveDisplayPreferenceUseCase = MockSensitiveDisplayPreferenceUseCase(
                excludeSensitives: excludeSensitive)
            let sut = makeSUT(
                fileSearchRepo: fileSearchRepo,
                userAlbumRepo: userAlbumRepo,
                sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
                sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                    isInheritingSensitivityResults: isInheritingSensitivityResults)
            )
            
            let result = try await sut.photos(in: userAlbum)
            XCTAssertEqual(Set(result), expectedResult, "Incorrect result for excludeSensitive: \(excludeSensitive)")
        }
    }
    
    func testAlbumReloadPublisher_onNonUserAlbum_shouldOnlyReloadOnAlbumReloadPublisher() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let setElementsUpdatedPublisher = PassthroughSubject<[SetElementEntity], Never>()
        
        let sut = makeSUT(
            albumContentsRepo: MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher()),
            userAlbumRepo: MockUserAlbumRepository(setElementsUpdatedPublisher: setElementsUpdatedPublisher.eraseToAnyPublisher())
        )
        
        let favouriteAlbum = AlbumEntity(id: 1, name: "Favourites", coverNode: nil,
                                         count: 1, type: .favourite)
        let exp = expectation(description: "Should reload once")
        sut.albumReloadPublisher(forAlbum: favouriteAlbum)
            .sink { _ in
                exp.fulfill()
            }.store(in: &subscriptions)
        
        albumReloadPublisher.send()
        setElementsUpdatedPublisher.send([SetElementEntity(handle: 1, ownerId: favouriteAlbum.id,
                                                           order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testAlbumReloadPublisher_onUserAlbum_shouldReloadOnAlbumReloadPublisherAndSetElementsUpdated() {
        let albumReloadPublisher = PassthroughSubject<Void, Never>()
        let setElementsUpdatedPublisher = PassthroughSubject<[SetElementEntity], Never>()
        
        let sut = makeSUT(
            albumContentsRepo: MockAlbumContentsUpdateNotifierRepository(albumReloadPublisher: albumReloadPublisher.eraseToAnyPublisher()),
            userAlbumRepo: MockUserAlbumRepository(setElementsUpdatedPublisher: setElementsUpdatedPublisher.eraseToAnyPublisher())
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
        setElementsUpdatedPublisher.send([])
        setElementsUpdatedPublisher.send([SetElementEntity(handle: 1, ownerId: 2, order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        setElementsUpdatedPublisher.send([SetElementEntity(handle: 2, ownerId: albumId, order: 1, nodeId: 1, modificationTime: Date(), name: "")])
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testUserAlbumPhotos_excludeSensitiveFalse_shouldReturnAllAlbumPhotos() async {
        let albumId: HandleEntity = 5
        let handle1 = HandleEntity(1)
        let handle2 = HandleEntity(2)
        
        let albumPhotoId1 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 5, nodeId: handle1)
        let albumPhotoId2 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 8, nodeId: handle2)
        
        let imageNode =  NodeEntity(name: "Test.jpg", handle: handle1)
        let videoNode =   NodeEntity(name: "Test.mp4", handle: handle2)
        let userAlbumRepo = MockUserAlbumRepository(albumElementIds: [albumId: [albumPhotoId1, albumPhotoId2]])
        
        let sut = makeSUT(
            fileSearchRepo: MockFilesSearchRepository(nodesForHandle: [1: [imageNode, videoNode]]),
            userAlbumRepo: userAlbumRepo
        )
        
        let expectedResult: Set = [
            AlbumPhotoEntity(photo: imageNode, albumPhotoId: albumPhotoId1.id),
            AlbumPhotoEntity(photo: videoNode, albumPhotoId: albumPhotoId2.id)
        ]
        
        let result = await sut.userAlbumPhotos(by: albumId, excludeSensitive: false)
        XCTAssertEqual(Set(result), expectedResult)
    }
    
    func testUserAlbumPhotos_excludeSensitiveTrue_shouldReturnAllNodesThatsNotMarkedSensitive() async {
        let albumId: HandleEntity = 5
        let hiddenNodeHandle = HandleEntity(1)
        let visibleNodeHandle = HandleEntity(2)
        let inheritHiddenNodeHandle = HandleEntity(3)
        
        let albumPhotoId1 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 5, nodeId: hiddenNodeHandle)
        let albumPhotoId2 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 8, nodeId: visibleNodeHandle)
        let albumPhotoId3 = AlbumPhotoIdEntity(albumId: albumId, albumPhotoId: 12, nodeId: inheritHiddenNodeHandle)
        
        let hiddenNode = NodeEntity(name: "hide.jpg", handle: hiddenNodeHandle, isMarkedSensitive: true)
        let visibleNode = NodeEntity(name: "vis.jpg", handle: visibleNodeHandle, isMarkedSensitive: false)
        let hiddenInheritNode = NodeEntity(name: "hide_inherit.jpg", handle: inheritHiddenNodeHandle, isMarkedSensitive: false)
        let userAlbumRepo = MockUserAlbumRepository(albumElementIds: [albumId: [albumPhotoId1, albumPhotoId2, albumPhotoId3]])
        
        let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [
            visibleNodeHandle: .success(false),
            inheritHiddenNodeHandle: .success(true)
        ]
        
        let sut = makeSUT(
            fileSearchRepo: MockFilesSearchRepository(nodesForHandle: [1: [hiddenNode, visibleNode, hiddenInheritNode]]),
            userAlbumRepo: userAlbumRepo,
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(
                isInheritingSensitivityResults: isInheritingSensitivityResults)
        )
        
        let result = await sut.userAlbumPhotos(by: albumId, excludeSensitive: true)
        
        XCTAssertEqual(result, [
            AlbumPhotoEntity(photo: visibleNode, albumPhotoId: albumPhotoId2.id)
        ])
    }
    
    func testUserAlbumUpdatedPublisher_onNonUserAlbum_shouldReturnNil() throws {
        let sut = makeSUT()
        
        let nonUserAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                       count: 1, type: .favourite)
        
        XCTAssertNil(sut.userAlbumUpdatedPublisher(for: nonUserAlbum))
    }
    
    func testUserAlbumUpdatedPublisher_onSetChangedForUserAlbum_shouldReturnSetElement() throws {
        let albumId = HandleEntity(65)
        
        let setsUpdatedPublisher = PassthroughSubject<[SetEntity], Never>()
        let sut = makeSUT(
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
        let sut = makeSUT()
        
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: HandleEntity(2))
        
        XCTAssertNil(coverPhoto)
    }
    
    func testUserAlbumCoverPhoto_onUserAlbumElementFound_shouldReturnNode() async {
        let albumId = HandleEntity(25)
        let photoId = HandleEntity(42)
        let expectedCoverPhoto = NodeEntity(name: "test.jpg", handle: 15)
        let coverSetElement = SetElementEntity(handle: photoId, ownerId: albumId,
                                               order: 1, nodeId: expectedCoverPhoto.handle)
        
        let sut = makeSUT(
            fileSearchRepo: MockFilesSearchRepository(nodesForHandle: [1: [expectedCoverPhoto]]),
            userAlbumRepo: MockUserAlbumRepository(albumElement: coverSetElement)
        )
        
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: photoId)
        XCTAssertEqual(coverPhoto, expectedCoverPhoto)
    }
    
    func testUserAlbumCoverPhoto_onUserAlbumElementFoundWithNoVisualMedia_shouldReturnNil() async {
        let albumId = HandleEntity(25)
        let photoId = HandleEntity(42)
        let photo = NodeEntity(name: "test.txt", handle: 15)
        let coverSetElement = SetElementEntity(handle: photoId, ownerId: albumId,
                                               order: 1, nodeId: photo.handle)
        
        let sut = makeSUT(
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [photo]),
            userAlbumRepo: MockUserAlbumRepository(albumElement: coverSetElement)
        )
        
        let userAlbum = AlbumEntity(id: 1, name: "Test", coverNode: nil,
                                    count: 1, type: .user)
        let coverPhoto = await sut.userAlbumCoverPhoto(in: userAlbum, forPhotoId: photoId)
        
        XCTAssertNil(coverPhoto)
    }
    
    // MARK: - Private
    
    private func makeSUT(
        albumContentsRepo: some AlbumContentsUpdateNotifierRepositoryProtocol = MockAlbumContentsUpdateNotifierRepository(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        fileSearchRepo: some FilesSearchRepositoryProtocol = MockFilesSearchRepository(),
        userAlbumRepo: some UserAlbumRepositoryProtocol = MockUserAlbumRepository(),
        sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol = MockSensitiveDisplayPreferenceUseCase(),
        photoLibraryUseCase: some PhotoLibraryUseCaseProtocol = MockPhotoLibraryUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> AlbumContentsUseCase {
        AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: mediaUseCase,
            fileSearchRepo: fileSearchRepo,
            userAlbumRepo: userAlbumRepo,
            sensitiveDisplayPreferenceUseCase: sensitiveDisplayPreferenceUseCase,
            photoLibraryUseCase: photoLibraryUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase)
    }
}
