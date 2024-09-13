import MEGASwift

public protocol SessionUpdateUseCaseProtocol: Sendable {
    func monitorOnSessionUpdate() -> AnyAsyncSequence<(ChatSessionEntity, CallEntity)>
}

public struct SessionUpdateUseCase<T: SessionUpdateRepositoryProtocol>: SessionUpdateUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnSessionUpdate() -> AnyAsyncSequence<(ChatSessionEntity, CallEntity)> {
        repository.sessionUpdate
            .eraseToAnyAsyncSequence()
    }
}
