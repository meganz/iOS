import MEGADomain

protocol TransferListUseCaseProtocol: Sendable {
    func areTransfersPaused() -> Bool
    func pauseTransfers()
    func resumeTransfers()
    func cancelTransfers()
}

struct TransferListUseCase: TransferListUseCaseProtocol {
    private let transfersListenerUseCase: any TransfersListenerUseCaseProtocol

    init(transfersListenerUseCase: some TransfersListenerUseCaseProtocol) {
        self.transfersListenerUseCase = transfersListenerUseCase
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
}
