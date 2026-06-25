import MEGASwift

public protocol LastPurgeRepositoryProtocol: RepositoryProtocol, Sendable {
    var lastPurgeSequence: AnyAsyncSequence<LastPurgeEventEntity> { get }
    func acknowledgeLastPurge(timestamp: Int64) async throws
}
