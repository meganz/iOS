import MEGASwift

public protocol EventRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Listen to event updates
    /// - Returns: an AsyncSequence that emits event updates
    var event: AnyAsyncSequence<EventEntity> { get }
}
