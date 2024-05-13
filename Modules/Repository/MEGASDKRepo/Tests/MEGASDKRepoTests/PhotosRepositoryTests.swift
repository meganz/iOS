import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class PhotosRepositoryTests: XCTestCase {
    func testAllPhotos_rootNodeNotFound_shouldThrowError() async {
        let photosRepositoryTaskManager = PhotosRepositoryTaskManager(photoLocalSource: MockPhotoLocalSource(),
                                                                      photoCacheRepositoryMonitors: MockPhotoCacheRepositoryMonitors())
        let sut = makeSUT(photosRepositoryTaskManager: photosRepositoryTaskManager)
        do {
            _ = try await sut.allPhotos()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertEqual(error as? NodeErrorEntity, NodeErrorEntity.nodeNotFound)
        }
    }
    
    func testAllPhotos_photoSourceEmpty_shouldRetrievePhotosThroughSearch() async throws {
        let expectedPhotos = [MockNode(handle: 45),
                              MockNode(handle: 65)]
        let photosRepositoryTaskManager = PhotosRepositoryTaskManager(photoLocalSource: MockPhotoLocalSource(),
                                                                      photoCacheRepositoryMonitors: MockPhotoCacheRepositoryMonitors())
        let sdk = MockSdk(nodes: expectedPhotos,
                          megaRootNode: MockNode(handle: 1))
        let sut = makeSUT(sdk: sdk,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos.toNodeEntities()))
    }
    
    func testAllPhotos_photoSourceContainsPhotos_shouldRetrievePhotos() async throws {
        let expectedPhotos = [NodeEntity(handle: 43),
                              NodeEntity(handle: 99)
        ]
        let photoLocalSource = MockPhotoLocalSource(photos: expectedPhotos)
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false)
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photos = try await sut.allPhotos()
        XCTAssertEqual(Set(photos), Set(expectedPhotos))
    }
    
    func testPhotoForHandle_photoSourceDontContainPhoto_shouldRetrieveAndSetPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = MockNode(handle: handle)
        let sdk = MockSdk(nodes: [expectedNode])
        let photoLocalSource = MockPhotoLocalSource()
        let photosRepositoryTaskManager = MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false)
        let sut = makeSUT(sdk: sdk,
                          photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: photosRepositoryTaskManager)
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode.toNodeEntity())
        let photoSourcePhotos = await photoLocalSource.photos
        XCTAssertEqual(photoSourcePhotos, [expectedNode.toNodeEntity()])
    }
    
    func testPhotoForHandle_SDKCantGetNode_shouldReturnNil() async {
        let sut = makeSUT()
        
        let photo = await sut.photo(forHandle: 6)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_nodeInRubbish_shouldReturnNil() async {
        let sdk = MockSdk(rubbishNodes: [MockNode(handle: 6)])
        let sut = makeSUT(sdk: sdk)
        
        let photo = await sut.photo(forHandle: 6)
        
        XCTAssertNil(photo)
    }
    
    func testPhotoForHandle_photoSourceContainPhoto_shouldReturnPhoto() async {
        let handle = HandleEntity(5)
        let expectedNode = NodeEntity(handle: handle)
        let photoLocalSource = MockPhotoLocalSource(photos: [expectedNode,
                                                             NodeEntity(handle: 7)])
        
        let sut = makeSUT(photoLocalSource: photoLocalSource,
                          photosRepositoryTaskManager: MockPhotosRepositoryTaskManager(didMonitoringTaskStop: false))
        
        let photo = await sut.photo(forHandle: handle)
        
        XCTAssertEqual(photo, expectedNode)
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
        
        let result = try await sut.allPhotos()
        
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
        
        let result = try await sut.allPhotos()
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
