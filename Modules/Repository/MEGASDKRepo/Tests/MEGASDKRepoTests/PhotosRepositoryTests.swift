import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class PhotosRepositoryTests: XCTestCase {
    
    func testAllPhotos_monitoringStopped_shouldRetrievePhotosThroughSearch() async throws {
        let expectedPhotos = [MockNode(handle: 45),
                              MockNode(handle: 65)]
        let localSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = PhotosRepositoryTaskManager(photoLocalSource: localSource,
                                                                      photoCacheRepositoryMonitors: MockPhotoCacheRepositoryMonitors())
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: localSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos(excludeSensitive: false)
        
        XCTAssertEqual(Set(photos), Set(expectedPhotos.toNodeEntities()))
        XCTAssertEqual(sdk.searchWithFilterCallCount, 2)
    }
    
    func testAllPhotos_monitoringDidNotStopPhotoSourceEmpty_shouldRetrievePhotosThroughSearch() async throws {
        let expectedPhotos = [NodeEntity(handle: 45),
                              NodeEntity(handle: 65)]
        let localSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: false,
            loadPhotosResult: .success(expectedPhotos))
        
        let sut = makeSUT(photoLocalSource: localSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos(excludeSensitive: false)
        
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
    }
    
    func testAllPhotosExludeSensitive_photoSourceEmpty_shouldRetrievePhotosAndReturnNonSensitive() async throws {
        let nonSensitivePhoto = NodeEntity(handle: 43, isMarkedSensitive: false)
        let inheritSensitivePhoto = NodeEntity(handle: 543, isMarkedSensitive: true)
        let allPhotos = [
            nonSensitivePhoto,
            NodeEntity(handle: 57, isMarkedSensitive: true),
            inheritSensitivePhoto
        ]
        let localSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: false,
            loadPhotosResult: .success(allPhotos))
        
        let sut = makeSUT(photoLocalSource: localSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos(excludeSensitive: true)
        
        XCTAssertEqual(photos, [nonSensitivePhoto])
    }
    
    func testAllPhotos_photoSourceContainsPhotos_shouldRetrievePhotos() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)
        ]
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false)
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos(excludeSensitive: false)
        
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
    }
    
    func testAllPhotosExludingSensitives_photoSourceContainsSensitivePhotos_shouldRetrunNonSensitivePhotos() async throws {
        let nonSensitivePhoto = NodeEntity(handle: 43, isMarkedSensitive: false)
        let inheritSensitivePhoto = MockNode(handle: 543, isMarkedSensitive: true)
        let allPhotos = [
            nonSensitivePhoto,
            NodeEntity(handle: 57, isMarkedSensitive: true),
            inheritSensitivePhoto.toNodeEntity()
        ]
        let sdk = MockSdk(
            nodes: [inheritSensitivePhoto],
            nodesInheritingSensitivity: [inheritSensitivePhoto.handle: true])
        let photoLocalSource = MockPhotoLocalSource(photos: allPhotos)
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false)
        let sut = makeSUT(
            sdk: sdk,
            photoLocalSource: photoLocalSource,
            photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos(excludeSensitive: true)
        
        XCTAssertEqual(photos, [nonSensitivePhoto])
    }
    
    func testPhotoForHandle_photoSourceDontContainPhoto_shouldRetrieveAndSetPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle, isMarkedSensitive: false)
        let photoLocalSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: false,
            loadPhotosResult: .success([expectedNode]))
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photo = await sut.photo(forHandle: handle, excludeSensitive: false)
        
        XCTAssertEqual(photo, expectedNode)
    }
    
    func testPhotoForHandle_SDKCantGetNode_shouldReturnNil() async {
        let photoLocalSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false)
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photo = await sut.photo(forHandle: 6, excludeSensitive: false)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_photoSourceContainPhoto_shouldReturnPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode,
                                                             NodeEntity(handle: 7)])
        
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false))
        
        let photo = await sut.photo(forHandle: handle, excludeSensitive: false)
        
        XCTAssertEqual(photo, expectedNode)
    }
    
    func testPhotoForHandleExcludeSensitive_photoSourceContainsSensitivePhoto_shouldReturnNil() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle, isMarkedSensitive: true)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode,
                                                             NodeEntity(handle: 7)])
        
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: MockPhotosRepositoryTaskManager(
                            didMonitoringTaskStop: false))
        
        let photo = await sut.photo(forHandle: handle, excludeSensitive: true)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandleExcludeSensitive_photoSourceContainsInheritedSensitivePhoto_shouldReturnNil() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle, isMarkedSensitive: true)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode,
                                                             NodeEntity(handle: 7)])
        let sdk = MockSdk(
            nodes: [MockNode(handle: handle)],
            nodesInheritingSensitivity: [handle: true])
        let sut = makeSUT(
            sdk: sdk,
            photoLocalSource: photoLocalSource,
            photosRepositoryTaskManager: MockPhotosRepositoryTaskManager(
                didMonitoringTaskStop: false))
        
        let photo = await sut.photo(forHandle: handle, excludeSensitive: true)
        
        XCTAssertNil(photo)
    }
    
    func testPhotosUpdate_onPhotoUpdateYield_shouldYieldTheUpdatedPhotos() async {
        let expectedNodes = [NodeEntity(name: "photo.jpg", handle: 1)]
        let photoUpdateSequence = SingleItemAsyncSequence(item: expectedNodes)
            .eraseToAnyAsyncSequence()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: false,
            photosUpdatedAsyncSequence: photoUpdateSequence)
        let sut = makeSUT(photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        var iterator = await sut.photosUpdated().makeAsyncIterator()
        
        let updatedNodes = await iterator.next()
        
        XCTAssertEqual(updatedNodes, expectedNodes)
    }
    
    func testPhotosUpdated_onCacheForcedClearedMonitoringStopped_shouldRePrimeCacheAndClearFlag() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)]
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: true,
            loadPhotosResult: .success(expectedPhotos))
        let photoLocalSource = MockPhotoLocalSource(wasForcedCleared: true)
        let sut = makeSUT(
            photoLocalSource: photoLocalSource,
            photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let result = try await sut.allPhotos(excludeSensitive: false)
        
        XCTAssertEqual(Set(result), Set(expectedPhotos))
        
        let wasForcedCleared = await photoLocalSource.wasForcedCleared
        XCTAssertFalse(wasForcedCleared)
    }
    
    func testPhotosUpdated_onCacheForcedClearedMonitoringNotStopped_shouldPrimeCacheOnce() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)]
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(
            didMonitoringTaskStop: false,
            loadPhotosResult: .success(expectedPhotos))
        let photoLocalSource = MockPhotoLocalSource(wasForcedCleared: true)
        let sut = makeSUT(
            photoLocalSource: photoLocalSource,
            photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let result = try await sut.allPhotos(excludeSensitive: false)
        XCTAssertEqual(Set(result), Set(expectedPhotos))
        
        let wasForcedCleared = await photoLocalSource.wasForcedCleared
        XCTAssertFalse(wasForcedCleared)
    }
    
    private func makeSUT(sdk: MEGASdk = MockSdk(),
                         photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource(),
                         photosRepositoryTaskManager: some PhotosRepositoryTaskManagerProtocol = MockPhotosRepositoryTaskManager()
    ) -> PhotosRepository {
        PhotosRepository(sdk: sdk,
                         photoLocalSource: photoLocalSource,
                         photosRepositoryTaskManager: photosRepositoryTaskManager)
    }
}
