import MEGASwift

public protocol ChatRoomUpdateUseCaseProtocol: Sendable {
    func monitorOnChatRoomUpdate() -> AnyAsyncSequence<ChatRoomEntity>
}

public struct ChatRoomUpdateUseCase<T: ChatRoomUpdateRepositoryProtocol>: ChatRoomUpdateUseCaseProtocol {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnChatRoomUpdate() -> AnyAsyncSequence<ChatRoomEntity> {
        repository.chatRoomUpdate
            .eraseToAnyAsyncSequence()
    }
}
