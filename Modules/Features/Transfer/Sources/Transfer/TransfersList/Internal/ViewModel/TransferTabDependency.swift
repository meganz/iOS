struct TransferTabDependency: Sendable {
    let itemsUseCase: any MonitorTransferTabItemsUseCaseProtocol
    let registry: TransferRegistry
    let locationResolver: any TransferLocationResolving
    let finishDateProvider: any TransferFinishDateProviding
    let rowRouter: any TransferRowRouting
    /// Shared clear use case. The parent VM calls it to clear a tab; the mounted tab's
    /// list view model observes its `clearedSignals` to re-query, since clearing emits
    /// no SDK transfer event of its own. Shared so both see the same emitter.
    let clearTransfersUseCase: any ClearTransfersUseCaseProtocol
}
