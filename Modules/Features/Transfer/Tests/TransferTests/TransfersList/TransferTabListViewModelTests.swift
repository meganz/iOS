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
        let sut = makeSUT(snapshot: [
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

    private func makeSUT(
        tab: TransfersTab = .active,
        snapshot: [TransferEntity] = [],
        events: [TransferTabEvent] = [],
        registry: TransferRegistry = TransferRegistry()
    ) -> TransferTabListViewModel {
        makeSUT(
            tab: tab,
            itemsUseCase: MockMonitorTransferTabItemsUseCase(
                snapshot: snapshot,
                events: events.async.eraseToAnyAsyncSequence()
            ),
            registry: registry
        )
    }

    private func makeSUT(
        tab: TransfersTab,
        itemsUseCase: some MonitorTransferTabItemsUseCaseProtocol,
        registry: TransferRegistry = TransferRegistry()
    ) -> TransferTabListViewModel {
        TransferTabListViewModel(
            tab: tab,
            dependency: TransferTabDependency(
                itemsUseCase: itemsUseCase,
                registry: registry,
                locationResolver: StubTransferLocationResolver(),
                finishDateProvider: StubTransferFinishDateProvider(),
                rowRouter: MockTransferRowRouting(),
                clearTransfersUseCase: MockClearTransfersUseCase()
            ),
            throttle: { $0 }
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

private struct StubTransferLocationResolver: TransferLocationResolving {
    func location(for entity: TransferEntity) async -> String? { nil }
}

private struct StubTransferFinishDateProvider: TransferFinishDateProviding {
    func finishDate(forTag tag: Int) -> Date? { nil }
    func recordIfAbsent(tag: Int, date: Date) -> Date { date }
    func removeDates(forTags tags: Set<Int>) {}
}
