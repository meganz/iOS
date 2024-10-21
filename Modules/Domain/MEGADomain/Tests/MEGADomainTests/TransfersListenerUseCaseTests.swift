import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

struct TransfersListenerUseCaseTests {
    final class Harness: Sendable {
        let sut: TransfersListenerUseCase<MockTransfersListenerRepository>
        let repo: MockTransfersListenerRepository
        
        init() {
            repo = MockTransfersListenerRepository()
            sut = TransfersListenerUseCase(repo: repo)
        }
    }
    
    @Test
    func testTransfers() async {
        // given
        let harness = Harness()
        let mockTransfers = [TransferEntity(nodeHandle: 1), TransferEntity(nodeHandle: 2)]
        
        // when
        let task = Task {
            var transfers: [HandleEntity] = []
            for await transfer in harness.sut.completedTransfers {
                transfers.append(transfer.nodeHandle)
            }
            return transfers
        }
        
        mockTransfers.forEach {
            harness.repo.simulateTransfer($0)
        }
        
        harness.repo.simulateTransferCompletion()

        let receivedTransfers = await task.value
        
        #expect(receivedTransfers == [1, 2])
    }
}
