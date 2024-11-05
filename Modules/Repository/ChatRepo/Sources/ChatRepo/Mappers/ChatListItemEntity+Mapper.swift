import MEGAChatSdk
import MEGADomain

public extension MEGAChatListItem {
    func toChatListItemEntity() -> ChatListItemEntity {
        ChatListItemEntity(with: self)
    }
}

public extension [MEGAChatListItem] {
    func toChatListItemEntities() -> [ChatListItemEntity] {
        map { $0.toChatListItemEntity() }
    }
}

fileprivate extension ChatListItemEntity {
    init(with chatListItem: MEGAChatListItem) {
        self.init(
            chatId: chatListItem.chatId,
            title: chatListItem.title,
            changeType: chatListItem.changes.toChatListItemChangeEntity(),
            ownPrivilege: chatListItem.ownPrivilege.toChatRoomPrivilegeEntity(),
            unreadCount: chatListItem.unreadCount,
            previewersCount: chatListItem.previewersCount,
            group: chatListItem.isGroup,
            publicChat: chatListItem.isPublicChat,
            preview: chatListItem.isPreview,
            active: chatListItem.isActive,
            deleted: chatListItem.isDeleted,
            meeting: chatListItem.isMeeting,
            peerHandle: chatListItem.peerHandle,
            lastMessage: chatListItem.lastMessage,
            lastMessageId: chatListItem.lastMessageId,
            lastMessageType: chatListItem.lastMessageType.toChatMessageTypeEntity(),
            lastMessageSender: chatListItem.lastMessageSender,
            lastMessageDate: chatListItem.lastMessageDate ?? Date(),
            lastMessagePriv: chatListItem.lastMessagePriv.toChatMessageTypeEntity(),
            lastMessageHandle: chatListItem.lastMessageHandle
        )
    }
}

public extension MEGAChatListItemChangeType {
    func toChatListItemChangeEntity() -> ChatListItemEntity.ChangeType {
        switch self {
        case .status:
            return .status
        case .ownPrivilege:
            return .ownPrivilege
        case .unreadCount:
            return .unreadCount
        case .participants:
            return .participants
        case .title:
            return .title
        case .closed:
            return .closed
        case .lastMsg:
            return .lastMessage
        case .lastTs:
            return .lastTimestamp
        case .archived:
            return .archived
        case .call:
            return .call
        case .chatMode:
            return .chatMode
        case .updatePreviewers:
            return .updatePreviewers
        case .previewClosed:
            return .previewClosed
        case .delete:
            return .delete
        @unknown default:
            return .noChanges
        }
    }
}
