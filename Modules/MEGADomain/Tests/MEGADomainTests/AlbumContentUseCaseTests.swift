import XCTest
import Combine
import MEGADomain
import MEGADomainMock

final class AlbumContentUseCaseTests: XCTestCase {
    private let albumContentsRepo = MockAlbumContentsUpdateNotifierRepository()
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testNodesForAlbum_onThumbnailPhotosReturned_shouldReturnGifNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample3.gif", handle: 7, hasThumbnail: false),
            NodeEntity(name: "test.raw", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test2.jpg", handle: 4, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 5, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 6, hasThumbnail: true),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true),
        ]
        let gifNodes = nodes.filter { $0.name.contains(".gif") }
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(gifImageFiles: gifNodes.map(\.name)),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: nodes),
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let nodesForGifAlbum = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif))
        XCTAssertEqual(nodesForGifAlbum, gifNodes.filter { $0.hasThumbnail })
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_shouldReturnRawNodes() async throws {
        let nodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.raw", handle: 6, hasThumbnail: false),
            NodeEntity(name: "test2.jpg", handle: 3, hasThumbnail: true),
            NodeEntity(name: "test3.png", handle: 4, hasThumbnail: true),
            NodeEntity(name: "sample3.raw", handle: 7, hasThumbnail: true),
            NodeEntity(name: "test.gif", handle: 2, hasThumbnail: true),
            NodeEntity(name: "test3.mp4", handle: 5, hasThumbnail: true),
        ]
        let rawImageNodes = nodes.filter { $0.name.contains(".raw") }
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(rawImageFiles: rawImageNodes.map(\.name)),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: nodes),
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let result = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 1, type: .raw))
        XCTAssertEqual(result, rawImageNodes.filter { $0.hasThumbnail })
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_onlyFavouritesAreReturned() async throws {
        let expectedPhotoNode = NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, isFavourite: true)
        let expectedVideoNode = NodeEntity(name: "test.mp4", handle: 1, hasThumbnail: true, isFavourite: true)
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [
                expectedPhotoNode,
                NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true),
                NodeEntity(name: "sample3.gif", handle: 2, hasThumbnail: false)
            ], videoNodes: [
                NodeEntity(name: "test-2.mp4", handle: 2, hasThumbnail: true),
                expectedVideoNode,
                NodeEntity(name: "test-3.mp4", handle: 2, hasThumbnail: false)
            ]),
            userAlbumRepo: MockUserAlbumRepository.newRepo
        )
        let result = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "Fav", coverNode: NodeEntity(handle: 2), count: 1, type: .favourite))
        XCTAssertEqual(result, [expectedPhotoNode, expectedVideoNode])
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_onlyUserAlbumContentsShouldReturn() async throws {
        let handle1 = HandleEntity(1)
        let handle2 = HandleEntity(2)
        let name1 = "sample1.png"
        let name2 = "sample2.png"
        let albumId = HandleEntity(1)
        let albumName = "New Album"
        
        let set = SetEntity(handle: albumId, userId: 1, coverId: handle1, modificationTime: Date(), name: albumName)
        let element1 = SetElementEntity(handle: handle1, order: 1, nodeId: handle1, modificationTime: Date(), name: name1)
        let element2 = SetElementEntity(handle: handle2, order: 2, nodeId: handle2, modificationTime: Date(), name: name2)
        
        let album = AlbumEntity(id: albumId, name: albumName, coverNode: NodeEntity(handle: 1), count: 1, type: .user)
        let node1 = NodeEntity(name: name1, handle: handle1, hasThumbnail: true)
        let node2 = NodeEntity(name: name2, handle: handle2, hasThumbnail: true)
        
        let userAlbumRepo = MockUserAlbumRepository(albums: [set], albumContent: [1 : [element1, element2]])
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            fileSearchRepo: MockFilesSearchRepository(photoNodes: [node1, node2]),
            userAlbumRepo: userAlbumRepo
        )
        
        let result = try await sut.nodes(forAlbum: album)
        XCTAssertEqual(result.count, 2)
    }
}
