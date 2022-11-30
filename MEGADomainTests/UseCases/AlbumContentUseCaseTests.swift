import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA

final class AlbumContentUseCaseTests: XCTestCase {

    private var albumContentUseCase: AlbumContentsUseCaseProtocol {
        AlbumContentsUseCase(
            albumContentsRepo: MockAlbumContentsUpdateNotifierRepository(sdk: MockSdk()),
            favouriteRepo: MockFavouriteNodesRepository.newRepo,
            photoUseCase: MockPhotoLibraryUseCase(allPhotos: [], allPhotosFromCloudDriveOnly: [], allPhotosFromCameraUpload: []),
            mediaUseCase: MockMediaUseCase(isGifImage: true),
            fileSearchRepo: MockFileSearchRepository(nodes: [
                NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
                NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: true)
            ])
        )
    }
    
    func testNodes_whenUserVisitAlbumContentScreen_shouldReturnTwoGifNode() async throws {
        let sut = albumContentUseCase
        let nodesForGifAlbum = try await sut.nodes(forAlbum: AlbumEntity(id: 1, name: "GIFs", coverNode: NodeEntity(handle: 1), count: 2, type: .gif))
     
        XCTAssert(nodesForGifAlbum.count == 2)
    }

}
