import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("TransferListUseCase presence")
struct TransferListUseCasePresenceTests {

    @Test func hasCompletedTransfers_withVisibleCompleted_isTrue() {
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .complete)])

        #expect(sut.hasCompletedTransfers())
    }

    @Test func hasCompletedTransfers_withOnlyFailed_isFalse() {
        // A failed transfer isn't visible on the Completed tab.
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .failed)])

        #expect(!sut.hasCompletedTransfers())
    }

    @Test func hasCompletedTransfers_withOnlyFolderTransfer_isFalse() {
        // Folder transfers are excluded from every list (see `isVisibleInList`).
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, isFolderTransfer: true, state: .complete)])

        #expect(!sut.hasCompletedTransfers())
    }

    @Test func hasFailedTransfers_withFailedOrCancelled_isTrue() {
        #expect(makeSUT(completedTransfers: [.init(type: .upload, tag: 1, state: .failed)]).hasFailedTransfers())
        #expect(makeSUT(completedTransfers: [.init(type: .upload, tag: 1, state: .cancelled)]).hasFailedTransfers())
    }

    @Test func hasFailedTransfers_withOnlyCompleted_isFalse() {
        // A completed transfer isn't visible on the Failed tab.
        let sut = makeSUT(completedTransfers: [.init(type: .download, tag: 1, state: .complete)])

        #expect(!sut.hasFailedTransfers())
    }
}

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
    completedTransfers: [TransferEntity] = [],
    listener: MockTransfersListenerUseCase = MockTransfersListenerUseCase()
) -> TransferListUseCase {
    TransferListUseCase(
        inventoryUseCase: MockTransferInventoryUseCase(completedTransfers: completedTransfers),
        transfersListenerUseCase: listener,
        filteringUserTransfers: true
    )
}
