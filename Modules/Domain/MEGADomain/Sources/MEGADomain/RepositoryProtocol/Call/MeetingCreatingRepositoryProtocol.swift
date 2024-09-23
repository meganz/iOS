public protocol MeetingCreatingRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Retrieves the username of the current user.
    ///
    /// - Returns: A `String` representing the username.
    var username: String { get }
    /// Retrieves the email address of the current user.
    /// 
    /// - Returns: An optional `String` containing the user's email address, or `nil` if the email is not available.
    var userEmail: String? { get }
    /// Creates a new meeting based on the provided `CreateMeetingNowEntity`.
    ///
    /// - Parameter startCall: An instance of `CreateMeetingNowEntity` containing the details for the meeting to be created.
    /// - Returns: A `ChatRoomEntity` representing the newly created meeting.
    /// - Throws: An error if the meeting creation fails.
    func createMeeting(_ startCall: CreateMeetingNowEntity) async throws -> ChatRoomEntity
    /// Joins a chat room with the specified chat ID and user handle.
    /// 
    /// - Parameters:
    ///   - chatId: The unique identifier of the chat room to join.
    ///   - userHandle: The unique identifier of the user joining the chat room.
    /// - Returns: A `ChatRoomEntity` representing the joined chat room.
    /// - Throws: An error if the operation fails.
    func joinChat(forChatId chatId: UInt64, userHandle: UInt64) async throws -> ChatRoomEntity
    /// Checks the validity of a chat link and returns the corresponding chat room entity.
    /// 
    /// This function takes a chat link as input, validates it, and retrieves the associated chat room entity.
    /// 
    /// - Parameter link: A `String` representing the chat link to be checked.
    /// - Returns: A `ChatRoomEntity` corresponding to the provided chat link.
    /// - Throws: An error if the chat link is invalid or if there is an issue retrieving the chat room entity.
    func checkChatLink(link: String) async throws -> ChatRoomEntity
    /// Creates an ephemeral account and joins a chat.
    ///
    /// This function is responsible for creating a temporary account and 
    /// joining a specified chat. It is typically used for scenarios where 
    /// a user is not logging into an account..
    ///
    /// - Parameters:
    ///   - chatId: The identifier of the chat to join.
    ///   - completion: A closure that gets called with the result of the operation.
    /// - Returns: Void
    /// - Throws: An error if there is a problem creating or joining the chat.
    func createEphemeralAccountAndJoinChat(
        firstName: String,
        lastName: String,
        link: String,
        karereInitCompletion: (() -> Void)?
    ) async throws
}
