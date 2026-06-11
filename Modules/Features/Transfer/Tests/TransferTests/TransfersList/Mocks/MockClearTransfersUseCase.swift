import MEGASwift
import Transfer

final class MockClearTransfersUseCase: ClearTransfersUseCaseProtocol, @unchecked Sendable {
    private(set) var clearCompletedTransfersCalledTimes = 0
    private(set) var clearFailedTransfersCalledTimes = 0

    init() {}

    func clearCompletedTransfers() {
        clearCompletedTransfersCalledTimes += 1
    }

    func clearFailedTransfers() {
        clearFailedTransfersCalledTimes += 1
    }

    var clearedSignals: AnyAsyncSequence<Void> {
        AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()
    }
}
