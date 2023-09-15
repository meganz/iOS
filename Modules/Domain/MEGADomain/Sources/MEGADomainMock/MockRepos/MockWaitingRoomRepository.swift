import MEGADomain

public final class MockWaitingRoomRepository: WaitingRoomRepositoryProtocol {
    public static var newRepo: MockWaitingRoomRepository {
        MockWaitingRoomRepository()
    }
    
    private let myUserName: String
    private let joinChatResult: Result<ChatRoomEntity, CallErrorEntity>
    
    public init(
        userName: String = "Test User",
        joinChatResult: Result<ChatRoomEntity, CallErrorEntity> = .success(.init())
    ) {
        self.myUserName = userName
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
