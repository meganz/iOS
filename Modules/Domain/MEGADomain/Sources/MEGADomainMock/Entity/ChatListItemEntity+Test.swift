import Foundation
import MEGADomain

extension ChatListItemEntity {
    
    public init(
        chatId: HandleEntity = 1,
        title: String? = "",
        changeType: ChangeType? = .noChanges,
        ownPrivilege: ChatRoomPrivilegeEntity = .unknown,
        unreadCount: Int = 1,
        previewersCount: UInt = 1,
        group: Bool = true,
        publicChat: Bool = true,
        preview: Bool = false,
        active: Bool = true,
        deleted: Bool = false,
        meeting: Bool = false,
        isNoteToSelf: Bool = false,
        peerHandle: HandleEntity = 2,
        lastMessage: String? = nil,
        lastMessageId: HandleEntity = 3,
        lastMessageType: ChatMessageTypeEntity = .unknown,
        lastMessageSender: HandleEntity = 4,
        lastMessageDate: Date = Date(),
        lastMessagePriv: ChatMessageTypeEntity = .unknown,
        lastMessageHandle: HandleEntity = 5,
        isTesting: Bool = true
    ) {
        self.init(
            chatId: chatId,
            title: title,
            changeType: changeType,
            ownPrivilege: ownPrivilege,
            unreadCount: unreadCount,
            previewersCount: previewersCount,
            group: group,
            publicChat: publicChat,
            preview: preview,
            active: active,
            deleted: deleted,
            meeting: meeting,
            noteToSelf: isNoteToSelf,
            peerHandle: peerHandle,
            lastMessage: lastMessage,
            lastMessageId: lastMessageId,
            lastMessageType: lastMessageType,
            lastMessageSender: lastMessageSender,
            lastMessageDate: lastMessageDate,
            lastMessagePriv: lastMessagePriv,
            lastMessageHandle: lastMessageHandle
        )
    }
    
}
