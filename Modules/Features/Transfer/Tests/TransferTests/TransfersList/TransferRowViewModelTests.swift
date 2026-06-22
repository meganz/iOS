import MEGADomain
import MEGADomainMock
import Testing
@testable import Transfer

@Suite("TransferRowViewModel per-row pause/resume")
@MainActor
struct TransferRowViewModelTests {
    private enum TestError: Error { case failure }

    private static func makeSUT(
        entity: TransferEntity,
        controlUseCase: MockTransferControlUseCase = MockTransferControlUseCase()
    ) -> (sut: TransferRowViewModel, useCase: MockTransferControlUseCase) {
        let sut = TransferRowViewModel(
            state: TransferEntityMapper.rowState(for: entity),
            transfer: entity,
            controlUseCase: controlUseCase
        )
        return (sut, controlUseCase)
    }

    // MARK: - Routing

    @Test("Tapping an active row pauses that transfer and flips the row")
    func pauseActiveTransfer() async {
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(transferredBytes: 50, totalBytes: 100, tag: 7, state: .active)
        )

        await sut.togglePauseResume()

        #expect(useCase.pausedTransfers.map(\.tag) == [7])
        #expect(useCase.resumedTransfers.isEmpty)
        #expect(sut.state.status == .paused)
    }

    @Test("Tapping a queued row pauses that transfer")
    func pauseQueuedTransfer() async {
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(tag: 8, state: .queued)
        )

        await sut.togglePauseResume()

        #expect(useCase.pausedTransfers.map(\.tag) == [8])
        #expect(sut.state.status == .paused)
    }

    @Test("Tapping a paused row resumes that transfer and flips the row")
    func resumePausedTransfer() async {
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(transferredBytes: 50, totalBytes: 100, tag: 9, state: .paused)
        )

        await sut.togglePauseResume()

        #expect(useCase.resumedTransfers.map(\.tag) == [9])
        #expect(useCase.pausedTransfers.isEmpty)
        #expect(sut.state.status == .active)
    }

    @Test("Terminal-state rows route no pause/resume request")
    func terminalStateIsNoOp() async {
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(tag: 10, state: .complete)
        )

        await sut.togglePauseResume()

        #expect(useCase.pausedTransfers.isEmpty)
        #expect(useCase.resumedTransfers.isEmpty)
    }

    // MARK: - Error handling

    @Test("A failed pause is swallowed and leaves the row unchanged")
    func pauseFailureLeavesRowUnchanged() async {
        let useCase = MockTransferControlUseCase()
        useCase.pauseError = TestError.failure
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(transferredBytes: 50, totalBytes: 100, tag: 11, state: .active),
            controlUseCase: useCase
        )

        await sut.togglePauseResume()

        #expect(sut.state.status == .active)
    }

    @Test("A failed resume is swallowed and leaves the row unchanged")
    func resumeFailureLeavesRowUnchanged() async {
        let useCase = MockTransferControlUseCase()
        useCase.resumeError = TestError.failure
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(transferredBytes: 50, totalBytes: 100, tag: 12, state: .paused),
            controlUseCase: useCase
        )

        await sut.togglePauseResume()

        #expect(sut.state.status == .paused)
    }
}
