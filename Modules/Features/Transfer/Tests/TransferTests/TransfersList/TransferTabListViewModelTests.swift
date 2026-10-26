import Combine
import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
@testable import Transfer

/// Exercises the membership state machine: rows are asserted after
/// `monitorTransferEvents()` consumes the injected finite event sequence.
/// The identity `throttle` makes every flush synchronous.
@MainActor
@Suite("TransferTabListViewModel")
struct TransferTabListViewModelTests {

    // MARK: - Snapshot

    @Test func snapshotPopulatesRowsInOrderAndMarksLoaded() async {
        let sut = makeSUT(tab: .completed, snapshot: [
            .init(type: .download, tag: 3, state: .active),
            .init(type: .upload, tag: 1, state: .active),
            .init(type: .download, tag: 2, state: .paused)
        ])
        #expect(!sut.isLoaded)

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [3, 1, 2])
        #expect(sut.isLoaded)
    }

    @Test func emptySnapshotStillMarksLoaded() async {
        let sut = makeSUT()

        await sut.monitorTransferEvents()

        #expect(sut.rows.isEmpty)
        #expect(sut.isLoaded)
    }

    // MARK: - Started

    @Test func startedEventAppendsRow() async {
        let sut = makeSUT(
            snapshot: [.init(type: .download, tag: 1, state: .active)],
            events: [.started(.init(type: .upload, tag: 2, state: .active))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    @Test func duplicateStartInsertsOnlyOneRow() async {
        let entity = TransferEntity(type: .upload, tag: 1, state: .active)
        let sut = makeSUT(events: [.started(entity), .started(entity)])

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1])
    }

    @Test func startedArrivingAfterFinishDoesNotResurrectRow() async {
        // merge doesn't order across streams: a buffered start can land after
        // its own finish. The tombstone must keep the row dead.
        let sut = makeSUT(
            snapshot: [.init(type: .download, tag: 1, state: .active)],
            events: [
                .finished(.init(type: .download, tag: 1, state: .complete)),
                .started(.init(type: .download, tag: 1, state: .active))
            ]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.isEmpty)
    }

    // MARK: - Updated

    @Test func updatedEventNeverInsertsARow() async {
        let sut = makeSUT(events: [.updated(.init(type: .download, tag: 1, state: .active))])

        await sut.monitorTransferEvents()

        #expect(sut.rows.isEmpty)
    }

    @Test func updatedEventMutatesTheExistingRow() async {
        let sut = makeSUT(
            snapshot: [.init(type: .download, transferredBytes: 0, totalBytes: 100, tag: 1, state: .active)],
            events: [.updated(.init(type: .download, transferredBytes: 50, totalBytes: 100, tag: 1, state: .active))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1])
        #expect(sut.rows.first?.state.transferredBytes == 50)
    }

    // MARK: - Finished

    @Test func finishRemovesRowOnActiveTab() async {
        let sut = makeSUT(
            snapshot: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .active)
            ],
            events: [.finished(.init(type: .download, tag: 1, state: .complete))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [2])
    }

    @Test(arguments: [TransfersTab.completed, .failed])
    func finishInsertsRowOnResultTabs(tab: TransfersTab) async {
        let state: TransferStateEntity = tab == .completed ? .complete : .failed
        let sut = makeSUT(
            tab: tab,
            events: [.finished(.init(type: .download, tag: 1, state: state))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1])
    }

    // MARK: - Cleared

    @Test func clearedEventReSnapshotsAndDropsVanishedRows() async {
        let itemsUseCase = SequencedItemsUseCase(
            snapshotsByCall: [
                [
                    .init(type: .download, tag: 1, state: .active),
                    .init(type: .upload, tag: 2, state: .active)
                ],
                [.init(type: .upload, tag: 2, state: .active)]
            ],
            events: [.cleared]
        )
        let sut = makeSUT(tab: .active, itemsUseCase: itemsUseCase)

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [2])
    }

    // MARK: - Selection

    @Test func snapshotMakesItsRowsSelectable() async {
        let selection = TransferSelection()
        let sut = makeSUT(
            snapshot: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .active)
            ],
            selection: selection
        )

        await sut.monitorTransferEvents()
        selection.toggleSelectAll()

        #expect(selection.selectedTags == [1, 2])
    }

    @Test func startedRowBecomesSelectableOnceFlushed() async {
        let selection = TransferSelection()
        let sut = makeSUT(
            snapshot: [.init(type: .download, tag: 1, state: .active)],
            events: [.started(.init(type: .upload, tag: 2, state: .active))],
            selection: selection
        )

        await sut.monitorTransferEvents()
        selection.toggleSelectAll()

        #expect(selection.selectedTags == [1, 2])
    }

    @Test func finishOnActiveTabPrunesTheSelectionWithoutWaitingForAFlush() async {
        // A throttle that never fires: the removal can't reach `rows`, yet the
        // selection must drop the finished tag immediately — pruning is not
        // allowed to hide behind the flush, or the top-bar count goes stale.
        let selection = TransferSelection()
        let sut = makeSUT(
            snapshot: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .active)
            ],
            events: [.finished(.init(type: .download, tag: 1, state: .complete))],
            selection: selection,
            throttle: { _ in Empty().eraseToAnyPublisher() }
        )
        await sut.monitorTransferEvents()

        #expect(selection.listedTags == [2])
        #expect(selection.selectedTags.isEmpty)
    }

    @Test func finishOnActiveTabDropsThatRowFromAnExistingSelection() async {
        let selection = TransferSelection()
        let sut = makeSUT(
            snapshot: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .active)
            ],
            events: [.finished(.init(type: .download, tag: 1, state: .complete))],
            selection: selection,
            throttle: { _ in Empty().eraseToAnyPublisher() }
        )
        selection.setListedTags([1, 2])
        selection.selectedTags = [1, 2]

        await sut.monitorTransferEvents()

        #expect(selection.selectedTags == [2])
    }

    @Test func clearedReSnapshotConvergesTheSelectionOnTheSurvivingRows() async {
        let selection = TransferSelection()
        let itemsUseCase = SequencedItemsUseCase(
            snapshotsByCall: [
                [
                    .init(type: .download, tag: 1, state: .active),
                    .init(type: .upload, tag: 2, state: .active)
                ],
                [.init(type: .upload, tag: 2, state: .active)]
            ],
            events: [.cleared]
        )
        let sut = makeSUT(tab: .active, itemsUseCase: itemsUseCase, selection: selection)
        selection.setListedTags([1, 2])
        selection.selectedTags = [1, 2]

        await sut.monitorTransferEvents()

        #expect(selection.selectedTags == [2])
    }

    // MARK: - Search

    @Test(arguments: [TransfersTab.completed, .failed])
    func searchKeepsRowsWhoseFileNameContainsTheQueryIgnoringCase(tab: TransfersTab) async {
        let (sut, stop) = await startMonitoring(tab: tab, snapshot: [
            .init(fileName: "Book.pdf", tag: 1),
            .init(fileName: "audio.mp3", tag: 2),
            .init(fileName: "my notebook.txt", tag: 3)
        ])
        defer { stop() }

        sut.searchText = "BOOK"

        #expect(sut.rows.map(\.id) == [1, 3])
    }

    @Test func clearingTheQueryRestoresEveryRow() async {
        let (sut, stop) = await startMonitoring(snapshot: [
            .init(fileName: "book.pdf", tag: 1),
            .init(fileName: "audio.mp3", tag: 2)
        ])
        defer { stop() }
        sut.searchText = "book"

        sut.searchText = ""

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    @Test func whitespaceOnlyQueryDoesNotFilter() async {
        let (sut, stop) = await startMonitoring(snapshot: [
            .init(fileName: "book.pdf", tag: 1),
            .init(fileName: "audio.mp3", tag: 2)
        ])
        defer { stop() }

        sut.searchText = "  "

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    @Test func queryMatchingNothingEmptiesRowsButKeepsHasTransfers() async {
        let (sut, stop) = await startMonitoring(snapshot: [.init(fileName: "book.pdf", tag: 1)])
        defer { stop() }

        sut.searchText = "video"

        #expect(sut.rows.isEmpty)
        #expect(sut.hasTransfers)
    }

    @Test func activeTabIgnoresTheQuery() async {
        let (sut, stop) = await startMonitoring(tab: .active, snapshot: [
            .init(fileName: "book.pdf", tag: 1, state: .active),
            .init(fileName: "audio.mp3", tag: 2, state: .active)
        ])
        defer { stop() }

        sut.searchText = "book"

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    @Test func initialQueryFiltersTheSnapshot() async {
        let sut = makeSUT(
            tab: .failed,
            snapshot: [
                .init(fileName: "audio.mp3", tag: 1),
                .init(fileName: "book.pdf", tag: 2)
            ],
            searchText: "audio"
        )

        await sut.monitorTransferEvents()

        #expect(sut.searchText == "audio")
        #expect(sut.rows.map(\.id) == [1])
    }

    @Test func finishedRowNotMatchingTheQueryStaysHidden() async {
        let sut = makeSUT(
            tab: .completed,
            snapshot: [.init(fileName: "book.pdf", tag: 1, state: .complete)],
            events: [.finished(.init(fileName: "audio.mp3", tag: 2, state: .complete))],
            searchText: "book"
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1])
    }

    @Test func queryChangesAreReported() async {
        let recorder = SearchTextRecorder()
        let sut = makeSUT(tab: .completed, onSearchTextChanged: { recorder.values.append($0) })

        sut.searchText = "a"
        sut.searchText = "a"
        sut.searchText = "ab"

        #expect(recorder.values == ["a", "ab"])
    }

    @Test func queryIsNotAppliedUntilItSettlesButIsReportedRightAway() async {
        let recorder = SearchTextRecorder()
        let (sut, stop) = await startMonitoring(
            snapshot: [
                .init(fileName: "book.pdf", tag: 1),
                .init(fileName: "audio.mp3", tag: 2)
            ],
            onSearchTextChanged: { recorder.values.append($0) },
            searchDebounce: { _ in Empty().eraseToAnyPublisher() }
        )
        defer { stop() }

        sut.searchText = "book"

        #expect(sut.rows.map(\.id) == [1, 2])
        #expect(recorder.values == ["book"])
    }

    @Test func clearingTheQueryAppliesWithoutWaitingForTheDebounce() async {
        let (sut, stop) = await startMonitoring(
            snapshot: [
                .init(fileName: "book.pdf", tag: 1),
                .init(fileName: "audio.mp3", tag: 2)
            ],
            searchText: "book",
            searchDebounce: { _ in Empty().eraseToAnyPublisher() }
        )
        defer { stop() }

        sut.searchText = ""

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    @Test func onlyMatchingRowsAreSelectable() async {
        let selection = TransferSelection()
        let (sut, stop) = await startMonitoring(
            snapshot: [
                .init(fileName: "book.pdf", tag: 1),
                .init(fileName: "audio.mp3", tag: 2)
            ],
            selection: selection
        )
        defer { stop() }
        sut.searchText = "book"

        selection.toggleSelectAll()

        #expect(selection.selectedTags == [1])
    }

    @Test func narrowingTheQueryDropsHiddenRowsFromTheSelection() async {
        let selection = TransferSelection()
        let (sut, stop) = await startMonitoring(
            snapshot: [
                .init(fileName: "book.pdf", tag: 1),
                .init(fileName: "audio.mp3", tag: 2)
            ],
            selection: selection
        )
        defer { stop() }
        selection.toggleSelectAll()

        sut.searchText = "audio"

        #expect(selection.selectedTags == [2])
    }

    // MARK: - Queue order

    @Test func activeSnapshotListsDownloadsThenUploadsEachInPriorityOrder() async {
        let sut = makeSUT(snapshot: [
            upload(1, priority: 5),
            download(2, priority: 30),
            upload(3, priority: 1),
            download(4, priority: 20)
        ])

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [4, 2, 3, 1])
    }

    @Test func startedTransferIsListedAtItsQueuePosition() async {
        let sut = makeSUT(
            snapshot: [download(1, priority: 10), download(2, priority: 30), upload(3, priority: 5)],
            events: [.started(download(4, priority: 20))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1, 4, 2, 3])
    }

    @Test func reprioritisedTransferMovesToItsNewPosition() async {
        let sut = makeSUT(
            snapshot: [download(1, priority: 10), download(2, priority: 30), upload(3, priority: 5)],
            events: [.updated(download(2, priority: 5))]
        )

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [2, 1, 3])
    }

    @Test func completedSnapshotKeepsItsOrderRegardlessOfPriority() async {
        let sut = makeSUT(tab: .completed, snapshot: [
            .init(type: .download, tag: 1, state: .complete, priority: 30),
            .init(type: .download, tag: 2, state: .complete, priority: 10)
        ])

        await sut.monitorTransferEvents()

        #expect(sut.rows.map(\.id) == [1, 2])
    }

    // MARK: - Reorder

    @Test func draggingARowReordersTheListRightAway() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)]
        )
        defer { events.finish() }

        let reorder = sut.reorder(fromOffsets: [2], toOffset: 0)

        #expect(sut.rows.map(\.id) == [3, 1, 2])
        #expect(reorder?.transfer.tag == 3)
        #expect(reorder?.nextTransfer?.tag == 1)
    }

    @Test func movingARowUpPlacesItBeforeItsNewNextRow() async {
        let controlUseCase = MockTransferControlUseCase()
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)],
            controlUseCase: controlUseCase
        )
        defer { events.finish() }

        if let reorder = sut.reorder(fromOffsets: [2], toOffset: 1) {
            await sut.commitReorder(reorder)
        }

        #expect(sut.rows.map(\.id) == [1, 3, 2])
        #expect(controlUseCase.movedTransfers.map(\.transfer.tag) == [3])
        #expect(controlUseCase.movedTransfers.map(\.nextTransfer?.tag) == [2])
    }

    @Test func movingARowDownPlacesItBeforeTheRowAfterTheDrop() async {
        let controlUseCase = MockTransferControlUseCase()
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)],
            controlUseCase: controlUseCase
        )
        defer { events.finish() }

        if let reorder = sut.reorder(fromOffsets: [0], toOffset: 2) {
            await sut.commitReorder(reorder)
        }

        #expect(sut.rows.map(\.id) == [2, 1, 3])
        #expect(controlUseCase.movedTransfers.map(\.transfer.tag) == [1])
        #expect(controlUseCase.movedTransfers.map(\.nextTransfer?.tag) == [3])
    }

    @Test func movingARowToTheEndOfItsQueueMovesItToTheEnd() async {
        let controlUseCase = MockTransferControlUseCase()
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)],
            controlUseCase: controlUseCase
        )
        defer { events.finish() }

        if let reorder = sut.reorder(fromOffsets: [0], toOffset: 3) {
            await sut.commitReorder(reorder)
        }

        #expect(sut.rows.map(\.id) == [2, 3, 1])
        #expect(controlUseCase.movedTransfers.map(\.transfer.tag) == [1])
        #expect(controlUseCase.movedTransfers.map(\.nextTransfer?.tag) == [nil])
    }

    @Test func downloadDroppedAmongUploadsLandsAtTheEndOfTheDownloads() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), upload(3, priority: 5), upload(4, priority: 15)]
        )
        defer { events.finish() }

        let reorder = sut.reorder(fromOffsets: [0], toOffset: 4)

        #expect(sut.rows.map(\.id) == [2, 1, 3, 4])
        #expect(reorder?.nextTransfer == nil)
    }

    @Test func uploadDroppedAmongDownloadsLandsFirstAmongTheUploads() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), upload(3, priority: 5), upload(4, priority: 15)]
        )
        defer { events.finish() }

        let reorder = sut.reorder(fromOffsets: [3], toOffset: 0)

        #expect(sut.rows.map(\.id) == [1, 2, 4, 3])
        #expect(reorder?.nextTransfer?.tag == 3)
    }

    @Test(arguments: [1, 2])
    func droppingARowBackInPlaceSendsNothing(destination: Int) async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)]
        )
        defer { events.finish() }

        let reorder = sut.reorder(fromOffsets: [1], toOffset: destination)

        #expect(reorder == nil)
        #expect(sut.rows.map(\.id) == [1, 2, 3])
    }

    @Test func lastDownloadDroppedAmongUploadsSendsNothing() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), upload(3, priority: 5)]
        )
        defer { events.finish() }

        let reorder = sut.reorder(fromOffsets: [1], toOffset: 3)

        #expect(reorder == nil)
        #expect(sut.rows.map(\.id) == [1, 2, 3])
    }

    @Test func rejectedMovePutsTheRowBack() async {
        let controlUseCase = MockTransferControlUseCase()
        controlUseCase.moveError = ReorderTestError.rejected
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)],
            controlUseCase: controlUseCase
        )
        defer { events.finish() }

        if let reorder = sut.reorder(fromOffsets: [2], toOffset: 0) {
            await sut.commitReorder(reorder)
        }

        #expect(sut.rows.map(\.id) == [1, 2, 3])
    }

    @Test func updateReportedBeforeTheMoveLandsDoesNotPutTheRowBack() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)]
        )
        defer { events.finish() }
        _ = sut.reorder(fromOffsets: [2], toOffset: 0)

        events.yield(.updated(download(3, priority: 30)))
        // Events apply in order, so once this row lists the stale update has been applied.
        events.yield(.started(download(4, priority: 40)))
        await settle { sut.rows.map(\.id).contains(4) }

        #expect(sut.rows.map(\.id) == [3, 1, 2, 4])
    }

    @Test func prioritiesReportedAfterTheMoveLandsAreApplied() async {
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)]
        )
        defer { events.finish() }
        _ = sut.reorder(fromOffsets: [2], toOffset: 0)

        events.yield(.updated(download(3, priority: 5)))
        events.yield(.updated(download(1, priority: 50)))
        await settle { sut.rows.map(\.id) == [3, 2, 1] }

        #expect(sut.rows.map(\.id) == [3, 2, 1])
    }

    @Test func rowDroppedAboveAFinishedRowStillOnScreenIsPlacedBeforeTheNextListedRow() async {
        // A throttle that never fires: the finished row stays in `rows` until the drop flushes.
        let registry = TransferRegistry()
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30), download(4, priority: 40)],
            registry: registry,
            throttle: { _ in Empty().eraseToAnyPublisher() }
        )
        defer { events.finish() }
        events.yield(.finished(download(3, priority: 30)))
        await settle { !registry.ids.contains(3) }

        let reorder = sut.reorder(fromOffsets: [0], toOffset: 2)

        #expect(reorder?.nextTransfer?.tag == 4)
        #expect(sut.rows.map(\.id) == [2, 1, 4])
    }

    @Test func draggingARowThatFinishedMeanwhileSendsNothing() async {
        let registry = TransferRegistry()
        let (sut, events) = await startMonitoringActiveTab(
            snapshot: [download(1, priority: 10), download(2, priority: 20), download(3, priority: 30)],
            registry: registry,
            throttle: { _ in Empty().eraseToAnyPublisher() }
        )
        defer { events.finish() }
        events.yield(.finished(download(1, priority: 10)))
        await settle { !registry.ids.contains(1) }

        let reorder = sut.reorder(fromOffsets: [0], toOffset: 3)

        #expect(reorder == nil)
        #expect(sut.rows.map(\.id) == [2, 3])
    }

    @Test(arguments: [TransfersTab.completed, .failed])
    func resultTabsAreNotReorderable(tab: TransfersTab) async {
        let (sut, stop) = await startMonitoring(tab: tab, snapshot: [
            .init(fileName: "a", tag: 1),
            .init(fileName: "b", tag: 2)
        ])
        defer { stop() }

        let reorder = sut.reorder(fromOffsets: [1], toOffset: 0)

        #expect(reorder == nil)
        #expect(sut.rows.map(\.id) == [1, 2])
    }

    // MARK: - Teardown

    @Test func monitorEndPrunesThisTabsRowsFromTheSharedRegistry() async {
        let registry = TransferRegistry()
        let sut = makeSUT(
            snapshot: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .active)
            ],
            registry: registry
        )

        await sut.monitorTransferEvents()

        #expect(registry.ids.isEmpty)
    }

    // MARK: - Helpers

    /// Monitors over an event stream that stays open until `stop` is called, returning once
    /// the snapshot has landed. Query changes have to happen while monitoring is live: its end
    /// prunes the tab's rows from the shared registry, which the search filter re-reads.
    private func startMonitoring(
        tab: TransfersTab = .completed,
        snapshot: [TransferEntity],
        selection: TransferSelection = TransferSelection(),
        searchText: String = "",
        onSearchTextChanged: @escaping @MainActor (String) -> Void = { _ in },
        searchDebounce: TransferTabListViewModel.SearchPublisherDebounce = { $0 }
    ) async -> (sut: TransferTabListViewModel, stop: () -> Void) {
        let (events, continuation) = AsyncStream<TransferTabEvent>.makeStream()
        let sut = makeSUT(
            tab: tab,
            itemsUseCase: MockMonitorTransferTabItemsUseCase(
                snapshot: snapshot,
                events: events.eraseToAnyAsyncSequence()
            ),
            selection: selection,
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged,
            searchDebounce: searchDebounce
        )
        Task { await sut.monitorTransferEvents() }
        while !sut.isLoaded {
            await Task.yield()
        }
        return (sut, { continuation.finish() })
    }

    /// Monitors the Active tab and hands back the open event stream, so a test can feed
    /// events after the snapshot. Finish the stream when done.
    private func startMonitoringActiveTab(
        snapshot: [TransferEntity],
        registry: TransferRegistry = TransferRegistry(),
        controlUseCase: MockTransferControlUseCase = MockTransferControlUseCase(),
        throttle: @escaping TransferTabListViewModel.FlushPublisherThrottle = { $0 }
    ) async -> (sut: TransferTabListViewModel, events: AsyncStream<TransferTabEvent>.Continuation) {
        let (events, continuation) = AsyncStream<TransferTabEvent>.makeStream()
        let sut = makeSUT(
            tab: .active,
            itemsUseCase: MockMonitorTransferTabItemsUseCase(
                snapshot: snapshot,
                events: events.eraseToAnyAsyncSequence()
            ),
            registry: registry,
            controlUseCase: controlUseCase,
            throttle: throttle
        )
        Task { await sut.monitorTransferEvents() }
        while !sut.isLoaded {
            await Task.yield()
        }
        return (sut, continuation)
    }

    /// Yields to the monitoring task until `condition` holds, or long enough that it won't.
    private func settle(until condition: () -> Bool) async {
        var turns = 0
        while !condition(), turns < 100 {
            await Task.yield()
            turns += 1
        }
    }

    private func download(_ tag: Int, priority: UInt64) -> TransferEntity {
        TransferEntity(type: .download, tag: tag, state: .active, priority: priority)
    }

    private func upload(_ tag: Int, priority: UInt64) -> TransferEntity {
        TransferEntity(type: .upload, tag: tag, state: .active, priority: priority)
    }

    private func makeSUT(
        tab: TransfersTab = .active,
        snapshot: [TransferEntity] = [],
        events: [TransferTabEvent] = [],
        registry: TransferRegistry = TransferRegistry(),
        selection: TransferSelection = TransferSelection(),
        searchText: String = "",
        onSearchTextChanged: @escaping @MainActor (String) -> Void = { _ in },
        searchDebounce: TransferTabListViewModel.SearchPublisherDebounce = { $0 },
        throttle: @escaping TransferTabListViewModel.FlushPublisherThrottle = { $0 }
    ) -> TransferTabListViewModel {
        makeSUT(
            tab: tab,
            itemsUseCase: MockMonitorTransferTabItemsUseCase(
                snapshot: snapshot,
                events: events.async.eraseToAnyAsyncSequence()
            ),
            registry: registry,
            selection: selection,
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged,
            searchDebounce: searchDebounce,
            throttle: throttle
        )
    }

    private func makeSUT(
        tab: TransfersTab,
        itemsUseCase: some MonitorTransferTabItemsUseCaseProtocol,
        registry: TransferRegistry = TransferRegistry(),
        selection: TransferSelection = TransferSelection(),
        searchText: String = "",
        onSearchTextChanged: @escaping @MainActor (String) -> Void = { _ in },
        searchDebounce: TransferTabListViewModel.SearchPublisherDebounce = { $0 },
        controlUseCase: MockTransferControlUseCase = MockTransferControlUseCase(),
        throttle: @escaping TransferTabListViewModel.FlushPublisherThrottle = { $0 }
    ) -> TransferTabListViewModel {
        TransferTabListViewModel(
            tab: tab,
            dependency: TransferTabDependency(
                itemsUseCase: itemsUseCase,
                registry: registry,
                locationResolver: StubTransferLocationResolver(),
                finishDateProvider: StubTransferFinishDateProvider(),
                rowRouter: MockTransferRowRouting(),
                clearTransfersUseCase: MockClearTransfersUseCase(),
                controlUseCase: controlUseCase
            ),
            selection: selection,
            searchText: searchText,
            onSearchTextChanged: onSearchTextChanged,
            searchDebounce: searchDebounce,
            throttle: throttle
        )
    }
}

