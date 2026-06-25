import MEGADomain
import MEGASwift

final class MockLastPurgeUseCase: LastPurgeUseCaseProtocol, @unchecked Sendable {
    private let _lastPurgeSequence: AnyAsyncSequence<LastPurgeEventEntity>
    private(set) var acknowledgedTimestamps: [Int64] = []

    init(lastPurgeSequence: AnyAsyncSequence<LastPurgeEventEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self._lastPurgeSequence = lastPurgeSequence
    }

    var lastPurgeEventSequence: AnyAsyncSequence<LastPurgeEventEntity> { _lastPurgeSequence }

    func acknowledgeLastPurge(timestamp: Int64) async throws {
        acknowledgedTimestamps.append(timestamp)
    }
}
