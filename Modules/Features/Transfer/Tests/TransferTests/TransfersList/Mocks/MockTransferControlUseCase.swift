import MEGADomain
import Transfer

final class MockTransferControlUseCase: TransferControlUseCaseProtocol, @unchecked Sendable {
    private(set) var pausedTransfers: [TransferEntity] = []
    private(set) var resumedTransfers: [TransferEntity] = []
    var pauseError: (any Error)?
    var resumeError: (any Error)?

    init() {}

    func pauseTransfer(_ transfer: TransferEntity) async throws {
        pausedTransfers.append(transfer)
        if let pauseError { throw pauseError }
    }

    func resumeTransfer(_ transfer: TransferEntity) async throws {
        resumedTransfers.append(transfer)
        if let resumeError { throw resumeError }
    }
}
