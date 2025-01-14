import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

@Suite("TransfersListenerUseCase Tests - Handling completed transfers and controlling queued transfers.")
struct TransfersListenerUseCaseTestSuite {
    
    static func makeSUT() -> (sut: TransfersListenerUseCase, repo: MockTransfersListenerRepository) {
        let repo = MockTransfersListenerRepository.newRepo
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
    
    @Suite("All Transfers Control")
    struct AllTransfersControl {
        
        @Test("Transfers state transitions after pausing")
        func testPauseTransfersUpdatesState() {
            let (sut, repo) = TransfersListenerUseCaseTestSuite.makeSUT()
            sut.pauseTransfers()
            #expect(sut.areTransfersPaused() == true, "Transfers should be paused after calling pauseTransfers()")
            #expect(repo.pauseTransfers_calledTimes == 1, "pauseTransfers should be called exactly once.")
        }
        
        @Test("Transfers state transitions after resuming")
        func testResumeTransfersUpdatesState() {
            let (sut, repo) = TransfersListenerUseCaseTestSuite.makeSUT()
            sut.pauseTransfers()
            #expect(sut.areTransfersPaused() == true, "Transfers should be paused before calling resumeTransfers()")
            sut.resumeTransfers()
            #expect(sut.areTransfersPaused() == false, "Transfers should not be paused after calling resumeTransfers()")
            #expect(repo.resumeTransfers_calledTimes == 1, "resumeTransfers should be called exactly once.")
        }
        
        @Test("areTransfersPaused reflects either transfer or queued transfer paused state")
        func testAreTransfersPausedReflectsCorrectState() {
            let (sut, _) = TransfersListenerUseCaseTestSuite.makeSUT()
            #expect(sut.areTransfersPaused() == false, "Initially, transfers should not be paused")
            
            sut.pauseQueuedTransfers()
            #expect(sut.areTransfersPaused() == true, "Should reflect true when queued transfers are paused")
            
            sut.resumeQueuedTransfers()
            #expect(sut.areTransfersPaused() == false, "Should reflect false when no transfers are paused")
        }
    }
}
