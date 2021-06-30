// MARK: - Use case protocol -
protocol MeetingCreatingUseCaseProtocol {
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void)
    func createChatLink(forChatId chatId: UInt64)
}

// MARK: - Use case implementation -
struct MeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {

    private let repository: MeetingCreatingRepositoryProtocol
    
    init(repository: MeetingCreatingRepositoryProtocol) {
        self.repository = repository
    }
    
    func startChatCall(meetingName: String, enableVideo: Bool, enableAudio: Bool,  completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.startChatCall(meetingName: meetingName, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.joinChatCall(forChatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func getUsername() -> String {
        repository.getUsername()
    }
    
    func getCall(forChatId chatId: UInt64) -> CallEntity? {
        repository.getCall(forChatId: chatId)
    }
    
    func createChatLink(forChatId chatId: UInt64) {
        repository.createChatLink(forChatId: chatId)
    }
    
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallsErrorEntity>) -> Void) {
        repository.checkChatLink(link: link, completion: completion)
    }

    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void) {
        repository.createEphemeralAccountAndJoinChat(firstName: firstName, lastName: lastName, link: link, completion: completion)
    }
    
}
