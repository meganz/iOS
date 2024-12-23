import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("TransfersListenerUseCase Tests - Handling completed transfers and controlling queued transfers.")
struct TransfersListenerUseCaseTestSuite {
    
    static func makeSUT() -> (sut: TransfersListenerUseCase, repo: MockTransfersListenerRepository) {
        let repo = MockTransfersListenerRepository()
        let sut = TransfersListenerUseCase(
            repo: repo,
            preferenceUseCase: MockPreferenceUseCase()
        )
        return (sut, repo)
    }
    
    @Suite("Completed Transfers")
    struct CompletedTransfers {
        @Test("Should receive all emitted transfers")
        func receivesAllEmittedTransfers() async {
            let (sut, repo) = TransfersListenerUseCaseTestSuite.makeSUT()
            let mockTransfers = [TransferEntity(nodeHandle: 1), TransferEntity(nodeHandle: 2)]
            
            let task = Task {
                var transfers: [HandleEntity] = []
                for await transfer in sut.completedTransfers {
                    transfers.append(transfer.nodeHandle)
                }
                return transfers
            }
            
            mockTransfers.forEach { repo.simulateTransfer($0) }
            repo.simulateTransferCompletion()
            
            let receivedTransfers = await task.value
            #expect(receivedTransfers == [1, 2])
        }
    }
    
    @Suite("Queued Transfers Control")
    struct QueuedTransfersControl {
        enum QueuedTransfersScenario {
            case pause, resume
        }
        
        @Test(
            "Queued transfers state transitions",
            arguments: [
                (QueuedTransfersScenario.pause, false, true, "Pausing queued transfers updates the state to paused"),
                (QueuedTransfersScenario.resume, true, false, "Resuming previously paused transfers updates the state to unpaused")
            ]
        )
        func testQueuedTransfersStateTransitions(
            action: QueuedTransfersScenario,
            initialState: Bool,
            finalState: Bool,
            description: Comment
        ) {
            let (sut, _) = TransfersListenerUseCaseTestSuite.makeSUT()
            
            if initialState {
                sut.pauseQueuedTransfers()
            }
            
            #expect(sut.areQueuedTransfersPaused() == initialState, "Initial state should match scenario")
            
            switch action {
            case .pause:
                sut.pauseQueuedTransfers()
            case .resume:
                sut.resumeQueuedTransfers()
            }
            
            #expect(sut.areQueuedTransfersPaused() == finalState, description)
        }
    }
}
