import MEGADomain
import Transfer

final class MockTransferControlRepository: TransferControlRepositoryProtocol, @unchecked Sendable {
    private(set) var pausedTransfers: [TransferEntity] = []
    private(set) var resumedTransfers: [TransferEntity] = []
    private(set) var retriedTransfers: [TransferEntity] = []
    private(set) var cancelledTransfers: [TransferEntity] = []
    var pauseError: (any Error)?
    var resumeError: (any Error)?
    var retryError: (any Error)?
    var cancelError: (any Error)?

    static var newRepo: MockTransferControlRepository {
        MockTransferControlRepository()
    }

    init() {}

    func pauseTransfer(_ transfer: TransferEntity) async throws {
        pausedTransfers.append(transfer)
        if let pauseError { throw pauseError }
    }

    func resumeTransfer(_ transfer: TransferEntity) async throws {
        resumedTransfers.append(transfer)
        if let resumeError { throw resumeError }
    }

    func retryTransfer(_ transfer: TransferEntity) async throws {
        retriedTransfers.append(transfer)
        if let retryError { throw retryError }
    }

    func cancelTransfer(_ transfer: TransferEntity) async throws {
        cancelledTransfers.append(transfer)
        if let cancelError { throw cancelError }
    }
}
