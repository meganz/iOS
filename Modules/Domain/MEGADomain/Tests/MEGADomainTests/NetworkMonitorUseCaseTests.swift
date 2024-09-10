import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class NetworkMonitorUseCaseTests: XCTestCase {
    private func makeSUT(
        connected: Bool = false,
        connectedViaWiFi: Bool = false,
        connectionSequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) -> NetworkMonitorUseCase {
        NetworkMonitorUseCase(
            repo: MockNetworkMonitorRepository(
                connected: connected,
                connectedViaWiFi: connectedViaWiFi,
                connectionSequence: connectionSequence
            )
        )
    }
    
    func testConnectionChangedStream_onNetworkChanges_shouldChange() async {
        let expectedResults = [true, false, true]
        let connectionChanged = AsyncStream<Bool> { continuation in
            for result in expectedResults {
                continuation.yield(result)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()

        let sut = makeSUT(connectionSequence: connectionChanged)
        var receivedResults = [Bool]()

        for await isConnected in sut.connectionSequence {
            receivedResults.append(isConnected)
        }

        XCTAssertEqual(receivedResults, expectedResults, "Connection status should match the expected results.")
    }
    
    func testIsConnected_whenConnected_shouldReturnTrue() {
        let sut = makeSUT(connected: true)
        XCTAssertTrue(sut.isConnected(), "isConnected() should return true when connected.")
    }
    
    func testIsConnected_whenNotConnected_shouldReturnFalse() {
        let sut = makeSUT(connected: false)
        XCTAssertFalse(sut.isConnected(), "isConnected() should return false when not connected.")
    }
    
    func testIsConnectedViaWiFi_whenConnectedViaWiFi_shouldReturnTrue() {
        let sut = makeSUT(connectedViaWiFi: true)
        XCTAssertTrue(sut.isConnectedViaWiFi(), "isConnectedViaWiFi() should return true when connected via WiFi.")
    }
    
    func testIsConnectedViaWiFi_whenNotConnectedViaWiFi_shouldReturnFalse() {
        let sut = makeSUT(connectedViaWiFi: false)
        XCTAssertFalse(sut.isConnectedViaWiFi(), "isConnectedViaWiFi() should return false when not connected via WiFi.")
    }
}
