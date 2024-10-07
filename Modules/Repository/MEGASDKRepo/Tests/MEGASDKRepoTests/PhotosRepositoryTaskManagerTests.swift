import Combine
import MEGADomain
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class PhotosRepositoryTaskManagerTests: XCTestCase {
    
    func testLoadAllPhotos_multipleCalls_ensureThatOperationIsCalledOnlyOnce() async throws {
        let localSource = MockPhotoLocalSource()
        let sut = makeSUT(photoLocalSource: localSource)
        let expected = [NodeEntity(handle: 43)]
        
        let loadPhotos: @Sendable () async throws -> [NodeEntity] = {
            return try await sut.loadAllPhotos {
                try await Task.sleep(nanoseconds: 100_000_000)
                return expected
            }
        }
        async let photosOne = loadPhotos()
        async let photosTwo = loadPhotos()
        
        let result = try await photosOne + photosTwo
        
        XCTAssertEqual(Set(result), Set(expected))
        
        let cached = await localSource.photos
        XCTAssertEqual(cached, expected)
        let setPhotosCalledCount = await localSource.setPhotosCalledCount
        XCTAssertEqual(setPhotosCalledCount, 1)
    }
    
    func testStartBackgroundMonitoring_onMultipleCalls_ShouldStartUpMonitoringOnlyOnce() async {
        let repositoryMonitor = MockPhotoCacheRepositoryMonitors()
        let sut = makeSUT(photoCacheRepositoryMonitors: repositoryMonitor)
        
        let exp = expectation(description: "monitor started")
        let subscription = Publishers.Zip(repositoryMonitor.monitorCacheInvalidationTriggersCountSubject,
                                           repositoryMonitor.monitorPhotoNodeUpdatesCountSubject)
            .dropFirst()
            .sink { (cacheInvalidationTriggersCount, photoNodeUpdatesCount) in
                XCTAssertEqual(cacheInvalidationTriggersCount, 1)
                XCTAssertEqual(photoNodeUpdatesCount, 1)
                exp.fulfill()
            }
        
        await sut.startBackgroundMonitoring()
        await sut.startBackgroundMonitoring()
        
        await fulfillment(of: [exp], timeout: 1)
        subscription.cancel()
    }
    
    func testStopMonitoring_onActiveMontoring_shouldStopMonitoringAndHaveNoBackgroundTasksRunning() async throws {
        let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
        let repositoryMonitor = MockPhotoCacheRepositoryMonitors(monitorPhotoNodeUpdates: stream.eraseToAnyAsyncSequence(),
                                                                 monitorCacheInvalidationTriggers: stream.eraseToAnyAsyncSequence())
        let sut = makeSUT(photoCacheRepositoryMonitors: repositoryMonitor)
        
        await sut.startBackgroundMonitoring()
        
        // Wait for background monitoring to start its own task
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let didChildTaskStopAfterMonitor = await sut.didMonitoringTaskStop()
        XCTAssertFalse(didChildTaskStopAfterMonitor)
        
        await sut.stopBackgroundMonitoring()
        let didChildTaskStopAfterStopping = await sut.didMonitoringTaskStop()
        XCTAssertTrue(didChildTaskStopAfterStopping)
        continuation.finish()
    }
    
    func testUpdateAsyncSequencesSource_photoUpdatedYields_shouldMatchResults() async {
        let updatedNodes = [NodeEntity(name: "photo.jpg", handle: 1)]
        let photoUpdateSequence = SingleItemAsyncSequence(item: updatedNodes)
            .eraseToAnyAsyncSequence()
        let repositoryMonitor = MockPhotoCacheRepositoryMonitors(photosUpdatedAsyncSequence: photoUpdateSequence)
        let sut = makeSUT(photoCacheRepositoryMonitors: repositoryMonitor)
        
        var iterator = await sut.photosUpdatedAsyncSequence.makeAsyncIterator()
        
        let yieldedNodes = await iterator.next()
        
        XCTAssertEqual(yieldedNodes, updatedNodes)
    }
    
    private func makeSUT(
        photoLocalSource: some PhotoLocalSourceProtocol = MockPhotoLocalSource(),
        photoCacheRepositoryMonitors: some PhotoCacheRepositoryMonitorsProtocol = MockPhotoCacheRepositoryMonitors(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> PhotosRepositoryTaskManager {
        let sut = PhotosRepositoryTaskManager(photoLocalSource: photoLocalSource,
                                              photoCacheRepositoryMonitors: photoCacheRepositoryMonitors)
        addTeardownBlock { [weak sut] in
            // Add sleep to give actor time to deinit. Could not see any retain cycles in instruments or when debugging deinit
            try await Task.sleep(nanoseconds: 100_000_000)
            
            XCTAssertNil(sut, "PhotosRepositoryTaskManager should have been deallocated, potential memory leak.", file: file, line: line)
        }
        return sut
    }
}
