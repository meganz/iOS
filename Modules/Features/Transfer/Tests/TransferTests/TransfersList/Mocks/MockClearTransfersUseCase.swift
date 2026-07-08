import MEGASwift
import Transfer

final class MockClearTransfersUseCase: ClearTransfersUseCaseProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfersCalledTimes = 0
    private(set) var clearFailedTransfersCalledTimes = 0
    private(set) var clearedTransferTags: [Int] = []

    let clearedSignals: AnyAsyncSequence<Void>

    init(clearedSignals: [Void] = []) {
        self.clearedSignals = clearedSignals.async.eraseToAnyAsyncSequence()
    }

    func clearCompletedTransfers() {
        clearCompletedTransfersCalledTimes += 1
    }

    func clearFailedTransfers() {
        clearFailedTransfersCalledTimes += 1
    }

    func clearTransfer(tag: Int) {
        clearedTransferTags.append(tag)
    }
}