/// Returns a different snapshot on each call, to model the inventory changing
/// across a `.cleared` re-snapshot.
private final class SequencedItemsUseCase: MonitorTransferTabItemsUseCaseProtocol, @unchecked Sendable {
    private let snapshotsByCall: [[TransferEntity]]
    private let eventList: [TransferTabEvent]
    private var call = 0

    init(snapshotsByCall: [[TransferEntity]], events: [TransferTabEvent]) {
        self.snapshotsByCall = snapshotsByCall
        eventList = events
    }

    func snapshot(for tab: TransfersTab) async -> [TransferEntity] {
        let index = min(call, snapshotsByCall.count - 1)
        call += 1
        return snapshotsByCall[index]
    }

    func events(for tab: TransfersTab) -> AnyAsyncSequence<TransferTabEvent> {
        eventList.async.eraseToAnyAsyncSequence()
    }
}

private enum ReorderTestError: Error {
    case rejected
}

@MainActor
private final class SearchTextRecorder {
    var values: [String] = []
}

private struct StubTransferLocationResolver: TransferLocationResolving {
    func location(for entity: TransferEntity) async -> String? { nil }
}

private struct StubTransferFinishDateProvider: TransferFinishDateProviding {
    func finishDate(forTag tag: Int) -> Date? { nil }
    func recordIfAbsent(tag: Int, date: Date) -> Date { date }
    func removeDates(forTags tags: Set<Int>) {}
}
