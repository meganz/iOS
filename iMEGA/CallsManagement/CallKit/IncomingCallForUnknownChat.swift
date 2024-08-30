import MEGADomain

/// A structure representing an incoming VoIP call in a chat room that is not yet known to the app's local cache.
/// This situation arises when the user is added to a new chat while the app is not active, and an incoming call is received before the chat information has been fetched and cached.
struct IncomingCallForUnknownChat {
    let chatId: ChatIdEntity
    let callUUID: UUID
    
    /// A closure to capture how to answer the call when user answer through CallKit but chat room is not yet fetched. When chat connection update with online status is received, this will be called to actually connect the call.
    var answeredCompletion: (() -> Void)?
}
