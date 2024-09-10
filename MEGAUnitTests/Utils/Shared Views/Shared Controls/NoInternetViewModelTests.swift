import ConcurrencyExtras
@testable import MEGA
import MEGADomainMock
import MEGASwift
import XCTest

final class NoInternetViewModelTests: XCTestCase {
    func testOnTask_isConnectedAttributeIsTrue_shouldMatch() async {
        await withMainSerialExecutor {
            let sut = NoInternetViewModel(
                networkMonitorUseCase: MockNetworkMonitorUseCase(),
                networkConnectionStateChanged: { _ in }
            )
            let task = Task {
                await sut.onTask()
            }

            await Task.yield()
            XCTAssertTrue(sut.isConnected)
            task.cancel()
        }
    }

    func testOnTask_isConnectedAttributeIsFalse_shouldMatch() async {
        await withMainSerialExecutor {
            let sut = NoInternetViewModel(
                networkMonitorUseCase: MockNetworkMonitorUseCase(connected: false),
                networkConnectionStateChanged: { _ in }
            )
            let task = Task {
                await sut.onTask()
            }

            await Task.yield()
            XCTAssertFalse(sut.isConnected)
            task.cancel()
        }
    }

    func testMonitorNetworkChanges_whenStatusChangesToFalse_shouldMatch() async {
        let connectionSequence = makeConnectionMonitorStream(statuses: [false]).eraseToAnyAsyncSequence()
        let expectation = expectation(description: "Wait for the connection state to update")
        let sut = NoInternetViewModel(
            networkMonitorUseCase: MockNetworkMonitorUseCase(connectionSequence: connectionSequence),
            networkConnectionStateChanged: { isConnected in
                if !isConnected {
                    expectation.fulfill()
                }
            }
        )
        let task = Task {
            await sut.onTask()
        }

        await Task.yield()
        await fulfillment(of: [expectation], timeout: 1.0)
        task.cancel()
    }

    private func makeConnectionMonitorStream(statuses: [Bool]) -> AsyncStream<Bool> {
        AsyncStream { continuation in
            statuses.forEach {
                continuation.yield($0)
            }
            continuation.finish()
        }
    }

}
