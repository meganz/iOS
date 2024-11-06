import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class TransfersListenerRepositoryTests: XCTestCase {
    final class Harness: Sendable {
        let sut: TransfersListenerRepository
        fileprivate let sdk: TestSdk
        
        init() {
            sdk = TestSdk()
            sut = .init(sdk: sdk)
        }
    }
    
    final class TestSdk: MEGASdk, @unchecked Sendable {
        var transferDelegates = [MEGATransferDelegate]()
        override func add(_ delegate: any MEGATransferDelegate, queueType: ListenerQueueType) {
            transferDelegates.append(delegate)
        }
        
        func simulateTransfer(_ transfer: MockTransfer) {
            transferDelegates.forEach {
                $0.onTransferFinish?(MockSdk(), transfer: transfer, error: .init())
            }
        }
    }
    
    func testTransfers() async {
        // given
        let harness = Harness()
        let mockTransfers = [MockTransfer(nodeHandle: 1), MockTransfer(nodeHandle: 2)]
        
        // when
        let taskStartedExp = expectation(description: "Waiting for Task to start")
        let exp = expectation(description: "Waiting for transfers")
        exp.expectedFulfillmentCount = mockTransfers.count
        
        let task = Task { @Sendable in
            taskStartedExp.fulfill()
            var expectedResults = mockTransfers.map(\.nodeHandle)
            for await transfer in harness.sut.completedTransfers {
                XCTAssertEqual(transfer.nodeHandle, expectedResults.removeFirst())
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [taskStartedExp], timeout: 0.5)
        
        mockTransfers.forEach {
            harness.sdk.simulateTransfer($0)
        }
        
        // and then
        await fulfillment(of: [exp], timeout: 0.5)
        task.cancel()
    }
}
