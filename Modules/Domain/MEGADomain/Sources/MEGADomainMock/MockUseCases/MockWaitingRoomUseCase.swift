import MEGADomain

public final class MockWaitingRoomUseCase: WaitingRoomUseCaseProtocol {
    
    private let myUserName: String
    private let joinChatResult: Result<ChatRoomEntity, CallErrorEntity>
    
    public init(
        myUserName: String = "",
        joinChatResult: Result<ChatRoomEntity, CallErrorEntity> = .success(.init())
    ) {
        self.myUserName = myUserName
        self.joinChatResult = joinChatResult
    }
    
    public func userName() -> String {
        myUserName
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        switch joinChatResult {
        case .success(let chatRoom):
            return chatRoom
        case .failure(let error):
            throw error
        }
    }
}
