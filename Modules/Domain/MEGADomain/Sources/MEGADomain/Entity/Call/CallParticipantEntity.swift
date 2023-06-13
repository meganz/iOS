import Foundation

public protocol CallParticipantVideoDelegate: AnyObject {
    func frameData(width: Int, height: Int, buffer: Data!)
}

public final class CallParticipantEntity {
    public enum CallParticipantAudioVideoFlag {
        case off
        case on
        case unknown
    }
    
    public let chatId: HandleEntity
    public let participantId: HandleEntity
    public let clientId: HandleEntity
    public var name: String?
    public var email: String?
    public var isModerator: Bool
    public var isInContactList: Bool
    public var video: CallParticipantAudioVideoFlag
    public var audio: CallParticipantAudioVideoFlag
    public var isVideoHiRes: Bool
    public var isVideoLowRes: Bool
    public var canReceiveVideoHiRes: Bool
    public var canReceiveVideoLowRes: Bool
    public weak var videoDataDelegate: (any CallParticipantVideoDelegate)?
    public weak var speakerVideoDataDelegate: (any CallParticipantVideoDelegate)?
    public var isSpeakerPinned: Bool
    public var sessionRecoverable: Bool
    
    public init(
        chatId: HandleEntity,
        participantId: HandleEntity,
        clientId: HandleEntity,
        email: String?,
        isModerator: Bool,
        isInContactList: Bool,
        video: CallParticipantAudioVideoFlag,
        audio: CallParticipantAudioVideoFlag,
        isVideoHiRes: Bool,
        isVideoLowRes: Bool,
        canReceiveVideoHiRes: Bool,
        canReceiveVideoLowRes: Bool,
        name: String?,
        sessionRecoverable: Bool,
        isSpeakerPinned: Bool
    ) {
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
        self.isSpeakerPinned = isSpeakerPinned
    }
    
    public func remoteVideoFrame(width: Int, height: Int, buffer: Data!) {
        videoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
        speakerVideoDataDelegate?.frameData(width: width, height: height, buffer: buffer)
    }
}

extension CallParticipantEntity: Equatable {
    public static func == (lhs: CallParticipantEntity, rhs: CallParticipantEntity) -> Bool {
        lhs.participantId == rhs.participantId && lhs.clientId == rhs.clientId
    }
}
