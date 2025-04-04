import MEGAAppSDKRepoMock
import XCTest

final class AlbumPhotoIdEntity_Mapper_swift_Tests: XCTestCase {
    func testToAlbumPhotoIdEntity_mapsCorrectly() {
        let setElement = MockMEGASetElement(handle: 5, ownerId: 10, order: 1, nodeId: 54,
                                            name: "value", changeType: .new, modificationTime: Date())
        
        let result = setElement.toAlbumPhotoIdEntity()
        
        XCTAssertEqual(result.albumId, setElement.ownerId)
        XCTAssertEqual(result.id, setElement.handle)
        XCTAssertEqual(result.nodeId, setElement.nodeId)
    }
}
