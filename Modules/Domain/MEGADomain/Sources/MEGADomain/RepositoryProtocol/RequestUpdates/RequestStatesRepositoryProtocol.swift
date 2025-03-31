import MEGASwift

public struct RequestResponseEntity: Sendable {
    public let requestEntity: RequestEntity
    public let error: ErrorEntity
    
    var isSuccess: Bool {
        error.type == .ok
    }
    
    public init(requestEntity: RequestEntity, error: ErrorEntity) {
        self.requestEntity = requestEntity
        self.error = error
    }
}

public protocol RequestStatesRepositoryProtocol: RepositoryProtocol, Sendable {
    var requestStartUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestUpdates: AnyAsyncSequence<RequestEntity> { get }
    var requestTemporaryErrorUpdates: AnyAsyncSequence<RequestResponseEntity> { get }
    var requestFinishUpdates: AnyAsyncSequence<RequestResponseEntity> { get }
}

public extension RequestStatesRepositoryProtocol {
    /// A stream of `RequestEntity` indicating request finished sucessfully (error type is ok)
    var completedRequestUpdates: AnyAsyncSequence<RequestEntity> {
        requestFinishUpdates
            .compactMap { $0.isSuccess ? $0.requestEntity : nil }
            .eraseToAnyAsyncSequence()
    }
}
