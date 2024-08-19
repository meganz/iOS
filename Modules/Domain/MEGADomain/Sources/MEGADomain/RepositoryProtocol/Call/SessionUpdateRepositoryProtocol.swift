import MEGASwift

public protocol SessionUpdateRepositoryProtocol: Sendable {
    /// - Returns: `AnyAsyncSequence` that will yield `ChatSessionEntity` items until sequence terminated.
    var sessionUpdate: AnyAsyncSequence<ChatSessionEntity> { get }
}
