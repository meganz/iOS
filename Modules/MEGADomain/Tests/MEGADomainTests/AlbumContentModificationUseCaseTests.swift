import XCTest
import MEGADomain
import MEGADomainMock

final class AlbumContentModificationUseCaseTests: XCTestCase {
    func testAddPhotosToAlbum_onAlbumCreated_shouldReturnPhotosAddedToAlbum() async throws {
        let sut = AlbumContentModificationUseCase(userAlbumRepo: MockUserAlbumRepository.newRepo)
        
        let nodes = [
            NodeEntity(name: "sample1.gif", handle: 1, hasThumbnail: true),
            NodeEntity(name: "sample2.gif", handle: 2, hasThumbnail: false)
        ]
        
        let result = try await sut.addPhotosToAlbum(by: 1, nodes: nodes)
        XCTAssert(result.success == nodes.count)
    }
}
