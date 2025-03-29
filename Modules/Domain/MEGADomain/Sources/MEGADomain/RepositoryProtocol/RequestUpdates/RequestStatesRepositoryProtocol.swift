import MEGASwift

public protocol RequestStatesRepositoryProtocol: RepositoryProtocol, Sendable {
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
    var requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> { get }
}
