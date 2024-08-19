import MEGADomain
import MEGASwift

public struct MockChatRoomUpdateUseCase: ChatRoomUpdateUseCaseProtocol {
    private let monitorChatRoomUpdateSequenceResult: AnyAsyncThrowingSequence<ChatRoomEntity, any Error>

    public init(
        monitorChatRoomUpdateSequenceResult: AnyAsyncThrowingSequence<ChatRoomEntity, any Error> = EmptyAsyncSequence().eraseToAnyAsyncThrowingSequence()
    ) {
        self.monitorChatRoomUpdateSequenceResult = monitorChatRoomUpdateSequenceResult
    }
    
    public func monitorOnChatRoomUpdate() -> AnyAsyncThrowingSequence<ChatRoomEntity, any Error> {
        monitorChatRoomUpdateSequenceResult
            .eraseToAnyAsyncThrowingSequence()
    }
}
