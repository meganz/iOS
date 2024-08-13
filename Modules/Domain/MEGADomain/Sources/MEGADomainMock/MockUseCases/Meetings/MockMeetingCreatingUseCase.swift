import MEGADomain

public final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    private let userName: String
    private let createMeetingResult: Result<ChatRoomEntity, CallErrorEntity>
    private let createEphemeralAccountCompletion: Result<Void, GenericErrorEntity>
    private let joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity>
    private let checkChatLinkCompletion: Result<ChatRoomEntity, CallErrorEntity>
    
    private var createChatLink_calledTimes = 0
    
    public init(userName: String = "Test Name",
                createMeetingResult: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
                createEphemeralAccountCompletion: Result<Void, GenericErrorEntity> = .failure(GenericErrorEntity()),
                joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic),
                checkChatLinkCompletion: Result<ChatRoomEntity, CallErrorEntity> = .failure(.generic)
    ) {
        self.userName = userName
        self.createMeetingResult = createMeetingResult
        self.createEphemeralAccountCompletion = createEphemeralAccountCompletion
        self.joinCallCompletion = joinCallCompletion
        self.checkChatLinkCompletion = checkChatLinkCompletion
    }
    
    public func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity {
        switch createMeetingResult {
        case .success(let chatRoom):
            return chatRoom
        case .failure(let error):
            throw error
        }
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(joinCallCompletion)
    }
    
    public func username() -> String {
        userName
    }
    
    public func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        completion(checkChatLinkCompletion)
    }
    
    public func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void) {
        completion(createEphemeralAccountCompletion)
    }
    
    public func createChatLink(forChatId chatId: UInt64) {
        createChatLink_calledTimes += 1
    }
}
