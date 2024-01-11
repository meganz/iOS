public extension CallParticipantEntity {
    convenience init(
        session: ChatSessionEntity,
        chatRoom: ChatRoomEntity,
        privilege: ChatRoomPrivilegeEntity
    ) {
        self.init(
            chatId: chatRoom.chatId,
            participantId: session.peerId,
            clientId: session.clientId,
            isModerator: privilege == .moderator,
            video: session.hasVideo ? .on : .off,
            audio: session.hasAudio ? .on : .off,
            isVideoHiRes: session.isHighResolution,
            isVideoLowRes: session.isLowResolution,
            canReceiveVideoHiRes: session.canReceiveVideoHiRes,
            canReceiveVideoLowRes: session.canReceiveVideoLowRes,
            name: nil,
            sessionRecoverable: session.termCode == .recoverable,
            isSpeakerPinned: false,
            hasCamera: session.hasCamera,
            isLowResCamera: session.isLowResCamera,
            isHiResCamera: session.isHiResCamera,
            hasScreenShare: session.hasScreenShare,
            isLowResScreenShare: session.isLowResScreenShare,
            isHiResScreenShare: session.isHiResScreenShare,
            audioDetected: session.audioDetected,
            isRecording: session.onRecording, 
            absentParticipantState: .notInCall
        )
    }
    
    convenience init(
        userHandle: HandleEntity,
        chatRoom: ChatRoomEntity,
        privilege: ChatRoomPrivilegeEntity
    ) {
        self.init(
            chatId: chatRoom.chatId,
            participantId: userHandle,
            clientId: .invalid,
            isModerator: privilege == .moderator,
            video: .unknown,
            audio: .unknown,
            isVideoHiRes: false,
            isVideoLowRes: false,
            canReceiveVideoHiRes: false,
            canReceiveVideoLowRes: false,
            name: nil,
            sessionRecoverable: false,
            isSpeakerPinned: false,
            hasCamera: false,
            isLowResCamera: false,
            isHiResCamera: false,
            hasScreenShare: false,
            isLowResScreenShare: false,
            isHiResScreenShare: false,
            audioDetected: false,
            isRecording: false, 
            absentParticipantState: .notInCall
        )
    }
    
    static func myself(
        handle: HandleEntity,
        userName: String?,
        chatRoom: ChatRoomEntity
    ) -> CallParticipantEntity {
        CallParticipantEntity(
            chatId: chatRoom.chatId,
            participantId: handle,
            clientId: 0,
            isModerator: chatRoom.ownPrivilege == .moderator,
            video: .unknown,
            audio: .unknown,
            isVideoHiRes: true,
            isVideoLowRes: false,
            canReceiveVideoHiRes: true,
            canReceiveVideoLowRes: false,
            name: userName,
            sessionRecoverable: false,
            isSpeakerPinned: false,
            hasCamera: false,
            isLowResCamera: false,
            isHiResCamera: false,
            hasScreenShare: false,
            isLowResScreenShare: false,
            isHiResScreenShare: false,
            audioDetected: false,
            isRecording: false,
            absentParticipantState: .notInCall
        )
    }
    
    static func createScreenShareParticipant(
        _ participant: CallParticipantEntity
    ) -> CallParticipantEntity {
        let callParticipant = CallParticipantEntity(
            chatId: participant.chatId,
            participantId: participant.participantId,
            clientId: participant.clientId,
            isModerator: participant.isModerator,
            video: participant.video,
            audio: participant.audio,
            isVideoHiRes: participant.isVideoHiRes,
            isVideoLowRes: participant.isVideoLowRes,
            canReceiveVideoHiRes: participant.canReceiveVideoHiRes,
            canReceiveVideoLowRes: participant.canReceiveVideoLowRes,
            name: participant.name,
            sessionRecoverable: participant.sessionRecoverable,
            isSpeakerPinned: participant.isSpeakerPinned,
            hasCamera: participant.hasCamera,
            isLowResCamera: participant.isLowResCamera,
            isHiResCamera: participant.isHiResCamera,
            hasScreenShare: participant.hasScreenShare,
            isLowResScreenShare: participant.isLowResScreenShare,
            isHiResScreenShare: participant.isHiResScreenShare,
            audioDetected: false,
            isRecording: false,
            absentParticipantState: .notInCall
        )
        callParticipant.name = participant.name
        callParticipant.isScreenShareCell = true
        callParticipant.isReceivingHiResVideo = participant.isReceivingHiResVideo
        callParticipant.isReceivingLowResVideo = participant.isReceivingLowResVideo
        return callParticipant
    }
}
