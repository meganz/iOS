import MEGASwift

public protocol ChatRoomUpdateUseCaseProtocol: Sendable {
    func monitorOnChatRoomUpdate() -> AnyAsyncThrowingSequence<ChatRoomEntity, any Error>
}

public struct ChatRoomUpdateUseCase<T: ChatRoomUpdateRepositoryProtocol>: ChatRoomUpdateUseCaseProtocol  {
    
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }

    public func monitorOnChatRoomUpdate() -> AnyAsyncThrowingSequence<ChatRoomEntity, any Error> {
        repository.chatRoomUpdate
            .eraseToAnyAsyncThrowingSequence()
    }
}
