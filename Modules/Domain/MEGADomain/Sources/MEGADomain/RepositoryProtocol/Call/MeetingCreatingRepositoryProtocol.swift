public protocol MeetingCreatingRepositoryProtocol: RepositoryProtocol, Sendable {
    func username() -> String
    func userEmail() -> String?
    func createMeeting(_ startCall: StartCallEntity) async throws -> ChatRoomEntity
    func joinChatCall(forChatId chatId: UInt64, enableVideo: Bool, enableAudio: Bool, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping @Sendable (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void)
    func createChatLink(forChatId chatId: UInt64)
}
