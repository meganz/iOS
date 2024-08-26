import MEGASwift

public protocol CallUpdateUseCaseProtocol: Sendable {
    func monitorOnCallUpdate() -> AnyAsyncSequence<CallEntity>
}

public struct CallUpdateUseCase<T: CallUpdateRepositoryProtocol>: CallUpdateUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnCallUpdate() -> AnyAsyncSequence<CallEntity> {
        repository.callUpdate
            .eraseToAnyAsyncSequence()
    }
}
