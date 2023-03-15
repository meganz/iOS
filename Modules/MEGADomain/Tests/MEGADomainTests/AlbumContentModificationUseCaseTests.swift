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
    
    func testRename_onAlbumRename_shouldReturnNewName() async throws {
        let sut = AlbumContentModificationUseCase(userAlbumRepo: MockUserAlbumRepository.newRepo)
        
        let newName = try await sut.rename(album: HandleEntity(1), with: "Hey There")

        XCTAssertEqual(newName, "Hey There")
    }
    
    func testUpdateAlbumCover_onAlbumCoverUpdate_shouldReturnUpdatedCoverNode() async throws {
        
        let setElem1 = SetElementEntity(handle: HandleEntity(1), ownerId: HandleEntity(1), order: HandleEntity(1), nodeId: HandleEntity(1), modificationTime: Date.distantPast, name: "1")
        let setElem2 = SetElementEntity(handle: HandleEntity(2), ownerId: HandleEntity(2), order: HandleEntity(2), nodeId: HandleEntity(2), modificationTime: Date.distantPast, name: "2")
        
        let albumContents: [HandleEntity: [SetElementEntity]] = [
            HandleEntity(1): [setElem1, setElem2]
        ]
        
        let sut = AlbumContentModificationUseCase(userAlbumRepo: MockUserAlbumRepository(albumContent: albumContents))
        
        let nodeId = try await sut.updateAlbumCover(album: HandleEntity(1), withNode: HandleEntity(2))

        XCTAssertEqual(nodeId, HandleEntity(2))
    }
}
