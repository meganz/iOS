import MEGADomain
import MEGASwift

public struct MockChatRoomUpdateUseCase: ChatRoomUpdateUseCaseProtocol {
    private let monitorChatRoomUpdateSequenceResult: AnyAsyncSequence<ChatRoomEntity>
    private let chatRoomUpdateContinuation: AsyncStream<ChatRoomEntity>.Continuation

    public init() {
        let (stream, continuation) = AsyncStream
            .makeStream(of: ChatRoomEntity.self)
        self.monitorChatRoomUpdateSequenceResult = AnyAsyncSequence(stream)
        self.chatRoomUpdateContinuation = continuation
    }
    
    public func monitorOnChatRoomUpdate() -> AnyAsyncSequence<ChatRoomEntity> {
        monitorChatRoomUpdateSequenceResult
            .eraseToAnyAsyncSequence()
    }
    
    public func sendChatRoomUpdate(_ chatRoom: ChatRoomEntity) async throws {
        chatRoomUpdateContinuation.yield(chatRoom)
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
