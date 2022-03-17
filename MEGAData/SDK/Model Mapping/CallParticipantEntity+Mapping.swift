
extension CallParticipantEntity {
    convenience init(
        session: ChatSessionEntity,
        chatId: MEGAHandle,
        sdk: MEGASdk = MEGASdkManager.sharedMEGASdk(),
        chatSDK: MEGAChatSdk = MEGASdkManager.sharedMEGAChatSdk()
    ) {
        var isModerator = false
        var isInContactList = false
        
        if let chatRoom = chatSDK.chatRoom(forChatId: chatId) {
            isModerator = chatRoom.peerPrivilege(byHandle: session.peerId) == MEGAChatRoomPrivilege.moderator.rawValue
        }
        
        let contact = sdk.visibleContacts().first(where: { $0.handle == session.peerId })
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
    
    static func myself(
        chatId: MEGAHandle,
        sdk: MEGASdk = MEGASdkManager.sharedMEGASdk(),
        chatSDK: MEGAChatSdk = MEGASdkManager.sharedMEGAChatSdk()
    ) -> CallParticipantEntity? {
        guard let user = sdk.myUser,
              let email = sdk.myEmail,
              let chatRoom = chatSDK.chatRoom(forChatId: chatId) else {
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
                                                canReceiveVideoLowRes: false,
                                                name: chatSDK.myFullname)
        
        return participant
    }
}
