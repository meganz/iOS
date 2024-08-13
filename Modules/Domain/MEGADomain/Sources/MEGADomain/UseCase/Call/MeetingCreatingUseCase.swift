// MARK: - Use case protocol -
public protocol MeetingCreatingUseCaseProtocol {
    func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func username() -> String
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createChatLink(forChatId chatId: UInt64)
}

// MARK: - Use case implementation -
public struct MeetingCreatingUseCase<T: MeetingCreatingRepositoryProtocol, U: UserStoreRepositoryProtocol>: MeetingCreatingUseCaseProtocol {

    private let meetingCreatingRepo: T
    private let userStoreRepo: U
    
    public init(
        meetingCreatingRepo: T,
        userStoreRepo: U
    ) {
        self.meetingCreatingRepo = meetingCreatingRepo
        self.userStoreRepo = userStoreRepo
    }
        
    public func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity {
        try await meetingCreatingRepo.createMeeting(startCall)
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        meetingCreatingRepo.joinChat(forChatId: chatId, userHandle: userHandle, completion: completion)
    }
    
    public func username() -> String {
        if let email = meetingCreatingRepo.userEmail(),
           let userName = userStoreRepo.userDisplayName(forEmail: email),
           userName.isNotEmpty {
            return userName
        }
        return meetingCreatingRepo.username()
    }
    
    public func createChatLink(forChatId chatId: UInt64) {
        meetingCreatingRepo.createChatLink(forChatId: chatId)
    }
    
    public func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        meetingCreatingRepo.checkChatLink(link: link, completion: completion)
    }

    public func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void) {
        meetingCreatingRepo.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link, completion: completion, karereInitCompletion: karereInitCompletion)
    }
    
}
