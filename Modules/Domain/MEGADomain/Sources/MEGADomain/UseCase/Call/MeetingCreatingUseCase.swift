// MARK: - Use case protocol -
public protocol MeetingCreatingUseCaseProtocol: Sendable {
    func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity
    var username: String { get }
    func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        karereInitCompletion: (() -> Void)?
    ) async throws
    func checkChatLink(link: String) async throws -> ChatRoomEntity
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
    
    public func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity {
        try await meetingCreatingRepo.joinChat(forChatId: chatId, userHandle: userHandle)
    }
    
    public var username: String {
        if let email = meetingCreatingRepo.userEmail,
           let userName = userStoreRepo.userDisplayName(forEmail: email),
           userName.isNotEmpty {
            return userName
        }
        return meetingCreatingRepo.username
    }
    
    public func checkChatLink(link: String) async throws -> ChatRoomEntity {
        try await meetingCreatingRepo.checkChatLink(link: link)
    }

    public func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        karereInitCompletion: (() -> Void)? = nil
    ) async throws {
        try await meetingCreatingRepo
            .createEphemeralAccountAndJoinChat(
                firstName: firstName,
                lastName: lastName,
                link: link,
                karereInitCompletion: karereInitCompletion
            )
    }
    
}
