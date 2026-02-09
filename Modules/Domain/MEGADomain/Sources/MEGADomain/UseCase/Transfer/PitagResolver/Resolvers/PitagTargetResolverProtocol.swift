/// Chain of Responsibility pattern for resolving PITAG targets.
/// Each strategy is evaluated in order; the first match wins.
public protocol PitagTargetResolverProtocol: Sendable {
    /// Attempts to resolve a PITAG target.
    /// Returns: A `PitagTargetEntity` if this handler can process the request, otherwise `nil`
    func resolve(forChats chats: [ChatListItemEntity], users: [UserEntity]) -> PitagTargetEntity?
}
