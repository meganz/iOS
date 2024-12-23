import MEGADomain

final class TransfersWidgetViewModel: NSObject {
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol
    private let transferInventoryUseCase: any TransferInventoryUseCaseProtocol
    
    init(
        transfersListenerUseCase: some TransfersListenerUseCaseProtocol,
        transfersInventoryUseCase: some TransferInventoryUseCaseProtocol
    ) {
        self.transfersListenerUseCase = transfersListenerUseCase
        self.transferInventoryUseCase = transfersInventoryUseCase
    }
    
    func pauseQueuedTransfers() {
        transfersListenerUseCase.pauseQueuedTransfers()
    }
    
    func resumeQueuedTransfers() {
        transfersListenerUseCase.resumeQueuedTransfers()
        
        startPendingUploadTransferIfNeeded()
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
