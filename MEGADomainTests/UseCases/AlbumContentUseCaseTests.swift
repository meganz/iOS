import XCTest
import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class AlbumContentUseCaseTests: XCTestCase {
    private let albumContentsRepo = MockAlbumContentsUpdateNotifierRepository(sdk: MockSdk())
    private let favouriteRepo = MockFavouriteNodesRepository.newRepo
    private let photoUseCase = MockPhotoLibraryUseCase(allPhotos: [], allPhotosFromCloudDriveOnly: [], allPhotosFromCameraUpload: [])
    
    private var subscriptions = Set<AnyCancellable>()
    
    func testNodesForAlbum_onThumbnailPhotosReturned_shouldReturnGifNodes() async throws {
        let expectedNodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true)
        ]
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            favouriteRepo: favouriteRepo,
            photoUseCase: photoUseCase,
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            fileSearchRepo: MockFileSearchRepository(photoNodes: expectedNodes)
        )
        let nodesForGifAlbum = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif))
        XCTAssertEqual(nodesForGifAlbum, expectedNodes)
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_shouldReturnRawNodes() async throws {
        let expectedNodes = [
            NodeEntity(name: "sample1.raw", handle: 1, hasThumbnail: true),
        ]
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            favouriteRepo: favouriteRepo,
            photoUseCase: photoUseCase,
            mediaUseCase: MockMediaUseCase(isRawImage: true),
            fileSearchRepo: MockFileSearchRepository(photoNodes: expectedNodes)
        )
        let result = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "RAW", coverNode: NodeEntity(handle: 1), count: 1, type: .raw))
        XCTAssertEqual(result, expectedNodes)
    }
    
    func testNodesForAlbum_onThumbnailPhotosReturned_onlyFavouritesAreReturned() async throws {
        let expectedPhotoNode = NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true, isFavourite: true)
        let expectedVideoNode = NodeEntity(name: "test.mp4", handle: 1, hasThumbnail: true, isFavourite: true)
        
        let sut = AlbumContentsUseCase(
            albumContentsRepo: albumContentsRepo,
            favouriteRepo: favouriteRepo,
            photoUseCase: photoUseCase,
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
