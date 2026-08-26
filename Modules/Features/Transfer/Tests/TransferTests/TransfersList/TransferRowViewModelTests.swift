import Foundation
import MEGADomain
import MEGADomainMock
import MEGARepo
import Testing
@testable import Transfer
import UIKit

@Suite("TransferRowViewModel per-row pause/resume")
@MainActor
struct TransferRowViewModelTests {
    private enum TestError: Error { case failure }

    private static func makeSUT(
        entity: TransferEntity,
        state: TransferRowState? = nil,
        controlUseCase: MockTransferControlUseCase = MockTransferControlUseCase(),
        rowRouter: MockTransferRowRouting = MockTransferRowRouting(),
        clearTransfersUseCase: MockClearTransfersUseCase = MockClearTransfersUseCase(),
        thumbnailLoader: TransferThumbnailLoader? = nil
    ) -> (sut: TransferRowViewModel, useCase: MockTransferControlUseCase) {
        let sut = TransferRowViewModel(
            state: state ?? TransferEntityMapper.rowState(for: entity, isRetryable: false),
            transfer: entity,
            controlUseCase: controlUseCase,
            rowRouter: rowRouter,
            clearTransfersUseCase: clearTransfersUseCase,
            thumbnailLoader: thumbnailLoader ?? TransferThumbnailLoader(thumbnailUseCase: MockThumbnailUseCase())
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
        var state = TransferEntityMapper.rowState(for: entity, isRetryable: false)
        state.canViewInFolder = false
        let (sut, _) = Self.makeSUT(entity: entity, state: state, rowRouter: router)

        sut.presentActions(isOffline: false, onRetried: {})

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

        sut.presentActions(isOffline: false, onRetried: {})
        router.lastOnClear?()

        #expect(clearUseCase.clearedTransferTags == [7])
    }

    @Test("The presented sheet receives a Retry handler alongside Clear")
    func presentActionsForwardsRetryHandler() {
        let router = MockTransferRowRouting()
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(tag: 8, state: .failed),
            rowRouter: router
        )

        sut.presentActions(isOffline: false, onRetried: {})

        #expect(router.lastOnRetry != nil)
        #expect(router.lastOnClear != nil)
    }

    /// Offline, the sheet must not be a way around the disabled select-mode buttons: Retry
    /// needs a connection, and Clear is withheld to match the bulk action for the same thing.
    @Test("Offline strips Retry and Clear from the sheet context")
    func presentActionsOfflineWithholdsMutatingEntries() {
        let router = MockTransferRowRouting()
        let entity = TransferEntity(fileName: "clip.mov", tag: 9, state: .failed)
        let state = TransferEntityMapper.rowState(for: entity, isRetryable: true)
        let (sut, _) = Self.makeSUT(entity: entity, state: state, rowRouter: router)

        sut.presentActions(isOffline: true, onRetried: {})

        #expect(router.presentActionsContexts.first?.canRetry == false)
        #expect(router.presentActionsContexts.first?.canClear == false)
    }

    /// The non-mutating entries are keyed off `canViewInFolder`, which offline must leave
    /// alone — a downloaded file is still there to be revealed and opened.
    @Test("Offline leaves the sheet's non-mutating entries alone")
    func presentActionsOfflineKeepsViewInFolder() {
        let router = MockTransferRowRouting()
        let entity = TransferEntity(fileName: "clip.mov", tag: 10, state: .complete)
        var state = TransferEntityMapper.rowState(for: entity, isRetryable: false)
        state.canViewInFolder = true
        let (sut, _) = Self.makeSUT(entity: entity, state: state, rowRouter: router)

        sut.presentActions(isOffline: true, onRetried: {})

        #expect(router.presentActionsContexts.first?.canViewInFolder == true)
    }

