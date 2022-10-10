
import MEGADomain

extension MEGAChatListItem {
    func toChatListItemEntity() -> ChatListItemEntity {
        ChatListItemEntity(with: self)
    }
}

fileprivate extension ChatListItemEntity {
    init(with chatListItem: MEGAChatListItem) {
        self.init(
            chatId: chatListItem.chatId,
            title: chatListItem.title,
            changeType: chatListItem.changes.toChatListItemChangeEntity(),
            ownPrivilege: chatListItem.ownPrivilege.toOwnPrivilegeEntity(),
            unreadCount: UInt(chatListItem.unreadCount),
            previewersCount: chatListItem.previewersCount,
            group: chatListItem.isGroup,
            publicChat: chatListItem.isPublicChat,
            preview: chatListItem.isPreview,
            active: chatListItem.isActive,
            deleted: chatListItem.isDeleted,
            peerHandle: chatListItem.peerHandle,
            lastMessage: chatListItem.lastMessage,
            lastMessageId: chatListItem.lastMessageId,
            lastMessageType: chatListItem.lastMessageType.toChatMessageType(),
            lastMessageSender: chatListItem.lastMessageSender,
            lastMessageDate: chatListItem.lastMessageDate,
            lastMessagePriv: chatListItem.lastMessagePriv.toChatMessageType(),
            lastMessageHandle: chatListItem.lastMessageHandle
        )
    }
}

extension MEGAChatListItemChangeType {
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

extension MEGAChatMessageType {
    func toChatMessageType() -> ChatListItemEntity.ChatMessageType {
        switch self {
        case .unknown:
            return .unknown
        case .invalid:
            return .invalid
        case .normal:
            return .normal
        case .alterParticipants:
            return .alterParticipants
        case .truncate:
            return .truncate
        case .privilegeChange:
            return .privilegeChange
        case .chatTitle:
            return .chatTitle
        case .callEnded:
            return .callEnded
        case .callStarted:
            return .callStarted
        case .publicHandleCreate:
            return .publicHandleCreate
        case .publicHandleDelete:
            return .publicHandleDelete
        case .setPrivateMode:
            return .setPrivateMode
        case .setRetentionTime:
            return .setRetentionTime
        case .attachment:
            return .attachment
        case .revokeAttachment:
            return .unknown
        case .contact:
            return .contact
        case .containsMeta:
            return .containsMeta
        case .voiceClip:
            return .voiceClip
        @unknown default:
            return .unknown
        }
    }
}
