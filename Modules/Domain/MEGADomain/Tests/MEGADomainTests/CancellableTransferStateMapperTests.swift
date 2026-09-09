import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing

/// Covers how a batch's transfer events are read as the state of that batch: which of them the
/// screen is told about, which are dropped, and what ends the reading.
///
/// The mapper is shared by both batch use cases and reads an upload exactly as it reads a
/// download -- `direction` only names the batch in the logs -- so the matrix is exercised once here
/// rather than twice through the use cases.
@Suite("CancellableTransferStateMapper Tests")
struct CancellableTransferStateMapperTests {

    // MARK: - Helpers

    private func makeSUT(direction: TransferDirectionEntity = .upload) -> CancellableTransferStateMapper {
        CancellableTransferStateMapper(direction: direction)
    }

    /// The states read from a batch that reported `events` and then ended, on `error` when given.
    private func states(
        from events: [TransferEventEntity],
        endingWith error: (any Error)? = nil
    ) async -> [CancellableTransferStateEntity] {
        var collected = [CancellableTransferStateEntity]()
        let mapped = makeSUT().map(from: {
            AsyncThrowingStream(TransferEventEntity.self) { continuation in
                events.forEach { continuation.yield($0) }
                continuation.finish(throwing: error)
            }.eraseToAnyAsyncThrowingSequence()
        })

        for await state in mapped {
            collected.append(state)
        }
        return collected
    }

    // MARK: - The stages of the batch

    @Test("A scanning batch is reported with what it has found so far")
    func aScanUpdateIsReportedAsScanning() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3)
        ])

        #expect(states == [.scanning(name: "Docs", folderCount: 2, fileCount: 3), .transferringFiles])
    }

    @Test("A scanning batch with no name to show is reported without one")
    func aScanUpdateWithoutAFileNameIsReportedWithAnEmptyName() async {
        let states = await states(from: [
            .folderUpdate(
                FolderTransferUpdateEntity(
                    transfer: TransferEntity(fileName: nil),
                    stage: .scan,
                    folderCount: 1,
                    createdFolderCount: 0,
                    fileCount: 1
                )
            )
        ])

        #expect(states.first == .scanning(name: "", folderCount: 1, fileCount: 1))
    }

    @Test("A batch recreating its tree is reported with how much of it stands")
    func aCreateTreeUpdateIsReportedAsCreatingFolders() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .createTree, folderCount: 4, createdFolderCount: 1)
        ])

        #expect(states == [.creatingFolders(created: 1, total: 4), .transferringFiles])
    }

    @Test("Every step of a stage is reported, so the screen can follow it")
    func everyProgressUpdateIsReported() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 1, fileCount: 1),
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 5),
            .folderUpdateEvent(stage: .createTree, folderCount: 2, createdFolderCount: 1),
            .folderUpdateEvent(stage: .createTree, folderCount: 2, createdFolderCount: 2)
        ])

        #expect(states == [
            .scanning(name: "Docs", folderCount: 1, fileCount: 1),
            .scanning(name: "Docs", folderCount: 2, fileCount: 5),
            .creatingFolders(created: 1, total: 2),
            .creatingFolders(created: 2, total: 2),
            .transferringFiles
        ])
    }

    @Test("A stage is reported as the batch reaches it, not once the batch is over")
    func aStageIsReportedAsItArrives() async {
        let (events, continuation) = AsyncThrowingStream.makeStream(
            of: TransferEventEntity.self,
            throwing: (any Error).self
        )
        continuation.yield(.folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 1, fileCount: 2))

        var states = makeSUT().map(from: { events.eraseToAnyAsyncThrowingSequence() }).makeAsyncIterator()

        // The batch is still going: nothing has finished the events it reports.
        #expect(await states.next() == .scanning(name: "Docs", folderCount: 1, fileCount: 2))

        continuation.finish()
    }

    // MARK: - What says nothing about the batch

    @Test("A stage-less folder update is dropped")
    func theNoneStageIsDropped() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .none, folderCount: 9, fileCount: 9)
        ])

        #expect(states == [.transferringFiles])
    }

    @Test("Start, byte progress and finish events are dropped")
    func nonFolderEventsAreDropped() async {
        // They belong to the transfer the batch is reported as, which carries no counts of it.
        let states = await states(from: [
            .start(TransferEntity()),
            .update(TransferEntity()),
            .finish(TransferEntity())
        ])

        #expect(states == [.transferringFiles])
    }

    // MARK: - Ending the batch

    @Test("A batch that reaches its transferring stage is away")
    func aTransferringUpdateEndsOnTransferringFiles() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 5)
        ])

        #expect(states == [.transferringFiles])
    }

    @Test("A batch that ends without reaching its transferring stage is away all the same")
    func exhaustedEventsEndOnTransferringFiles() async {
        // A screen waiting on a terminal state has to be given one, whichever way the batch ended,
        // and events that ran out without an error are events of a batch that got queued.
        let states = await states(from: [])

        #expect(states == [.transferringFiles])
    }

    @Test("Nothing the batch reports after its transferring stage is read")
    func nothingIsReportedAfterTransferringFiles() async {
        let states = await states(from: [
            .folderUpdateEvent(stage: .transferringFiles, fileCount: 1),
            .folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 2),
            .folderUpdateEvent(stage: .createTree, folderCount: 2, createdFolderCount: 1)
        ])

        #expect(states == [.transferringFiles])
    }

    @Test("A batch whose events fail ends on failed")
    func failingEventsEndOnFailed() async {
        let states = await states(from: [], endingWith: TransferErrorEntity.generic)

        #expect(states == [.failed])
    }

    @Test("A batch that failed while scanning keeps the progress it had reported")
    func progressBeforeAFailureIsKept() async {
        let states = await states(
            from: [.folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 2, fileCount: 3)],
            endingWith: TransferErrorEntity.generic
        )

        #expect(states == [.scanning(name: "Docs", folderCount: 2, fileCount: 3), .failed])
    }

    @Test("A batch that failed after reporting itself away is not walked back")
    func anErrorAfterTheTransferringStageIsNotRead() async {
        let states = await states(
            from: [.folderUpdateEvent(stage: .transferringFiles, fileCount: 1)],
            endingWith: TransferErrorEntity.generic
        )

        #expect(states == [.transferringFiles])
    }

    // MARK: - Starting and dropping the batch

    @Test("The batch is started once, from inside the mapping")
    func theBatchIsStartedOnce() async {
        let startCount = Atomic(wrappedValue: 0)

        let mapped = makeSUT().map(from: {
            startCount.mutate { $0 += 1 }
            return EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
        })
        for await _ in mapped { }

        #expect(startCount.wrappedValue == 1)
    }

    @Test("Walking away from the states stops reading the batch's events")
    func droppingTheStatesStopsReadingTheEvents() async {
        let (events, eventsContinuation) = AsyncThrowingStream.makeStream(
            of: TransferEventEntity.self,
            throwing: (any Error).self
        )
        let (letGo, letGoContinuation) = AsyncStream.makeStream(of: Void.self)
        eventsContinuation.onTermination = { _ in letGoContinuation.yield() }
        eventsContinuation.yield(.folderUpdateEvent(stage: .scan, name: "Docs", folderCount: 1, fileCount: 1))

        for await _ in makeSUT().map(from: { events.eraseToAnyAsyncThrowingSequence() }) {
            break
        }

        // The batch is left running -- cancelling it is the use case's job, not the mapper's --
        // but its events are of no use to a caller that stopped reading the states.
        var letGoStates = letGo.makeAsyncIterator()
        await letGoStates.next()
    }
}
