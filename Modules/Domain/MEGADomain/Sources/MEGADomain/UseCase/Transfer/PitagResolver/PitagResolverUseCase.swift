/// Protocol for resolving PITAG entities
/// Use this to determine the appropriate PITAG targets and triggers
public protocol PitagResolverUseCaseProtocol: Sendable {
    /// Determines the PITAG target based on the combination of chats and users being sent to
    /// - Parameters:
    ///   - chats: List of chat rooms to send to
    ///   - users: List of individual users to send to
    /// - Returns: The appropriate `PitagTargetEntity`
    func resolvePitagTarget(
        forChats chats: [ChatListItemEntity],
        users: [UserEntity]
    ) -> PitagTargetEntity
}

// MARK: - Use Case

public struct PitagResolverUseCase: PitagResolverUseCaseProtocol {
    private let strategies: [any PitagTargetResolverProtocol]
    
    public init(
        strategies: [any PitagTargetResolverProtocol] = [
            MultipleChatsResolver(),
            Chat1To1UserResolver(),
            NoteToSelfResolver(),
            ChatGroupResolver(),
            Chat1To1ChatResolver()
        ]
    ) {
        self.strategies = strategies
    }
    
    public func resolvePitagTarget(
        forChats chats: [ChatListItemEntity],
        users: [UserEntity]
    ) -> PitagTargetEntity {
        strategies
            .lazy
            .compactMap { $0.resolve(forChats: chats, users: users) }
            .first ?? .notApplicable
    }
}
