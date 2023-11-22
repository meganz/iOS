import Foundation
import MEGADomain

public extension CallParticipantEntity {
    convenience init(
        chatId: HandleEntity = 0,
        participantId: HandleEntity = 0,
        clientId: HandleEntity = 0,
        email: String? = "test@email.com",
        isModerator: Bool = false,
        isInContactList: Bool = false,
        video: CallParticipantAudioVideoFlag = .unknown,
        audio: CallParticipantAudioVideoFlag = .unknown,
        isVideoHiRes: Bool = false,
        isVideoLowRes: Bool = false,
        canReceiveVideoHiRes: Bool = false,
        canReceiveVideoLowRes: Bool = false,
        name: String? = nil,
        sessionRecoverable: Bool = false,
        isSpeakerPinned: Bool = false,
        hasCamera: Bool = false,
        isLowResCamera: Bool = false,
        isHiResCamera: Bool = false,
        hasScreenShare: Bool = false,
        isLowResScreenShare: Bool = false,
        isHiResScreenShare: Bool = false,
        audioDetected: Bool = false,
        isRecording: Bool = false,
        isTesting: Bool = true
    ) {
        self.init(
            chatId: chatId,
            participantId: participantId,
            clientId: clientId,
            email: email,
            isModerator: isModerator,
            isInContactList: isInContactList,
            video: video,
            audio: audio,
            isVideoHiRes: isVideoHiRes,
            isVideoLowRes: isVideoLowRes,
            canReceiveVideoHiRes: canReceiveVideoHiRes,
            canReceiveVideoLowRes: canReceiveVideoLowRes,
            name: name,
            sessionRecoverable: sessionRecoverable,
            isSpeakerPinned: isSpeakerPinned,
            hasCamera: hasCamera,
            isLowResCamera: isLowResCamera,
            isHiResCamera: isHiResCamera,
            hasScreenShare: hasScreenShare,
            isLowResScreenShare: isLowResScreenShare,
            isHiResScreenShare: isHiResScreenShare,
            audioDetected: audioDetected,
            isRecording: isRecording
        )
    }
}
