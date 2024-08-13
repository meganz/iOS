public protocol MeetingCreatingRepositoryProtocol: RepositoryProtocol, Sendable {
    func username() -> String
    func userEmail() -> String?
    func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func checkChatLink(link: String, completion: @escaping (Result<ChatRoomEntity, CallErrorEntity>) -> Void)
    func createEphemeralAccountAndJoinChat(firstName: String, lastName: String, link: String, completion: @escaping @Sendable (Result<Void, GenericErrorEntity>) -> Void, karereInitCompletion: @escaping () -> Void)
    func createChatLink(forChatId chatId: UInt64)
}
