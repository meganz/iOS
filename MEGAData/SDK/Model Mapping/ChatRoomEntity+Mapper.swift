extension ChatRoomEntity {
    init(with chatRoom: MEGAChatRoom) {
        self.chatId = chatRoom.chatId
        self.ownPrivilege = Privilege(rawValue: chatRoom.ownPrivilege.rawValue) ?? .unknown
        self.changeType = ChangeType(rawValue: chatRoom.changes.rawValue)
        
        self.peerCount = chatRoom.peerCount
        self.authorizationToken = chatRoom.authorizationToken
        self.title = chatRoom.title
        self.unreadCount = chatRoom.unreadCount
        self.userTypingHandle = chatRoom.userTypingHandle
        self.retentionTime = chatRoom.retentionTime
        self.creationTimeStamp = chatRoom.creationTimeStamp
        
        self.hasCustomTitle = chatRoom.hasCustomTitle
        self.isPublicChat = chatRoom.isPublicChat
        self.isPreview = chatRoom.isPreview
        self.isactive = chatRoom.isActive
        self.isArchived = chatRoom.isArchived
        
        self.peerHandles = (0..<chatRoom.peerCount).compactMap(chatRoom.peerHandle)
        
        if chatRoom.isMeeting {
            self.chatType = .meeting
        } else if chatRoom.isGroup {
            self.chatType = .group
        } else {
            self.chatType = .oneToOne
        }
    }
}
