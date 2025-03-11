public struct ChatRoomEntity: Sendable {
    public enum ChatType: Sendable {
        case oneToOne
        case group
        case meeting
        case noteToSelf
    }
    
    public enum ChangeType: Sendable {
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
    
    public struct Peer: Sendable {
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
    public let authorizationToken: String?
    public let title: String?
    public let unreadCount: Int
    public let userTypingHandle: HandleEntity
    public let retentionTime: UInt
    public let creationTimeStamp: UInt64
    public let previewersCount: UInt

    public let hasCustomTitle: Bool
    public let isPublicChat: Bool
    public let isPreview: Bool
    public let isActive: Bool
    public let isArchived: Bool
    public let isMeeting: Bool
    public let isNoteToSelf: Bool
    public let chatType: ChatType
    public let peers: [Peer]
    public let userHandle: HandleEntity
    public let isOpenInviteEnabled: Bool
    public let isWaitingRoomEnabled: Bool
    
    public init(
        chatId: HandleEntity,
        ownPrivilege: ChatRoomPrivilegeEntity,
        changeType: ChangeType?,
        peerCount: UInt,
        authorizationToken: String?,
        title: String?,
        unreadCount: Int,
        userTypingHandle: HandleEntity,
        retentionTime: UInt,
        creationTimeStamp: UInt64,
        previewersCount: UInt,
        hasCustomTitle: Bool,
        isPublicChat: Bool,
        isPreview: Bool,
        isActive: Bool,
        isArchived: Bool,
        isMeeting: Bool,
        isNoteToSelf: Bool,
        chatType: ChatType,
        peers: [Peer],
        userHandle: HandleEntity,
        isOpenInviteEnabled: Bool,
        isWaitingRoomEnabled: Bool
    ) {
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
        self.previewersCount = previewersCount
        self.hasCustomTitle = hasCustomTitle
        self.isPublicChat = isPublicChat
        self.isPreview = isPreview
        self.isActive = isActive
        self.isArchived = isArchived
        self.isMeeting = isMeeting
        self.isNoteToSelf = isNoteToSelf
        self.chatType = chatType
        self.peers = peers
        self.userHandle = userHandle
        self.isOpenInviteEnabled = isOpenInviteEnabled
        self.isWaitingRoomEnabled = isWaitingRoomEnabled
    }
}

extension ChatRoomEntity {
    public var isGroup: Bool {
        chatType != .oneToOne
    }
    
    public var ownPrivilegeIsReadOnlyOrLower: Bool {
        switch ownPrivilege {
        case .unknown, .removed, .readOnly:
            true
        case .standard, .moderator:
            false
        }
    }
    
    public var canAddReactions: Bool {
        if isPublicChat,
        isPreview {
            false
        } else if ownPrivilegeIsReadOnlyOrLower {
            false
        } else {
            true
        }
    }
    
    ///  For one to one chat rooms returns the other participant user handle
    public func oneToOneRoomOtherParticipantUserHandle() -> HandleEntity? {
        chatType == .oneToOne ? peers.first?.handle : nil
    }
}

extension ChatRoomEntity: Equatable {
    public static func == (lhs: ChatRoomEntity, rhs: ChatRoomEntity) -> Bool {
        lhs.chatId == rhs.chatId
    }
}
