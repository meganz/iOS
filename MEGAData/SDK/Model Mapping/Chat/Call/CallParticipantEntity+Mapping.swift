import MEGAChatSdk
import MEGADomain
import MEGASdk

extension CallParticipantEntity {
    convenience init(
        session: ChatSessionEntity,
        chatId: HandleEntity,
        sdk: MEGASdk = .sharedSdk,
        chatSDK: MEGAChatSdk = .sharedChatSdk
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
                  email: contact?.email,
                  isModerator: isModerator,
                  isInContactList: isInContactList,
                  video: session.hasVideo ? .on : .off,
                  audio: session.hasAudio ? .on : .off,
                  isVideoHiRes: session.isHighResolution,
                  isVideoLowRes: session.isLowResolution,
                  canReceiveVideoHiRes: session.canReceiveVideoHiRes,
                  canReceiveVideoLowRes: session.canReceiveVideoLowRes,
                  name: nil,
                  sessionRecoverable: session.termCode == .recoverable,
                  isSpeakerPinned: false)
    }
    
    convenience init(
        chatId: ChatIdEntity,
        userHandle: HandleEntity,
        peerPrivilege: ChatRoomPrivilegeEntity,
        sdk: MEGASdk = .sharedSdk
    ) {
        var isInContactList = false
        
        let contact = sdk.visibleContacts().first(where: { $0.handle == userHandle })
        isInContactList = (contact != nil)
        
        self.init(chatId: chatId,
                  participantId: userHandle,
                  clientId: .invalid,
                  email: contact?.email,
                  isModerator: peerPrivilege == .moderator,
                  isInContactList: isInContactList,
                  video: .unknown,
                  audio: .unknown,
                  isVideoHiRes: false,
                  isVideoLowRes: false,
                  canReceiveVideoHiRes: false,
                  canReceiveVideoLowRes: false,
                  name: nil,
                  sessionRecoverable: false,
                  isSpeakerPinned: false)
    }
    
    convenience init(
        chatId: HandleEntity,
        userHandle: HandleEntity,
        sdk: MEGASdk = .sharedSdk
    ) {
        var isInContactList = false
        
        let contact = sdk.visibleContacts().first(where: { $0.handle == userHandle })
        isInContactList = (contact != nil)
        
        self.init(chatId: chatId,
                  participantId: userHandle,
                  clientId: .invalid,
                  email: contact?.email,
                  isModerator: false,
                  isInContactList: isInContactList,
                  video: .unknown,
                  audio: .unknown,
                  isVideoHiRes: false,
                  isVideoLowRes: false,
                  canReceiveVideoHiRes: false,
                  canReceiveVideoLowRes: false,
                  name: nil,
                  sessionRecoverable: false,
                  isSpeakerPinned: false)
    }
    
    static func myself(
        chatId: HandleEntity,
        sdk: MEGASdk = .sharedSdk,
        chatSDK: MEGAChatSdk = .sharedChatSdk
    ) -> CallParticipantEntity? {
        guard let user = sdk.myUser,
              let chatRoom = chatSDK.chatRoom(forChatId: chatId) else {
            return nil
        }
        let participant = CallParticipantEntity(
            chatId: chatId,
            participantId: user.handle,
            clientId: 0,
            email: sdk.myEmail,
            isModerator: chatRoom.toChatRoomEntity().ownPrivilege == .moderator,
            isInContactList: false,
            video: .unknown,
            audio: .unknown,
            isVideoHiRes: true,
            isVideoLowRes: false,
            canReceiveVideoHiRes: true,
            canReceiveVideoLowRes: false,
            name: chatSDK.myFullname,
            sessionRecoverable: false,
            isSpeakerPinned: false
        )
        
        return participant
    }
}
