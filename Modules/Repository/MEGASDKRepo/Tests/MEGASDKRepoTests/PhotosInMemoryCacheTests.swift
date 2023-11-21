import MEGADomain
@testable import MEGASDKRepo
import XCTest

final class PhotosInMemoryCacheTests: XCTestCase {

    override func tearDown() async throws {
        try await super.tearDown()
        await PhotosInMemoryCache.shared.removeAllPhotos()
    }
    
    func testPhotos_photosSet_shouldRetrieve() async {
        let photos = [NodeEntity(handle: 1),
                      NodeEntity(handle: 2)
        ]
        
        let sut = PhotosInMemoryCache.shared
        await sut.setPhotos(photos)
        
        let result = await sut.photos
        
        XCTAssertEqual(Set(result), Set(photos))
    }
    
    func testPhotoForHandle_photoCached_shouldRetrieveCachedPhoto() async {
        let photoHandle = HandleEntity(32)
        let expectedPhoto = NodeEntity(handle: photoHandle)
        let photos = [NodeEntity(handle: 87),
                      expectedPhoto
        ]
        
        let sut = PhotosInMemoryCache.shared
        await sut.setPhotos(photos)
        
        let cachedPhoto = await sut.photo(forHandle: photoHandle)
        
        XCTAssertEqual(cachedPhoto, expectedPhoto)
    }
    
    func testRemovePhotoForHandle_photoCached_shouldReturnNil() async {
        let photoHandle = HandleEntity(22)
        let photos = [NodeEntity(handle: 76),
                      NodeEntity(handle: photoHandle)
        ]
        
        let sut = PhotosInMemoryCache.shared
        await sut.setPhotos(photos)
        
        await sut.removePhoto(forHandle: photoHandle)
        
        let cachedPhoto = await sut.photo(forHandle: photoHandle)
        XCTAssertNil(cachedPhoto)
    }
    
    func testRemoveAllPhotos_onCachedPhotos_shouldRemoveAllValues() async {
        let photos = [NodeEntity(handle: 8),
                      NodeEntity(handle: 5)
        ]
        
        let sut = PhotosInMemoryCache.shared
        await sut.setPhotos(photos)
        
        await sut.removeAllPhotos()
        
        let cachedPhotos = await sut.photos
        XCTAssertTrue(cachedPhotos.isEmpty)
    }
}
