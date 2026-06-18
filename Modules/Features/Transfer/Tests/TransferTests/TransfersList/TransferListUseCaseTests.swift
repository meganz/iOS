import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("TransferListUseCase pause control")
struct TransferListUseCasePauseTests {

    @Test func areTransfersPaused_reflectsListener() {
        #expect(makeSUT(listener: MockTransfersListenerUseCase(paused: true)).areTransfersPaused())
        #expect(!makeSUT(listener: MockTransfersListenerUseCase(paused: false)).areTransfersPaused())
    }

    @Test func pauseTransfers_forwardsToListener() {
        let listener = MockTransfersListenerUseCase()
        let sut = makeSUT(listener: listener)

        sut.pauseTransfers()

        #expect(listener.pauseTransfersCalledTimes == 1)
        #expect(listener.resumeTransfersCalledTimes == 0)
    }

    @Test func resumeTransfers_forwardsToListener() {
        let listener = MockTransfersListenerUseCase()
        let sut = makeSUT(listener: listener)

        sut.resumeTransfers()

        #expect(listener.resumeTransfersCalledTimes == 1)
        #expect(listener.pauseTransfersCalledTimes == 0)
    }
}

// MARK: - Helpers

private func makeSUT(
    listener: MockTransfersListenerUseCase = MockTransfersListenerUseCase()
) -> TransferListUseCase {
    TransferListUseCase(transfersListenerUseCase: listener)
}
