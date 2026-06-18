@testable import Transfer

final class MockTransferListUseCase: TransferListUseCaseProtocol, @unchecked Sendable {
    private let paused: Bool

    private(set) var pauseTransfersCalledTimes = 0
    private(set) var resumeTransfersCalledTimes = 0
    private(set) var cancelTransfersCalledTimes = 0

    init(paused: Bool = false) {
        self.paused = paused
    }

    func areTransfersPaused() -> Bool { paused }
    func pauseTransfers() { pauseTransfersCalledTimes += 1 }
    func resumeTransfers() { resumeTransfersCalledTimes += 1 }
    func cancelTransfers() { cancelTransfersCalledTimes += 1 }
}
