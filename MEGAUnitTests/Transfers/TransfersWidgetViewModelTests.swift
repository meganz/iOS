@testable import MEGA
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TransfersWidgetViewModel Tests Suite - Ensures the ViewModel behaves correctly for user actions and state verification")
struct TransfersWidgetViewModelTests {
    
    // MARK: - Helper Functions
    private static func makeSUT(
        paused: Bool = false,
        uploadTransfers: [TransferEntity] = []
    ) -> (TransfersWidgetViewModel, MockTransfersListenerUseCase) {
        let mockTransfersListenerUseCase = MockTransfersListenerUseCase(paused: paused)
        let mockTransferInventoryUseCase = MockTransferInventoryUseCase(
            uploadTransfers: uploadTransfers
        )
        let sut = TransfersWidgetViewModel(
            transfersListenerUseCase: mockTransfersListenerUseCase,
            transfersInventoryUseCase: mockTransferInventoryUseCase
        )
        return (sut, mockTransfersListenerUseCase)
    }

    // MARK: - Action Tests Suite
    @Suite("Action Tests Suite - Verifies behavior when user triggers actions")
    struct ActionTests {
        @Test("pauseQueuedTransfers calls the method to pause queued transfers")
        func pauseQueuedTransfers_callsPause() {
            let (sut, mockListener) = makeSUT()
            mockListener.pauseQueuedTransfersCalledTimes = 0
            
            sut.pauseQueuedTransfers()
            
            #expect(mockListener.pauseQueuedTransfersCalledTimes == 1, "Expected the pauseQueuedTransfers method to be called once.")
        }

        @Test("resumeQueuedTransfers calls the method to resume queued transfers")
        func resumeQueuedTransfers_callsResume() {
            let (sut, mockListener) = makeSUT()
            mockListener.resumeQueuedTransfersCalledTimes = 0
            
            sut.resumeQueuedTransfers()
            
            #expect(mockListener.resumeQueuedTransfersCalledTimes == 1, "Expected the resumeQueuedTransfers method to be called once.")
        }

        @Test("resumeQueuedTransfers does not trigger additional logic when there is an active transfer")
        func resumeQueuedTransfers_withActiveTransfer_noExtraCalls() {
            let activeTransfer = TransferEntity(state: .active)
            let (sut, mockListener) = makeSUT(uploadTransfers: [activeTransfer])
            
            sut.resumeQueuedTransfers()
            
            #expect(mockListener.resumeQueuedTransfersCalledTimes == 1, "Expected the resumeQueuedTransfers method to be called only once when an active transfer exists.")
        }

        @Test("resumeQueuedTransfers resumes transfers when there are no active transfers")
        func resumeQueuedTransfers_withoutActiveTransfer_callsResume() {
            let (sut, mockListener) = makeSUT(uploadTransfers: [])
            
            sut.resumeQueuedTransfers()
            
            #expect(mockListener.resumeQueuedTransfersCalledTimes == 1, "Expected the resumeQueuedTransfers method to be called once when no active transfers exist.")
        }
    }

    // MARK: - State Verification Tests Suite
    @Suite("State Verification Tests Suite - Checks the state of queued transfers")
    struct StateVerificationTests {
        @Test("areQueuedTransfersPaused returns true when transfers are paused")
        func areQueuedTransfersPaused_whenPaused_isTrue() {
            let (_, mockListener) = makeSUT(paused: true)
            
            #expect(mockListener.areQueuedTransfersPaused() == true, "Expected areQueuedTransfersPaused to return true when transfers are paused.")
        }

        @Test("areQueuedTransfersPaused returns false when transfers are not paused")
        func areQueuedTransfersPaused_whenNotPaused_isFalse() {
            let (_, mockListener) = makeSUT(paused: false)
            
            #expect(mockListener.areQueuedTransfersPaused() == false, "Expected areQueuedTransfersPaused to return false when transfers are not paused.")
        }
    }
}
