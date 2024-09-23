import MEGADomain
import XCTest

final class AlbumPhotoEntity_Additions_Tests: XCTestCase {
    func testLatestModifiedPhoto_excludeSensitivesFalse_shouldReturnLatestPhoto() throws {
        let expectedPhoto = NodeEntity(modificationTime: try "2024-05-03T22:01:04Z".date)
        let photos =  [AlbumPhotoEntity(photo: NodeEntity(modificationTime: try "2024-05-01T22:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(modificationTime: try "2024-05-01T22:01:04Z".date)),
                       AlbumPhotoEntity(photo: expectedPhoto)]
        
        let latestModifiedPhoto = photos.latestModifiedPhoto()
        
        XCTAssertEqual(latestModifiedPhoto, expectedPhoto)
    }
    
    func testLatestModifiedPhotoSameDates_excludeSensitivesFalse_shouldReturnLatestPhotoHandle() throws {
        let expectedPhoto = NodeEntity(handle: 2, modificationTime: try "2024-05-03T22:01:04Z".date)
        let photos =  [AlbumPhotoEntity(photo: NodeEntity(handle: 1, modificationTime: try "2024-05-03T22:01:04Z".date)),
                       AlbumPhotoEntity(photo: expectedPhoto)]
        
        let latestModifiedPhoto = photos.latestModifiedPhoto()
        
        XCTAssertEqual(latestModifiedPhoto, expectedPhoto)
    }
}
