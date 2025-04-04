import Combine
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGASwift
import XCTest

final class AlbumCacheMonitorTaskManagerTests: XCTestCase {

    func testStartMonitoring_onCalled_ShouldStartUpMonitoring() async {
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors()
        let sut = makeSUT(repositoryMonitor: repositoryMonitor)
        
        let exp = expectation(description: "monitor started")
        let subscription = Publishers.Zip3(repositoryMonitor.monitorSetUpdatesCountSubject,
                                           repositoryMonitor.monitorSetElementUpdatesCountSubject,
                                           repositoryMonitor.monitorCacheInvalidationTriggersCountSubject)
            .dropFirst()
            .sink { (setUpdatesCount, setElementUpdatesCount, cacheInvalidationTriggersCount) in
                XCTAssertEqual(setUpdatesCount, 1)
                XCTAssertEqual(setElementUpdatesCount, 1)
                XCTAssertEqual(cacheInvalidationTriggersCount, 1)
                exp.fulfill()
            }
        
        await sut.startMonitoring()
        
        await fulfillment(of: [exp], timeout: 1)
        subscription.cancel()
    }
    
    func testStopMonitoring_taskStarted_shouldReturnFalseForChildTask() async {
        let repositoryMonitor = MockUserAlbumCacheRepositoryMonitors()
        let sut = makeSUT(repositoryMonitor: repositoryMonitor)
        
        await sut.startMonitoring()
        
        let didChildTaskStop = await sut.didChildTaskStop()
        XCTAssertFalse(didChildTaskStop)
        
        await sut.stopMonitoring()
        
        let didChildTaskStopAfterMonitoringStop = await sut.didChildTaskStop()
        XCTAssertTrue(didChildTaskStopAfterMonitoringStop)
    }

    private func makeSUT(
        repositoryMonitor: some UserAlbumCacheRepositoryMonitorsProtocol = MockUserAlbumCacheRepositoryMonitors(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> AlbumCacheMonitorTaskManager {
        let sut = AlbumCacheMonitorTaskManager(repositoryMonitor: repositoryMonitor)
        addTeardownBlock { [weak sut] in
            // Add sleep to give actor time to deinit. Could not see any retain cycles in instruments or when debugging deinit
            try await Task.sleep(nanoseconds: 100_000_000)
            
            XCTAssertNil(sut, "AlbumCacheMonitorTaskManager should have been deallocated, potential memory leak.", file: file, line: line)
        }
        return sut
    }
}
