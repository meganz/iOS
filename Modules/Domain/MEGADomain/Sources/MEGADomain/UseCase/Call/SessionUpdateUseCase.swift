import MEGASwift

public protocol SessionUpdateUseCaseProtocol: Sendable {
    func monitorOnSessionUpdate() -> AnyAsyncSequence<ChatSessionEntity>
}

public struct SessionUpdateUseCase<T: SessionUpdateRepositoryProtocol>: SessionUpdateUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnSessionUpdate() -> AnyAsyncSequence<ChatSessionEntity> {
        repository.sessionUpdate
            .eraseToAnyAsyncSequence()
    }
}
