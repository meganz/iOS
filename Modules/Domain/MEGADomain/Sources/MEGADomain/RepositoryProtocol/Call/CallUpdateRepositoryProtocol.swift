import MEGASwift

public protocol CallUpdateRepositoryProtocol: Sendable {
    /// - Returns: `AnyAsyncSequence` that will yield `CallEntity` items until sequence terminated.
    var callUpdate: AnyAsyncSequence<CallEntity> { get }
}
