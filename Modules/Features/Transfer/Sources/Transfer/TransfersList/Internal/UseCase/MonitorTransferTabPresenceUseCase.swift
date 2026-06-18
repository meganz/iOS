import AsyncAlgorithms
import MEGADomain
import MEGASwift

protocol MonitorTransferTabPresenceUseCaseProtocol: Sendable {
    /// Emits the current tab presence: a seed value immediately, then a fresh value each
    /// time a transfer starts or finishes, or a bulk clear runs. Deduplicated, so it
    /// emits only when presence actually changes. Progress and temporary-error updates
    /// are not observed (they never change which tabs are non-empty).
    var presenceUpdates: AnyAsyncSequence<TransferTabPresence> { get }
}

struct MonitorTransferTabPresenceUseCase: MonitorTransferTabPresenceUseCaseProtocol {
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

    var presenceUpdates: AnyAsyncSequence<TransferTabPresence> {
        let inventoryUseCase = self.inventoryUseCase
        let filteringUserTransfers = self.filteringUserTransfers

        let triggers = chain(
            [()].async.eraseToAnyAsyncSequence(),
            merge(
                counterUseCase.transferStartUpdates.map { _ in () }.eraseToAnyAsyncSequence(),
                counterUseCase.transferFinishUpdates.map { _ in () }.eraseToAnyAsyncSequence(),
                clearTransfersUseCase.clearedSignals
            )
        )

        return triggers
            .map { _ in await Self.presence(inventoryUseCase: inventoryUseCase, filteringUserTransfers: filteringUserTransfers) }
            .removeDuplicates()
            .eraseToAnyAsyncSequence()
    }

    private static func presence(
        inventoryUseCase: any TransferInventoryUseCaseProtocol,
        filteringUserTransfers: Bool
    ) async -> TransferTabPresence {
        let ongoing = await inventoryUseCase.transfers(filteringUserTransfers: filteringUserTransfers)
        let completed = inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
        return TransferTabPresence(
            hasActive: ongoing.contains(where: \.isVisibleOnActiveTab),
            hasCompleted: completed.contains(where: \.isVisibleOnCompletedTab),
            hasFailed: completed.contains(where: \.isVisibleOnFailedTab)
        )
    }
}
