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
    
    func testLatestModifiedPhoto_excludeSensitives_shouldReturnLatestPhotoThatsNotMarkedSensitive() throws {
        let expectedPhoto = NodeEntity(handle: 2, modificationTime: try "2024-05-01T22:01:04Z".date)
        let photos =  [AlbumPhotoEntity(photo: NodeEntity(handle: 3, isMarkedSensitive: true, modificationTime: try "2024-05-02T10:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 6, isMarkedSensitive: true, modificationTime: try "2024-05-02T12:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 1, modificationTime: try "2024-05-02T14:01:04Z".date), isSensitiveInherited: true),
                       AlbumPhotoEntity(photo: expectedPhoto),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 4, isMarkedSensitive: true, modificationTime: try "2024-04-20T10:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 3, modificationTime: try "2024-04-02T10:01:04Z".date))]
        
        let latestModifiedPhoto = photos.latestModifiedPhoto(excludeSensitives: true)
        
        XCTAssertEqual(latestModifiedPhoto, expectedPhoto)
    }
    
    func testLatestModifiedPhoto_excludeSensitivesAllPhotosHidden_shouldReturnNil() throws {
        let photos =  [AlbumPhotoEntity(photo: NodeEntity(handle: 3, isMarkedSensitive: true, modificationTime: try "2024-05-02T10:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 6, isMarkedSensitive: true, modificationTime: try "2024-05-02T12:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 1, modificationTime: try "2024-05-02T14:01:04Z".date), isSensitiveInherited: true),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 2, modificationTime: try "2024-05-01T22:01:04Z".date), isSensitiveInherited: true),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 4, isMarkedSensitive: true, modificationTime: try "2024-04-20T10:01:04Z".date)),
                       AlbumPhotoEntity(photo: NodeEntity(handle: 3, modificationTime: try "2024-04-02T10:01:04Z".date), isSensitiveInherited: true)]
        
        let latestModifiedPhoto = photos.latestModifiedPhoto(excludeSensitives: true)
        
        XCTAssertNil(latestModifiedPhoto)
    }
}
