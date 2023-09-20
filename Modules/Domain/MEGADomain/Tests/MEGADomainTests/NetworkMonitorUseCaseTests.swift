import MEGADomain
import MEGADomainMock
import XCTest

final class NetworkMonitorUseCaseTests: XCTestCase {

    func testNetworkIsConnected() {
        let repo = MockNetworkMonitorRepository(connected: true)
        let sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertTrue(result)
        }
    }
    
    func testNetworkIsNotConnected() {
        let repo = MockNetworkMonitorRepository(connected: false)
        let sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertFalse(result)
        }
    }
    
    func testNetworkChangedFromNotConnectedToConnected() {
        var repo = MockNetworkMonitorRepository(connected: false)
        var sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertFalse(result)
        }
        repo.connected = true
        sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertTrue(result)
        }
    }
    
    func testNetworkChangedFromConnectedToNotConnected() {
        var repo = MockNetworkMonitorRepository(connected: true)
        var sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertTrue(result)
        }
        repo.connected = false
        sut = NetworkMonitorUseCase(repo: repo)
        sut.networkPathChanged { result in
            XCTAssertFalse(result)
        }
    }
    
    func testConnectionChangedStream_onNetworkChanges_shouldChange() async {
        var expectedResults = [true, false, true]
        let connectionChanged = AsyncStream { continuation in
            for expectedResult in expectedResults {
                continuation.yield(expectedResult)
            }
            continuation.finish()
        }
        let networkMonitorRepository = MockNetworkMonitorRepository(connectionChangedStream: connectionChanged)
        let sut = NetworkMonitorUseCase(repo: networkMonitorRepository)
        
        for await isConnected in sut.connectionChangedStream {
            XCTAssertEqual(isConnected, expectedResults.removeFirst())
        }
    }
}
