import MEGADomain

final class TransfersWidgetViewModel: NSObject {
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    private let nodeUseCase: any NodeUseCaseProtocol
    private let router: any NodeNavigationRouting
    
    init(
        transfersListenerUseCase: some TransfersListenerUseCaseProtocol,
        transfersInventoryUseCase: some TransferInventoryUseCaseProtocol,
        nodeUseCase: some NodeUseCaseProtocol,
        router: some NodeNavigationRouting
    ) {
        self.transfersListenerUseCase = transfersListenerUseCase
        self.transferInventoryUseCase = transfersInventoryUseCase
        self.nodeUseCase = nodeUseCase
        self.router = router
    }
    
    func pauseQueuedTransfers() {
        transfersListenerUseCase.pauseQueuedTransfers()
    }
    
    func resumeQueuedTransfers() {
        transfersListenerUseCase.resumeQueuedTransfers()
        
        startPendingUploadTransferIfNeeded()
    }
    
    func navigateToParentNode(_ node: NodeEntity) {
        Task { [weak self] in
            guard let nodeHierarchy = await self?.nodeUseCase.parentsForHandle(node.handle) else { return }
            let nodeAccess = self?.nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)
            
            await self?.router.navigateThroughNodeHierarchy(
                nodeHierarchy,
                isOwnNode: nodeAccess == .owner,
                isInRubbishBin: node.nodeType == .rubbish
            )
        }
    }
    
    private func startPendingUploadTransferIfNeeded() {
        guard !areQueuedTransfersPaused() else {
            return
        }
        
        let transfers = transferInventoryUseCase.uploadTransfers(filteringUserTransfers: false)
        
        if !transfers.contains(where: { $0.state == .active }) {
            Helper.startFirstPendingUploadTransfer()
        }
    }
    
    private func areQueuedTransfersPaused() -> Bool {
        transfersListenerUseCase.areQueuedTransfersPaused()
    }
}
