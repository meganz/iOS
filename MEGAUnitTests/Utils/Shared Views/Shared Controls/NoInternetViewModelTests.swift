import ConcurrencyExtras
@testable import MEGA
import MEGADomainMock
import MEGASwift
import XCTest

final class NoInternetViewModelTests: XCTestCase {
    @MainActor
    private func makeSUT(
        connected: Bool = true,
        connectionSequence: AnyAsyncSequence<Bool> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        networkConnectionStateChanged: ((Bool) -> Void)? = nil
    ) -> NoInternetViewModel {
        NoInternetViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(
                connected: connected,
                connectionSequence: connectionSequence
            ),
            networkConnectionStateChanged: networkConnectionStateChanged
        )
    }

    @MainActor
    func testOnTask_isConnectedAttributeIsTrue_shouldMatch() async {
        let sut = makeSUT(connected: true)
        let task = Task {
            await sut.onTask()
        }

        await Task.yield()
        XCTAssertTrue(sut.isConnected)
        task.cancel()
    }

    @MainActor
    func testOnTask_isConnectedAttributeIsFalse_shouldMatch() async {
        let sut = makeSUT(connected: false)
        let task = Task {
            await sut.onTask()
        }

        await Task.yield()
        XCTAssertFalse(sut.isConnected)
        task.cancel()
    }

    @MainActor
    func testMonitorNetworkChanges_whenStatusChangesToFalse_shouldMatch() async {
        let expectation = self.expectation(description: "Wait for connection state change to false")
        
        let sut = makeSUT(connectionSequence: makeConnectionMonitorStream(statuses: [false]).eraseToAnyAsyncSequence()) {
            if !$0 {
                expectation.fulfill()
            }
        }

        let task = Task {
            await sut.onTask()
        }
        
        await Task.yield()
        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()
    }

    private func makeConnectionMonitorStream(statuses: [Bool]) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            statuses.forEach { continuation.yield($0) }
            continuation.finish()
        }
    }
}
