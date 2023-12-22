import MEGADomain

// MARK: - Use case protocol -
protocol MeetingCreatingUseCaseProtocol {
    func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createChatLink(forChatId chatId: UInt64)
}

// MARK: - Use case implementation -
struct MeetingCreatingUseCase<T: MeetingCreatingRepositoryProtocol, U: UserStoreRepositoryProtocol>: MeetingCreatingUseCaseProtocol {

    private let meetingCreatingRepo: T
    private let userStoreRepo: U
    
    init(
        meetingCreatingRepo: T,
        userStoreRepo: U
    ) {
        self.meetingCreatingRepo = meetingCreatingRepo
        self.userStoreRepo = userStoreRepo
    }
        
    func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity {
        try await meetingCreatingRepo.createMeeting(startCall)
    }
    
    func joinCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        meetingCreatingRepo.joinChatCall(forChatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, userHandle: userHandle, completion: completion)
    }
    
    func getUsername() -> String {
        if let email = meetingCreatingRepo.userEmail(),
           let userName = userStoreRepo.userDisplayName(forEmail: email),
           userName.isNotEmpty {
            return userName
        }
        return meetingCreatingRepo.username()
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        meetingCreatingRepo.getCall(forChatId: chatId)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        meetingCreatingRepo.createChatLink(forChatId: chatId)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void) {
        meetingCreatingRepo.checkChatLink(link: link, completion: completion)
    }

    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void) {
        meetingCreatingRepo.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link, completion: completion, karereInitCompletion: karereInitCompletion)
    }
    
}
