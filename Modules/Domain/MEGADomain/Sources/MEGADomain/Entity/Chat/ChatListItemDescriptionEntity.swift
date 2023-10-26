public struct ChatListItemDescriptionEntity: Sendable {
    public let description: String
    
    public init(description: String) {
        self.description = description
    }
}

extension ChatListItemDescriptionEntity: Equatable {
    public static func == (
        lhs: ChatListItemDescriptionEntity,
        rhs: ChatListItemDescriptionEntity
    ) -> Bool {
        lhs.description == rhs.description
    }
}
