import Combine

public protocol CallSessionUseCaseProtocol {
    mutating func onCallSessionUpdate() -> AnyPublisher<ChatSessionEntity, Never>
}

public struct CallSessionUseCase<T: CallSessionRepositoryProtocol>: CallSessionUseCaseProtocol {
    private var repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    mutating public func onCallSessionUpdate() -> AnyPublisher<MEGADomain.ChatSessionEntity, Never> {
        repository.onCallSessionUpdate()
    }
}
