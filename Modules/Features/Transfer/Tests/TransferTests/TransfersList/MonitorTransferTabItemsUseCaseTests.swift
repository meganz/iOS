import Foundation
import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
@testable import Transfer

@Suite("MonitorTransferTabItemsUseCase")
struct MonitorTransferTabItemsUseCaseTests {

    // MARK: - Snapshot

    @Test func activeSnapshotIncludesOnlyTransfersVisibleOnActiveTab() async {
        let sut = makeSUT(
            inventory: MockTransferInventoryUseCase(transfers: [
                .init(type: .download, tag: 1, state: .active),
                .init(type: .upload, tag: 2, state: .paused),
                .init(type: .download, tag: 3, state: .complete),
                .init(type: .download, tag: 4, isFolderTransfer: true, state: .active)
            ])
        )

        let tags = await sut.snapshot(for: .active).map(\.tag)

        #expect(tags == [1, 2])
    }

    @Test func completedSnapshotIncludesOnlyCompleteTransfers() async {
        let sut = makeSUT(inventory: mixedCompletedInventory)

        let tags = await sut.snapshot(for: .completed).map(\.tag)

        #expect(tags == [1])
    }

    @Test func failedSnapshotIncludesFailedAndCancelledTransfers() async {
        let sut = makeSUT(inventory: mixedCompletedInventory)

        let tags = await sut.snapshot(for: .failed).map(\.tag)

        #expect(tags == [2, 3])
    }

    // MARK: - Events

    @Test func activeEventsMapStartsAndDropInvisibleOnes() async {
        let sut = makeSUT(startUpdates: [
            .init(type: .upload, tag: 1, state: .active),
            .init(type: .download, tag: 2, state: .complete)
        ])

        let events = await collect(sut.events(for: .active))

        #expect(events == [.started(1)])
    }

    @Test func activeEventsMapProgressAndTemporaryErrorsToUpdated() async {
        let sut = makeSUT(
            progressUpdates: [.init(type: .upload, tag: 1, state: .active)],
            temporaryErrors: [.init(type: .download, tag: 2, state: .retrying)]
        )

        let events = await collect(sut.events(for: .active))

        // The two source streams are merged, so cross-stream order is undefined.
        #expect(Set(events) == [.updated(1), .updated(2)])
    }

    @Test func activeEventsPassFinishesThroughUnfiltered() async {
        // A finished entity is never visible on the Active tab, yet its event is
        // what removes the row, so no visibility filter may apply here.
        let sut = makeSUT(finishUpdates: [
            .init(type: .download, tag: 1, state: .complete),
            .init(type: .upload, tag: 2, state: .failed)
        ])

        let events = await collect(sut.events(for: .active))

        #expect(events == [.finished(1), .finished(2)])
    }

    @Test func completedEventsIncludeOnlyCompleteFinishes() async {
        let sut = makeSUT(
            startUpdates: [.init(type: .upload, tag: 9, state: .active)],
            progressUpdates: [.init(type: .upload, tag: 9, state: .active)],
            finishUpdates: mixedFinishes
        )

        let events = await collect(sut.events(for: .completed))

        #expect(events == [.finished(1)])
    }

    @Test func failedEventsIncludeFailedAndCancelledFinishes() async {
        let sut = makeSUT(finishUpdates: mixedFinishes)

        let events = await collect(sut.events(for: .failed))

        #expect(events == [.finished(2), .finished(3)])
    }

    @Test(arguments: TransfersTab.allCases)
    func clearedSignalMapsToClearedEventOnEveryTab(tab: TransfersTab) async {
        let sut = makeSUT(clearedSignals: [()])

        let events = await collect(sut.events(for: tab))

        #expect(events == [.cleared])
    }

    // MARK: - Helpers

    private var mixedCompletedInventory: MockTransferInventoryUseCase {
        MockTransferInventoryUseCase(completedTransfers: [
            .init(type: .download, tag: 1, state: .complete),
            .init(type: .upload, tag: 2, state: .failed),
            .init(type: .download, tag: 3, state: .cancelled)
        ])
    }

    private var mixedFinishes: [TransferEntity] {
        [
            .init(type: .download, tag: 1, state: .complete),
            .init(type: .upload, tag: 2, state: .failed),
            .init(type: .download, tag: 3, state: .cancelled)
        ]
    }

    private func makeSUT(
        inventory: MockTransferInventoryUseCase = MockTransferInventoryUseCase(),
        startUpdates: [TransferEntity] = [],
        progressUpdates: [TransferEntity] = [],
        temporaryErrors: [TransferEntity] = [],
        finishUpdates: [TransferEntity] = [],
        clearedSignals: [Void] = []
    ) -> MonitorTransferTabItemsUseCase {
        MonitorTransferTabItemsUseCase(
            inventoryUseCase: inventory,
            counterUseCase: MockTransferCounterUseCase(
                transferStartUpdates: startUpdates.async.eraseToAnyAsyncSequence(),
                transferUpdates: progressUpdates.async.eraseToAnyAsyncSequence(),
                transferTemporaryErrorUpdates: responses(temporaryErrors),
                transferFinishUpdates: responses(finishUpdates)
            ),
            clearTransfersUseCase: MockClearTransfersUseCase(clearedSignals: clearedSignals),
            filteringUserTransfers: true
        )
    }

    private func collect(_ events: AnyAsyncSequence<TransferTabEvent>) async -> [EventDescriptor] {
        var values: [EventDescriptor] = []
        for await event in events {
            values.append(EventDescriptor(event))
        }
        return values
    }

    private func responses(_ entities: [TransferEntity]) -> AnyAsyncSequence<TransferResponseEntity> {
        entities
            .map { TransferResponseEntity(transferEntity: $0, error: ErrorEntity(type: .ok)) }
            .async
            .eraseToAnyAsyncSequence()
    }
}

/// `TransferEntity` is not `Equatable`, so events are reduced to their tag for assertions.
private enum EventDescriptor: Hashable {
    case started(Int)
    case updated(Int)
    case finished(Int)
    case cleared

    init(_ event: TransferTabEvent) {
        self = switch event {
        case .started(let entity): .started(entity.tag)
        case .updated(let entity): .updated(entity.tag)
        case .finished(let entity): .finished(entity.tag)
        case .cleared: .cleared
        }
    }
}
