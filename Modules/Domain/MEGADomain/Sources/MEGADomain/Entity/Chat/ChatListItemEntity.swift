import Foundation

public struct ChatListItemEntity: Sendable {
    public let chatId: HandleEntity
    public let title: String?
    public let changeType: ChangeType?
    public let ownPrivilege: ChatRoomPrivilegeEntity
    public let unreadCount: Int
    public let previewersCount: UInt
    
    public let group: Bool
    public let publicChat: Bool
    public let preview: Bool
    public let active: Bool
    public let deleted: Bool
    public let meeting: Bool
    public let isNoteToSelf: Bool
    
    public let peerHandle: HandleEntity
    
    public let lastMessage: String?
    public let lastMessageId: HandleEntity
    public let lastMessageType: ChatMessageTypeEntity
    public let lastMessageSender: HandleEntity
    public let lastMessageDate: Date
    public let lastMessagePriv: ChatMessageTypeEntity
    public let lastMessageHandle: HandleEntity
    
    public enum ChangeType: Sendable {
        case noChanges
        case status
        case ownPrivilege
        case unreadCount
        case participants
        case title
        case closed
        case lastMessage
        case lastTimestamp
        case archived
        case call
        case chatMode
        case updatePreviewers
        case previewClosed
        case delete
    }
    
    public init(
        chatId: HandleEntity,
        title: String?,
        changeType: ChangeType?,
        ownPrivilege: ChatRoomPrivilegeEntity,
        unreadCount: Int,
        previewersCount: UInt,
        group: Bool,
        publicChat: Bool,
        preview: Bool,
        active: Bool,
        deleted: Bool,
        meeting: Bool,
        noteToSelf: Bool,
        peerHandle: HandleEntity,
        lastMessage: String?,
        lastMessageId: HandleEntity,
        lastMessageType: ChatMessageTypeEntity,
        lastMessageSender: HandleEntity,
        lastMessageDate: Date,
        lastMessagePriv: ChatMessageTypeEntity,
        lastMessageHandle: HandleEntity
    ) {
        self.chatId = chatId
        self.title = title
        self.changeType = changeType
        self.ownPrivilege = ownPrivilege
        self.unreadCount = unreadCount
        self.previewersCount = previewersCount
        self.group = group
        self.publicChat = publicChat
        self.preview = preview
        self.active = active
        self.deleted = deleted
        self.meeting = meeting
        self.isNoteToSelf = noteToSelf
        self.peerHandle = peerHandle
        self.lastMessage = lastMessage
        self.lastMessageId = lastMessageId
        self.lastMessageType = lastMessageType
        self.lastMessageSender = lastMessageSender
        self.lastMessageDate = lastMessageDate
        self.lastMessagePriv = lastMessagePriv
        self.lastMessageHandle = lastMessageHandle
    }
}

extension ChatListItemEntity: Equatable {
    public static func == (lhs: ChatListItemEntity, rhs: ChatListItemEntity) -> Bool {
        lhs.chatId == rhs.chatId
    }
}
