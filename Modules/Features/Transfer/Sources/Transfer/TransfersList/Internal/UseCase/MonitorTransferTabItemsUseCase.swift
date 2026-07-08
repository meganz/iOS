import AsyncAlgorithms
import MEGADomain
import MEGASwift

/// A change to the set of transfers a tab renders.
///
/// `started` and `updated` are only emitted for the Active tab. `finished` is
/// emitted for every tab: it removes the row on Active and inserts it on
/// Completed/Failed. `cleared` asks the tab to re-snapshot its inventory.
enum TransferTabEvent: Sendable {
    case started(TransferEntity)
    case updated(TransferEntity)
    case finished(TransferEntity)
    case cleared
}

protocol MonitorTransferTabItemsUseCaseProtocol: Sendable {
    /// The tab's current inventory, filtered to the entities the tab renders.
    func snapshot(for tab: TransfersTab) async -> [TransferEntity]

    /// Live events that change the tab's list. Started and updated events are
    /// pre-filtered to entities visible on the tab; ordering guards (e.g. a stale
    /// update arriving after the finish) remain the consumer's responsibility.
    func events(for tab: TransfersTab) -> AnyAsyncSequence<TransferTabEvent>
}

struct MonitorTransferTabItemsUseCase: MonitorTransferTabItemsUseCaseProtocol {
    private let inventoryUseCase: any TransferInventoryUseCaseProtocol
    private let counterUseCase: any TransferCounterUseCaseProtocol
    private let clearTransfersUseCase: any ClearTransfersUseCaseProtocol
    private let filteringUserTransfers: Bool

    init(
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        counterUseCase: some TransferCounterUseCaseProtocol,
        clearTransfersUseCase: some ClearTransfersUseCaseProtocol,
        filteringUserTransfers: Bool
    ) {
        self.inventoryUseCase = inventoryUseCase
        self.counterUseCase = counterUseCase
        self.clearTransfersUseCase = clearTransfersUseCase
        self.filteringUserTransfers = filteringUserTransfers
    }

    func snapshot(for tab: TransfersTab) async -> [TransferEntity] {
        switch tab {
        case .active:
            await inventoryUseCase.transfers(filteringUserTransfers: filteringUserTransfers)
                .filter(\.isVisibleOnActiveTab)
        case .completed:
            inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(\.isVisibleOnCompletedTab)
        case .failed:
            inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
                .filter(\.isVisibleOnFailedTab)
        }
    }

    func events(for tab: TransfersTab) -> AnyAsyncSequence<TransferTabEvent> {
        // Clearing is a silent SDK cache removal that fires no transfer delegate
        // event, so this is the only signal that re-snapshots the list after a clear.
        let cleared = clearTransfersUseCase.clearedSignals
            .map { _ in TransferTabEvent.cleared }
            .eraseToAnyAsyncSequence()
        switch tab {
        case .active:
            let started = counterUseCase.transferStartUpdates
                .filter { $0.isVisibleOnActiveTab }
                .map(TransferTabEvent.started)
                .eraseToAnyAsyncSequence()
            let updated = merge(
                counterUseCase.transferUpdates,
                counterUseCase.transferTemporaryErrorUpdates.map(\.transferEntity).eraseToAnyAsyncSequence()
            )
            .filter { $0.isVisibleOnActiveTab }
            .map(TransferTabEvent.updated)
            .eraseToAnyAsyncSequence()
            // Finish events are deliberately not visibility-filtered here: a finished
            // entity's state is never visible-on-active, yet the event is what removes
            // the row from the Active tab.
            let finished = counterUseCase.transferFinishUpdates
                .map { TransferTabEvent.finished($0.transferEntity) }
                .eraseToAnyAsyncSequence()
            return merge(merge(started, updated), finished, cleared).eraseToAnyAsyncSequence()
        case .completed:
            let finished = counterUseCase.transferFinishUpdates
                .filter { $0.transferEntity.isVisibleOnCompletedTab }
                .map { TransferTabEvent.finished($0.transferEntity) }
                .eraseToAnyAsyncSequence()
            return merge(finished, cleared).eraseToAnyAsyncSequence()
        case .failed:
            let finished = counterUseCase.transferFinishUpdates
                .filter { $0.transferEntity.isVisibleOnFailedTab }
                .map { TransferTabEvent.finished($0.transferEntity) }
                .eraseToAnyAsyncSequence()
            return merge(finished, cleared).eraseToAnyAsyncSequence()
        }
    }
}
