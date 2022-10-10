
public struct ChatRoomEntity {
    public enum ChatType {
        case oneToOne
        case group
        case meeting
    }
    
    public enum ChangeType {
        case noChange
        case status
        case unreadCount
        case participants
        case title
        case userTyping
        case closed
        case ownPrivilege
        case userStopTyping
        case archive
        case call
        case chatMode
        case previewers
        case retentionTime
        case openInvite
        case speakRequest
        case waitingRoom
    }
    
    public struct Peer {
        public let handle: HandleEntity
        public let privilege: ChatRoomPrivilegeEntity
        
        public init(handle: HandleEntity, privilege: ChatRoomPrivilegeEntity) {
            self.handle = handle
            self.privilege = privilege
        }
    }
    
    public let chatId: HandleEntity
    public let ownPrivilege: ChatRoomPrivilegeEntity
    public let changeType: ChangeType?

    public let peerCount: UInt
    public let authorizationToken: String
    public let title: String?
    public let unreadCount: Int
    public let userTypingHandle: HandleEntity
    public let retentionTime: UInt
    public let creationTimeStamp: UInt64
    
    public let hasCustomTitle: Bool
    public let isPublicChat: Bool
    public let isPreview: Bool
    public let isactive: Bool
    public let isArchived: Bool
    public let chatType: ChatType
    public let peers: [Peer]
    public let userHandle: HandleEntity
    public let isOpenInviteEnabled: Bool
    
    public init(chatId: HandleEntity, ownPrivilege: ChatRoomPrivilegeEntity, changeType: ChangeType?, peerCount: UInt, authorizationToken: String, title: String?, unreadCount: Int, userTypingHandle: HandleEntity, retentionTime: UInt, creationTimeStamp: UInt64, hasCustomTitle: Bool, isPublicChat: Bool, isPreview: Bool, isactive: Bool, isArchived: Bool, chatType: ChatType, peers: [Peer], userHandle: HandleEntity, isOpenInviteEnabled: Bool) {
        self.chatId = chatId
        self.ownPrivilege = ownPrivilege
        self.changeType = changeType
        self.peerCount = peerCount
        self.authorizationToken = authorizationToken
        self.title = title
        self.unreadCount = unreadCount
        self.userTypingHandle = userTypingHandle
        self.retentionTime = retentionTime
        self.creationTimeStamp = creationTimeStamp
        self.hasCustomTitle = hasCustomTitle
        self.isPublicChat = isPublicChat
        self.isPreview = isPreview
        self.isactive = isactive
        self.isArchived = isArchived
        self.chatType = chatType
        self.peers = peers
        self.userHandle = userHandle
        self.isOpenInviteEnabled = isOpenInviteEnabled
    }
}

