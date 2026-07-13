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
        state: TransferRowState? = nil,
        controlUseCase: MockTransferControlUseCase = MockTransferControlUseCase(),
        rowRouter: MockTransferRowRouting = MockTransferRowRouting(),
        clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase()
    ) -> (sut: TransferRowViewModel, useCase: MockTransferControlUseCase) {
        let sut = TransferRowViewModel(
            state: state ?? TransferEntityMapper.rowState(for: entity),
            transfer: entity,
            controlUseCase: controlUseCase,
            rowRouter: rowRouter,
            clearTransfersUseCase: clearTransfersUseCase
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

    // MARK: - Context actions

    @Test("Presenting actions forwards the transfer and a header context")
    func presentActionsForwardsToRouter() {
        let router = MockTransferRowRouting()
        let entity = TransferEntity(fileName: "clip.mov", tag: 42, state: .complete)
        var state = TransferEntityMapper.rowState(for: entity)
        state.canViewInFolder = false
        let (sut, _) = Self.makeSUT(entity: entity, state: state, rowRouter: router)

        sut.presentActions()

        #expect(router.presentActionsTags == [42])
        #expect(router.presentActionsContexts.first?.canViewInFolder == false)
        #expect(router.presentActionsContexts.first?.name == "clip.mov")
    }

    @Test("Tapping Clear in the presented sheet removes the row's entry by tag")
    func clearFromSheetRemovesEntryByTag() {
        let router = MockTransferRowRouting()
        let clearUseCase = MockClearTransfersUseCase()
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(tag: 7, state: .complete),
            rowRouter: router,
            clearTransfersUseCase: clearUseCase
        )

        sut.presentActions()
        router.lastOnClear?()

        #expect(clearUseCase.clearedTransferTags == [7])
    }

    @Test("Tapping a completed row opens the file via the row router")
    func openFileRoutesToRouter() {
        let router = MockTransferRowRouting()
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(tag: 42, state: .complete),
            rowRouter: router
        )

        sut.openFile()

        #expect(router.openFileTags == [42])
    }

    // MARK: - Swipe cancel

    @Test("Swipe-cancelling an active row routes the cancel and returns the entity for undo")
    func cancelRoutesToUseCaseAndReturnsEntity() async {
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(tag: 13, state: .active)
        )

        let cancelled = await sut.cancel()

        #expect(useCase.cancelledTransfers.map(\.tag) == [13])
        #expect(cancelled?.tag == 13)
    }

    @Test("A failed cancel is swallowed and returns nil so the row stays")
    func cancelFailureReturnsNil() async {
        let useCase = MockTransferControlUseCase()
        useCase.cancelError = TestError.failure
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(tag: 14, state: .active),
            controlUseCase: useCase
        )

        let cancelled = await sut.cancel()

        #expect(cancelled == nil)
    }
}
