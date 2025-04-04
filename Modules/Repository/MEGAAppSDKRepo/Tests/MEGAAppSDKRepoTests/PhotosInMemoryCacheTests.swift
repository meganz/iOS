@testable import MEGAAppSDKRepo
import MEGADomain
import XCTest

final class PhotosInMemoryCacheTests: XCTestCase {

    override func tearDown() async throws {
        try await super.tearDown()
        await PhotosInMemoryCache.shared.removeAllPhotos(forced: false)
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
    
    func testRemoveAllPhotos_onCachedPhotosForcedClear_shouldRemoveAllValuesAndSetFlagToStateProvided() async {
        let photos = [NodeEntity(handle: 8),
                      NodeEntity(handle: 5)
        ]
        await withTaskGroup(of: Void.self) { taskGroup in
            [true, false].forEach { forceCleared in
                taskGroup.addTask {
                    let sut = PhotosInMemoryCache.shared
                    await sut.setPhotos(photos)
                    
                    await sut.removeAllPhotos(forced: forceCleared)
                    
                    let cachedPhotos = await sut.photos
                    XCTAssertTrue(cachedPhotos.isEmpty)
                    
                    let wasForcedCleared = await sut.wasForcedCleared
                    XCTAssertEqual(wasForcedCleared, wasForcedCleared)
                }
            }
        }
    }
    
    func testClearForcedFlag_onForcedCleared_shouldResetFlag() async {
        let sut = PhotosInMemoryCache.shared
        await sut.removeAllPhotos(forced: true)
        let ensureWasForcedCleared = await sut.wasForcedCleared
        XCTAssertTrue(ensureWasForcedCleared)
        
        await sut.clearForcedFlag()
        
        let result = await sut.wasForcedCleared
        XCTAssertFalse(result)
    }
}
