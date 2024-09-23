import MEGADomain

public final class MockMeetingCreatingUseCase: MeetingCreatingUseCaseProtocol {
    private let userName: String
    private let createMeetingResult: Result<ChatRoomEntity, CallErrorEntity>
    private let createEphemeralAccountCompletion: Result<Void, GenericErrorEntity>
    private let joinCallCompletion: Result<ChatRoomEntity, CallErrorEntity>
    private let checkChatLinkCompletion: Result<ChatRoomEntity, CallErrorEntity>
    
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
        try createMeetingResult.get()
    }
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        try joinCallCompletion.get()
    }
    
    public var username: String {
        userName
    }
    
    public func checkChatLink(link: String) async throws -> ChatRoomEntity {
        try checkChatLinkCompletion.get()
    }
    
    public func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        karereInitCompletion: (() -> Void)?
    ) async throws {
        try createEphemeralAccountCompletion.get()
    }
}
