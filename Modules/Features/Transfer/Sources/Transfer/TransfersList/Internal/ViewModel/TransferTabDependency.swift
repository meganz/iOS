import MEGADomain

/// The dependencies a Transfers tab needs to build its own `TransferTabViewModel`.
/// Built once in the composition root and injected by `TransfersListView` into each
/// tab, so the same `TransferRegistry` (a shared per-row store) is reused as a
/// transfer moves between tabs. Each tab constructs its `TransferTabViewModel` from
/// this, so the parent `TransfersListViewModel` no longer owns tab construction.
struct TransferTabDependency: Sendable {
    let inventoryUseCase: any TransferInventoryUseCaseProtocol
    let counterUseCase: any TransferCounterUseCaseProtocol
    let registry: TransferRegistry
    let locationResolver: any TransferLocationResolving
    let filteringUserTransfers: Bool
    /// Shared clear use case. The parent VM calls it to clear a tab; the mounted tab's
    /// provider observes its `clearedSignals` to re-query, since clearing emits no SDK
    /// transfer event of its own. Shared so both see the same emitter.
    let clearTransfersUseCase: any ClearTransfersUseCaseProtocol
}