    /// Online, a retryable row keeps both — the gate is the connection, not the row.
    @Test("Online keeps Retry and Clear in the sheet context")
    func presentActionsOnlineOffersMutatingEntries() {
        let router = MockTransferRowRouting()
        let entity = TransferEntity(fileName: "clip.mov", tag: 11, state: .failed)
        let state = TransferEntityMapper.rowState(for: entity, isRetryable: true)
        let (sut, _) = Self.makeSUT(entity: entity, state: state, rowRouter: router)

        sut.presentActions(isOffline: false, onRetried: {})

        #expect(router.presentActionsContexts.first?.canRetry == true)
        #expect(router.presentActionsContexts.first?.canClear == true)
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

    // MARK: - Retry

    @Test("Retrying a failed row re-queues the transfer, then clears its old entry")
    func retryRoutesRetryThenClear() async {
        let clearUseCase = MockClearTransfersUseCase()
        let (sut, useCase) = Self.makeSUT(
            entity: TransferEntity(tag: 21, state: .failed),
            clearTransfersUseCase: clearUseCase
        )

        let retried = await sut.retry()

        #expect(retried)
        #expect(useCase.retriedTransfers.map(\.tag) == [21])
        #expect(clearUseCase.clearedTransferTags == [21])
    }

    @Test("A failed retry is swallowed, clears nothing, and reports false so no snackbar shows")
    func retryFailureClearsNothing() async {
        let useCase = MockTransferControlUseCase()
        useCase.retryError = TestError.failure
        let clearUseCase = MockClearTransfersUseCase()
        let (sut, _) = Self.makeSUT(
            entity: TransferEntity(tag: 22, state: .failed),
            controlUseCase: useCase,
            clearTransfersUseCase: clearUseCase
        )

        let retried = await sut.retry()

        #expect(!retried)
        #expect(clearUseCase.clearedTransferTags.isEmpty)
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
    
    // MARK: - Thumbnail retry on upload completion

    @Test("Upload completion re-arms a missed thumbnail load and bumps the retry trigger")
    func uploadCompletionRearmsThumbnailRetry() async throws {
        // Staged-file generation always fails; the node's thumbnail is locally cached,
        // so only the post-completion node lookup can produce an image.
        let thumbnailURL = try Self.writeTempImage()
        let loader = TransferThumbnailLoader(
            thumbnailUseCase: MockThumbnailUseCase(
                cachedThumbnails: [ThumbnailEntity(url: thumbnailURL, type: .thumbnail)]
            ),
            makeUploadThumbnailGenerator: { _ in StubFailingAttributeGenerator() }
        )
        let inFlight = TransferEntity(type: .upload, path: "/staged/doc.pdf", tag: 21, state: .active)
        let (sut, _) = Self.makeSUT(entity: inFlight, thumbnailLoader: loader)

        await sut.loadThumbnail()
        #expect(sut.thumbnail == nil)
        let triggerBefore = sut.thumbnailRetryTrigger

        // A resolved miss stays resolved while the upload is in flight.
        await sut.loadThumbnail()
        #expect(sut.thumbnail == nil)
        #expect(sut.thumbnailRetryTrigger == triggerBefore)

        let completed = TransferEntity(type: .upload, path: "/staged/doc.pdf", nodeHandle: 7, tag: 21, state: .complete)
        sut.update(state: TransferEntityMapper.rowState(for: completed, isRetryable: false), transfer: completed)
        #expect(sut.thumbnailRetryTrigger == triggerBefore + 1)

        // The bumped trigger restarts the row's `.task`, which retries via the node.
        await sut.loadThumbnail()
        #expect(sut.thumbnail != nil)
    }

    private static func writeTempImage() throws -> URL {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).png")
        let data = try #require(image.pngData())
        try data.write(to: url)
        return url
    }
}

private struct StubFailingAttributeGenerator: FileAttributeGeneratorProtocol {
    func createThumbnail(at destinationURL: URL) async -> Bool { false }

    func createPreview(at destinationURL: URL) async -> Bool { false }

    func requestThumbnail() async -> UIImage? { nil }
}
