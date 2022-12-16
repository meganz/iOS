import XCTest
import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGA

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
            fileSearchRepo: MockFileSearchRepository(photoNodes: nodes)
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
            fileSearchRepo: MockFileSearchRepository(photoNodes: nodes)
        )
        let result = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 1, type: .raw))
        XCTAssertEqual(result,  rawImageNodes.filter { $0.hasThumbnail })
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_onlyFavouritesAreReturned() async throws {
        let expectedPhotoNode = NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, isFavourite: true)
        let expectedVideoNode = NodeEntity(name: "test.mp4", handle: 1, hasThumbnail: true, isFavourite: true)
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            fileSearchRepo: MockFileSearchRepository(photoNodes: [
                expectedPhotoNode,
                NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true),
                NodeEntity(name: "sample3.gif", handle: 2, hasThumbnail: false)
            ], videoNodes: [
                NodeEntity(name: "test-2.mp4", handle: 2, hasThumbnail: true),
                expectedVideoNode,
                NodeEntity(name: "test-3.mp4", handle: 2, hasThumbnail: false)
            ])
        )
        let result = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "Fav", coverNode: NodeEntity(handle: 2), count: 1, type: .favourite))
        XCTAssertEqual(result, [expectedPhotoNode, expectedVideoNode])
    }
}
