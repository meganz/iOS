
enum CallParticipantVideoResolution {
    case low
    case high
}

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
    var networkQuality: Int
    var email: String?
    var isModerator: Bool
    var isInContactList: Bool
    var video: CallParticipantAudioVideoFlag = .unknown
    var audio: CallParticipantAudioVideoFlag = .unknown
    var videoResolution: CallParticipantVideoResolution
    weak var videoDataDelegate: CallParticipantVideoDelegate?
    weak var speakerVideoDataDelegate: CallParticipantVideoDelegate?
    var isSpeakerPinned: Bool = false

    init(chatId: MEGAHandle,
         participantId: MEGAHandle,
         clientId: MEGAHandle,
         networkQuality: Int,
         email: String?,
         isModerator: Bool,
         isInContactList: Bool,
         video: CallParticipantAudioVideoFlag = .unknown,
         audio: CallParticipantAudioVideoFlag = .unknown,
         videoResolution: CallParticipantVideoResolution) {
        self.chatId = chatId
        self.participantId = participantId
        self.clientId = clientId
        self.networkQuality = networkQuality
        self.email = email
        self.isModerator = isModerator
        self.isInContactList = isInContactList
        self.video = video
        self.audio = audio
        self.videoResolution = videoResolution
    }
    
    static func == (lhs: CallParticipantEntity, rhs: CallParticipantEntity) -> Bool {
        lhs.participantId == rhs.participantId && lhs.clientId == rhs.clientId
    }
    
    func remoteVideoFrame(width: Int, height: Int, buffer: Data!) {
        videoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
        speakerVideoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
    }
}
