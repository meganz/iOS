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
        
        func loadAlbums(completion: @escaping () -> Void) {
            sut.loadAlbums(completion: completion)
        }
    }
    
    func testAlbums_ifPermissionAuthorized_loadsData() {
        // given
        let expectation = expectation(description: #function)
        let harness = Harness(.authorized)
        
        // when
        harness.loadAlbums {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        
        // then
        XCTAssertTrue(harness.mockPhotoLibrary.fetchAssetsCallCount > 0)
    }
    
    func testAlbums_ifPermissionLimited_loadsData() {
        // given
        let expectation = expectation(description: #function)
        let harness = Harness(.limited)
        
        // when
        harness.loadAlbums {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        
        // then
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
        // given
        let expectation = expectation(description: #function)
        let harness = Harness(.authorized)
        
        // when
        harness.loadAlbums {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
        
        // then
        XCTAssertEqual(harness.mockPhotoLibrary.registerCallCount, 1)
    }
    
    func testAlbums_whenDestroyedAndAuthorized_unregistersForChanges() {
        // given
        let expectation = expectation(description: #function)
        var harness: Harness? = Harness(.authorized)
        let mockPhotoLibrary = harness?.mockPhotoLibrary
        
        // when
        harness?.loadAlbums {
            harness = nil
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        
        // then
        XCTAssertEqual(mockPhotoLibrary?.unregisterCallCount, 1)
    }
}
