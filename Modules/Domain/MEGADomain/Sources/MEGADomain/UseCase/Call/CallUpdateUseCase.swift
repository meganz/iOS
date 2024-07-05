import MEGASwift

public protocol CallUpdateUseCaseProtocol: Sendable {
    func monitorOnCallUpdate() -> AnyAsyncThrowingSequence<CallEntity, any Error>
}

public struct CallUpdateUseCase<T: CallUpdateRepositoryProtocol>: CallUpdateUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnCallUpdate() -> AnyAsyncThrowingSequence<CallEntity, any Error> {
        repository.callUpdate
            .eraseToAnyAsyncThrowingSequence()
    }
}
