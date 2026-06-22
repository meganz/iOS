import MEGASwift
import Transfer

final class MockClearTransfersUseCase: ClearTransfersUseCaseProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfersCalledTimes = 0
    private(set) var clearFailedTransfersCalledTimes = 0
    private(set) var clearedTransferTags: [Int] = []

    init() {}

    func clearCompletedTransfers() {
        clearCompletedTransfersCalledTimes += 1
    }

    func clearFailedTransfers() {
        clearFailedTransfersCalledTimes += 1
    }

    func clearTransfer(tag: Int) {
        clearedTransferTags.append(tag)
    }

    var clearedSignals: AnyAsyncSequence<Void> {
        AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()
    }
}
