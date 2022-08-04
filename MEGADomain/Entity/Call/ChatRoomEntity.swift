struct ChatRoomEntity {
    enum ChatType {
        case oneToOne
        case group
        case meeting
    }
    
    enum ChangeType: Int {
        case status           = 0x01
        case unreadCount      = 0x02
        case participants     = 0x04
        case title            = 0x08
        case userTyping       = 0x10
        case closed           = 0x20
        case ownPrivilege     = 0x40
        case userStopTyping   = 0x80
        case archive          = 0x100
        case call             = 0x200
        case chatMode         = 0x400
        case previewers       = 0x800
        case retentionTime    = 0x1000
    }
    
    enum Privilege: Int {
        case unknown   = -2
        case removed   = -1
        case readOnly  = 0
        case standard  = 2
        case moderator = 3
    }
    
    let chatId: HandleEntity
    let ownPrivilege: Privilege
    let changeType: ChangeType?

    let peerCount: UInt
    let authorizationToken: String
    let title: String?
    let unreadCount: Int
    let userTypingHandle: HandleEntity
    let retentionTime: UInt
    let creationTimeStamp: UInt64
    
    let hasCustomTitle: Bool
    let isPublicChat: Bool
    let isPreview: Bool
    let isactive: Bool
    let isArchived: Bool
    let chatType: ChatType
    let peerHandles: [HandleEntity]
    let userHandle: HandleEntity
}
