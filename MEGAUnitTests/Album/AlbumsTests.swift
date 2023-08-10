@testable import MEGA
import MEGAPermissions
import MEGAPermissionsMock
import Photos
import XCTest

final class AlbumsTests: XCTestCase {
    class MockPhotoLibrary: PhotoLibraryProviding {
        
        var registerCallCount = 0
        func register(_ observer: PHPhotoLibraryChangeObserver) {
            registerCallCount += 1
        }
        
        var unregisterCallCount = 0
        func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver) {
            unregisterCallCount += 1
        }
        
        var fetchAssetsCallCount = 0
        func fetchAssets(
            in assetCollection: PHAssetCollection,
            options: PHFetchOptions?
        ) -> PHFetchResult<PHAsset> {
            fetchAssetsCallCount += 1
            return MockPHFetchResult()
        }
        
        func enumerateCollection(
            collection: PHFetchResult<PHAssetCollection>,
            block: @escaping (PHAssetCollection) -> Void
        ) {
            block(MockPHAssetCollection())
        }
        
        class MockPHAssetCollection: PHAssetCollection {
            override var localizedTitle: String? {
                "some non nil string"
            }
        }
        
        class MockPHFetchResult: PHFetchResult<PHAsset> {
            override var count: Int { 1 }
            
            override func object(at index: Int) -> PHAsset {
                PHAsset()
            }
        }
    }
    
    class Harness {
        
        let mockPermissionHandler = MockDevicePermissionHandler()
        let mockPhotoLibrary = MockPhotoLibrary()
        let sut: Albums
        
        init(
            _ photoAuthorization: PHAuthorizationStatus
        ) {
            
            mockPermissionHandler.photoLibraryAuthorizationStatus = photoAuthorization
            
            sut = Albums(
                permissionHandler: mockPermissionHandler,
                photoLibraryRegisterer: mockPhotoLibrary
            )
        }
    }
    
    func testAlbums_ifPermissionAuthorized_loadsData() {
        let harness = Harness(.authorized)
        XCTAssertTrue(harness.mockPhotoLibrary.fetchAssetsCallCount > 0)
    }
    
    func testAlbums_ifPermissionLimited_loadsData() {
        let harness = Harness(.limited)
        XCTAssertTrue(harness.mockPhotoLibrary.fetchAssetsCallCount > 0)
    }
    
    func testAlbums_ifPermissionDenied_doesNotLoadData() {
        let harness = Harness(.denied)
        XCTAssertEqual(harness.mockPhotoLibrary.fetchAssetsCallCount, 0)
    }
    
    func testAlbums_ifPermissionRestricted_doesNotLoadData() {
        let harness = Harness(.restricted)
        XCTAssertEqual(harness.mockPhotoLibrary.fetchAssetsCallCount, 0)
    }
    
    func testAlbums_ifPermissionNotDetermined_doesNotLoadData() {
        let harness = Harness(.notDetermined)
        XCTAssertEqual(harness.mockPhotoLibrary.fetchAssetsCallCount, 0)
    }
    
    func testAlbums_whenCreatedAndAuthorized_registersForChanges() {
        let harness = Harness(.authorized)
        XCTAssertEqual(harness.mockPhotoLibrary.registerCallCount, 1)
    }
    
    func testAlbums_whenDestroyedAndAuthorized_unregistersForChanges() {
        var harness: Harness? = Harness(.authorized)
        let mockPhotoLibrary = harness?.mockPhotoLibrary
        harness = nil
        XCTAssertEqual(mockPhotoLibrary?.unregisterCallCount, 1)
    }
}
