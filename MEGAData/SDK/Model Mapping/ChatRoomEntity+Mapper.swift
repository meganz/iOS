import MEGADomain

extension MEGAChatRoom {
    func toChatRoomEntity() -> ChatRoomEntity {
        ChatRoomEntity(with: self)
    }
}

fileprivate extension ChatRoomEntity {
    init(with chatRoom: MEGAChatRoom) {
        self.init(
            chatId: chatRoom.chatId,
            ownPrivilege: chatRoom.ownPrivilege.toOwnPrivilegeEntity(),
            changeType: chatRoom.changes.toChatRoomChangeTypeEntity(),
            peerCount: chatRoom.peerCount,
            authorizationToken: chatRoom.authorizationToken,
            title: chatRoom.title,
            unreadCount: chatRoom.unreadCount,
            userTypingHandle: chatRoom.userTypingHandle,
            retentionTime: chatRoom.retentionTime,
            creationTimeStamp: chatRoom.creationTimeStamp,
            hasCustomTitle: chatRoom.hasCustomTitle,
            isPublicChat: chatRoom.isPublicChat,
            isPreview: chatRoom.isPreview,
            isactive: chatRoom.isActive,
            isArchived: chatRoom.isArchived,
            chatType:  chatRoom.isMeeting ? .meeting : chatRoom.isGroup ? .group : .oneToOne,
            peers: (0..<chatRoom.peerCount).map { Peer(chatRoom: chatRoom, index: $0) },
            userHandle: chatRoom.userHandle,
            isOpenInviteEnabled: chatRoom.isOpenInviteEnabled)
    }
}

extension MEGAChatRoomPrivilege {
    func toOwnPrivilegeEntity() -> ChatRoomPrivilegeEntity {
        switch self {
        case .unknown:
            return .unknown
        case .rm:
            return .removed
        case .ro:
            return .readOnly
        case .standard:
            return .standard
        case .moderator:
            return .moderator
        @unknown default:
            return .unknown
        }
    }
}

extension MEGAChatRoomChangeType {
    func toChatRoomChangeTypeEntity() -> ChatRoomEntity.ChangeType {
        switch self {
        case .status:
            return .status
        case .unreadCount:
            return .unreadCount
        case .participants:
            return .participants
        case .title:
            return .title
        case .userTyping:
            return .userTyping
        case .closed:
            return .closed
        case .ownPriv:
            return .ownPrivilege
        case .userStopTyping:
            return .userStopTyping
        case .archive:
            return .archive
        case .call:
            return .call
        case .chatMode:
            return .chatMode
        case .updatePreviewers:
            return .previewers
        case .retentionTime:
            return .retentionTime
        case .openInvite:
            return .openInvite
        case .speakRequest:
            return .speakRequest
        case .waitingRoom:
            return .waitingRoom
        @unknown default:
            return .noChange
        }
    }
}
