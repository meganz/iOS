import MEGASwift

public protocol SessionUpdateRepositoryProtocol: Sendable {
    /// - Returns: `AnyAsyncSequence` that will yield `ChatSessionEntity, CallEntity` items until sequence terminated.
    var sessionUpdate: AnyAsyncSequence<(ChatSessionEntity, CallEntity)> { get }
}
