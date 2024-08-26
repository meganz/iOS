import MEGADomain
import MEGASwift

public struct MockChatRoomUpdateUseCase: ChatRoomUpdateUseCaseProtocol {
    private let monitorChatRoomUpdateSequenceResult: AnyAsyncSequence<ChatRoomEntity>

    public init(
        monitorChatRoomUpdateSequenceResult: AnyAsyncSequence<ChatRoomEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.monitorChatRoomUpdateSequenceResult = monitorChatRoomUpdateSequenceResult
    }
    
    public func monitorOnChatRoomUpdate() -> AnyAsyncSequence<ChatRoomEntity> {
        monitorChatRoomUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
}
