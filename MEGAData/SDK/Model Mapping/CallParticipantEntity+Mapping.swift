
extension CallParticipantEntity {
    convenience init(session: ChatSessionEntity, chatId: MEGAHandle) {
        var isModerator = false
        var isInContactList = false
        
        if let chatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(forChatId: chatId) {
            isModerator = chatRoom.peerPrivilege(byHandle: session.peerId) == MEGAChatRoomPrivilege.moderator.rawValue
        }
        
        let contact = MEGASdkManager.sharedMEGASdk().visibleContacts().first(where: { $0.handle == session.peerId })
        isInContactList = (contact != nil)
        
        self.init(chatId: chatId,
                  participantId: session.peerId,
                  clientId: session.clientId,
                  networkQuality: 0,
                  email: contact?.email,
                  isModerator: isModerator,
                  isInContactList: isInContactList,
                  video: session.hasVideo ? .on : .off,
                  audio: session.hasAudio ? .on : .off,
                  isVideoHiRes: session.isHighResolution,
                  isVideoLowRes: session.isLowResolution,
                  canReceiveVideoHiRes: session.canReceiveVideoHiRes,
                  canReceiveVideoLowRes: session.canReceiveVideoLowRes)
    }
    
    static func myself(chatId: MEGAHandle) -> CallParticipantEntity? {
        guard let user = MEGASdkManager.sharedMEGASdk().myUser,
              let email = MEGASdkManager.sharedMEGASdk().myEmail,
              let chatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(forChatId: chatId) else {
            return nil
        }
        
        let participant = CallParticipantEntity(chatId: chatId,
                                                participantId: user.handle,
                                                clientId: 0,
                                                networkQuality: 0,
                                                email: email,
                                                isModerator: ChatRoomEntity(with: chatRoom).ownPrivilege == .moderator,
                                                isInContactList: false,
                                                isVideoHiRes: true,
                                                isVideoLowRes: false,
                                                canReceiveVideoHiRes: true,
                                                canReceiveVideoLowRes: false)
        
        return participant
    }
}
