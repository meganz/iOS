import MEGASDKRepo
import MEGASDKRepoMock
import Network
import XCTest

final class NetworkMonitorRepositoryTests: XCTestCase {
    private func makeSUT(
        pathStatus: NetworkPathStatus = .satisfied,
        availableInterfaces: [NetworkInterface] = []
    ) -> (NetworkMonitorRepository, MockNetworkMonitor) {
        let mockPath = MockPath(
            status: pathStatus,
            availableInterfaces: availableInterfaces
        )
        let mockMonitor = MockNetworkMonitor(currentPath: mockPath)
        let sut = NetworkMonitorRepository(monitor: mockMonitor)
        
        trackForMemoryLeaks(on: sut)
        return (sut, mockMonitor)
    }

    func testInit_withDefaultMonitor_startsMonitoring() {
        let (_, mockMonitor) = makeSUT()
        mockMonitor.start()
        XCTAssertTrue(mockMonitor.isStarted, "Monitor should start monitoring on initialization.")
    }
    
    func testCancel_whenCalled_stopsMonitoring() {
        let (_, mockMonitor) = makeSUT()
        mockMonitor.start()
        
        XCTAssertTrue(mockMonitor.isStarted, "Monitor should start monitoring on initialization.")
        
        mockMonitor.cancel()
        
        XCTAssertFalse(mockMonitor.isStarted, "Monitor should stop monitoring after cancellation.")
    }
    
    func testConnectionChangedStream_whenStatusChangesToSatisfied_emitsTrue() async throws {
        let (sut, mockMonitor) = makeSUT(pathStatus: .unsatisfied)
        mockMonitor.start()
        let stream = sut.connectionSequence
        let expectation = self.expectation(description: "Stream emits 'true' when connection becomes satisfied.")
        
        Task {
            for await isConnected in stream where isConnected {
                XCTAssertTrue(isConnected, "Stream should emit 'true' when connection becomes satisfied.")
                mockMonitor.cancel()
                expectation.fulfill()
                break
            }
        }
        
        mockMonitor.simulatePathUpdate(
            newPath: MockPath(
                status: .satisfied,
                availableInterfaces: [MockNetworkInterface(type: .wifi)]
            )
        )
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsConnected_whenPathStatusIsSatisfied_returnsTrue() {
        let (sut, _) = makeSUT(pathStatus: .satisfied)
        let isConnected = sut.isConnected()
        
        XCTAssertTrue(isConnected, "isConnected() should return true when path status is satisfied.")
    }
    
    func testIsConnected_whenPathStatusIsUnsatisfied_returnsFalse() {
        let (sut, _) = makeSUT(pathStatus: .unsatisfied)
        let isConnected = sut.isConnected()

        XCTAssertFalse(isConnected, "isConnected() should return false when path status is unsatisfied.")
    }
    
    func testIsConnectedViaWiFi_whenUsingWiFiInterface_returnsTrue() {
        let wifiInterface = MockNetworkInterface(type: .wifi)
        let (sut, _) = makeSUT(availableInterfaces: [wifiInterface])
        let isConnectedViaWiFi = sut.isConnectedViaWiFi()
        
        XCTAssertTrue(isConnectedViaWiFi, "isConnectedViaWiFi() should return true when using WiFi interface.")
    }
    
    func testIsConnectedViaWiFi_whenNotUsingWiFiInterface_returnsFalse() {
        let cellularInterface = MockNetworkInterface(type: .cellular)
        let (sut, _) = makeSUT(availableInterfaces: [cellularInterface])
        let isConnectedViaWiFi = sut.isConnectedViaWiFi()
        
        XCTAssertFalse(isConnectedViaWiFi, "isConnectedViaWiFi() should return false when not using WiFi interface.")
    }
}
