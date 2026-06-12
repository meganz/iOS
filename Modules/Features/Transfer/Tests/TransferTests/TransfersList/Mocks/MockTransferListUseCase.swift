@testable import Transfer

final class MockTransferListUseCase: TransferListUseCaseProtocol, @unchecked Sendable {
    var hasCompletedTransfersResult: Bool
    var hasFailedTransfersResult: Bool
    private let paused: Bool

    private(set) var pauseTransfersCalledTimes = 0
    private(set) var resumeTransfersCalledTimes = 0
    private(set) var cancelTransfersCalledTimes = 0

    init(
        hasCompletedTransfers: Bool = false,
        hasFailedTransfers: Bool = false,
        paused: Bool = false
    ) {
        self.hasCompletedTransfersResult = hasCompletedTransfers
        self.hasFailedTransfersResult = hasFailedTransfers
        self.paused = paused
    }

    func hasCompletedTransfers() -> Bool { hasCompletedTransfersResult }
    func hasFailedTransfers() -> Bool { hasFailedTransfersResult }
    func areTransfersPaused() -> Bool { paused }
    func pauseTransfers() { pauseTransfersCalledTimes += 1 }
    func resumeTransfers() { resumeTransfersCalledTimes += 1 }
    func cancelTransfers() { cancelTransfersCalledTimes += 1 }
}
