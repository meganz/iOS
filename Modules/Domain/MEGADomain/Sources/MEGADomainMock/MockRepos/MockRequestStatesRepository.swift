import MEGADomain
import MEGASwift

public final class MockRequestStatesRepository: RequestStatesRepositoryProtocol {
    public static var newRepo: MockRequestStatesRepository {
        MockRequestStatesRepository()
    }

    public let requestStartUpdates: AnyAsyncSequence<RequestEntity>
    public let requestUpdates: AnyAsyncSequence<RequestEntity>
    public let requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>>
    public let requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>>

    public init(
        requestStartUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestUpdates: AnyAsyncSequence<RequestEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestTemporaryErrorUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        requestFinishUpdates: AnyAsyncSequence<Result<RequestEntity, ErrorEntity>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.requestStartUpdates = requestStartUpdates
        self.requestUpdates = requestUpdates
        self.requestTemporaryErrorUpdates = requestTemporaryErrorUpdates
        self.requestFinishUpdates = requestFinishUpdates
    }
}
