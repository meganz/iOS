import Foundation

public struct ChatListItemAvatarEntity: Sendable {
    public let primaryAvatarData: Data?
    public let secondaryAvatarData: Data?
    
    public init(
        primaryAvatarData: Data?,
        secondaryAvatarData: Data?
    ) {
        self.primaryAvatarData = primaryAvatarData
        self.secondaryAvatarData = secondaryAvatarData
    }
}

extension ChatListItemAvatarEntity: Equatable {
    public static func == (
        lhs: ChatListItemAvatarEntity,
        rhs: ChatListItemAvatarEntity
    ) -> Bool {
        lhs.primaryAvatarData == rhs.primaryAvatarData &&
        lhs.secondaryAvatarData == rhs.secondaryAvatarData
    }
}
