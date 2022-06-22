
protocol CallParticipantVideoDelegate: AnyObject {
    func frameData(width: Int, height: Int, buffer: Data!)
}

final class CallParticipantEntity: Equatable {
    enum CallParticipantAudioVideoFlag {
        case off
        case on
        case unknown
    }
    
    let chatId: MEGAHandle
    let participantId: MEGAHandle
    let clientId: MEGAHandle
    var name: String?
    var email: String?
    var isModerator: Bool
    var isInContactList: Bool
    var video: CallParticipantAudioVideoFlag = .unknown
    var audio: CallParticipantAudioVideoFlag = .unknown
    var isVideoHiRes: Bool
    var isVideoLowRes: Bool
    var canReceiveVideoHiRes: Bool
    var canReceiveVideoLowRes: Bool
    weak var videoDataDelegate: CallParticipantVideoDelegate?
    weak var speakerVideoDataDelegate: CallParticipantVideoDelegate?
    var isSpeakerPinned: Bool = false
    var sessionRecoverable: Bool
    
    init(chatId: MEGAHandle,
         participantId: MEGAHandle,
         clientId: MEGAHandle,
         networkQuality: Int,
         email: String?,
         isModerator: Bool,
         isInContactList: Bool,
         video: CallParticipantAudioVideoFlag = .unknown,
         audio: CallParticipantAudioVideoFlag = .unknown,
         isVideoHiRes: Bool,
         isVideoLowRes: Bool,
         canReceiveVideoHiRes: Bool,
         canReceiveVideoLowRes: Bool,
         name: String? = nil,
         sessionRecoverable: Bool = false) {
        self.chatId = chatId
        self.participantId = participantId
        self.clientId = clientId
        self.email = email
        self.isModerator = isModerator
        self.isInContactList = isInContactList
        self.video = video
        self.audio = audio
        self.isVideoHiRes = isVideoHiRes
        self.isVideoLowRes = isVideoLowRes
        self.canReceiveVideoHiRes = canReceiveVideoHiRes
        self.canReceiveVideoLowRes = canReceiveVideoLowRes
        self.name = name
        self.sessionRecoverable = sessionRecoverable
    }
    
    static func == (lhs: CallParticipantEntity, rhs: CallParticipantEntity) -> Bool {
        lhs.participantId == rhs.participantId && lhs.clientId == rhs.clientId
    }
    
    func remoteVideoFrame(width: Int, height: Int, buffer: Data!) {
        videoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
        speakerVideoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
    }
}
