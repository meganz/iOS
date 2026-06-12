import MEGADomain

protocol TransferListUseCaseProtocol: Sendable {
    func hasCompletedTransfers() -> Bool
    func hasFailedTransfers() -> Bool
    func areTransfersPaused() -> Bool
    func pauseTransfers()
    func resumeTransfers()
    func cancelTransfers()
}

struct TransferListUseCase: TransferListUseCaseProtocol {
    private let inventoryUseCase: any TransferInventoryUseCaseProtocol
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol
    private let filteringUserTransfers: Bool

    init(
        inventoryUseCase: some TransferInventoryUseCaseProtocol,
        transfersListenerUseCase: some TransfersListenerUseCaseProtocol,
        filteringUserTransfers: Bool
    ) {
        self.inventoryUseCase = inventoryUseCase
        self.transfersListenerUseCase = transfersListenerUseCase
        self.filteringUserTransfers = filteringUserTransfers
    }

    func hasCompletedTransfers() -> Bool {
        completedTransfers.contains(where: \.isVisibleOnCompletedTab)
    }

    func hasFailedTransfers() -> Bool {
        completedTransfers.contains(where: \.isVisibleOnFailedTab)
    }

    func areTransfersPaused() -> Bool {
        transfersListenerUseCase.areTransfersPaused()
    }

    func pauseTransfers() {
        transfersListenerUseCase.pauseTransfers()
    }

    func resumeTransfers() {
        transfersListenerUseCase.resumeTransfers()
    }
    
    func cancelTransfers() {
        transfersListenerUseCase.cancelTransfers()
    }

    private var completedTransfers: [TransferEntity] {
        inventoryUseCase.completedTransfers(filteringUserTransfers: filteringUserTransfers)
    }
}
