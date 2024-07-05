import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class TransfersListenerUseCaseTests: XCTestCase {
    class Harness {
        let sut: TransfersListenerUseCase<MockTransfersListenerRepository>
        let repo: MockTransfersListenerRepository
        
        init() {
            repo = MockTransfersListenerRepository()
            sut = TransfersListenerUseCase(repo: repo)
        }
    }
    
    func testTransfers() async {
        // given
        let harness = Harness()
        let mockTransfers = [TransferEntity(nodeHandle: 1), TransferEntity(nodeHandle: 2)]
        
        let taskStartedExp = expectation(description: "Waiting for Task to start")
        let exp = expectation(description: "Waiting for transfers")
        exp.expectedFulfillmentCount = mockTransfers.count
        
        // when
        let task = Task {
            taskStartedExp.fulfill()
            var expectedResults = mockTransfers.map(\.nodeHandle)
            for await transfer in harness.sut.completedTransfers {
                XCTAssertEqual(transfer.nodeHandle, expectedResults.removeFirst())
                // then
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [taskStartedExp], timeout: 0.5)
        
        mockTransfers.forEach {
            harness.repo.simulateTransfer($0)
        }

        await fulfillment(of: [exp], timeout: 0.5)
        task.cancel()
    }
}
