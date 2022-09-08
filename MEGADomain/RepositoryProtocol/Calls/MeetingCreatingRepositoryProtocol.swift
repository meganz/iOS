protocol MeetingCreatingRepositoryProtocol {
    func getUsername() -> String
    func getCall(forChatId chatId: UInt64) -> CallEntity?
    func startCall(
        meetingName: String,
        enableVideo: Bool,
        enableAudio: Bool,
        speakRequest: Bool,
        waitingRoom: Bool,
        allowNonHostToAddParticipants: Bool,
        completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void
    )
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping (Result<Void, MEGASDKErrorType>) -> Void, karereInitCompletion: @escaping () -> Void)
    func createChatLink(forChatId chatId: UInt64)
}
