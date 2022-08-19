
import XCTest
import MEGADomain
import MEGADomainMock

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
}
