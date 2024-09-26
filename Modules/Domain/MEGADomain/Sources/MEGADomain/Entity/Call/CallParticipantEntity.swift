import Foundation

public enum VideoFrameType {
    case cameraVideo
    case screenShare
}

public enum AbsentParticipantState {
    case notInCall
    case calling
    case noResponse
}

public protocol CallParticipantVideoDelegate: AnyObject {
    func videoFrameData(width: Int, height: Int, buffer: Data!, type: VideoFrameType)
}

public final class CallParticipantEntity {
    public enum CallParticipantAudioVideoFlag {
        case off
        case on
        case unknown
    }
    
    public let chatId: HandleEntity
    public let participantId: HandleEntity
    public var clientId: HandleEntity
    public var name: String?
    public var isModerator: Bool
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
    public var hasCamera: Bool
    public var isLowResCamera: Bool
    public var isHiResCamera: Bool
    public var hasScreenShare: Bool
    public var isLowResScreenShare: Bool
    public var isHiResScreenShare: Bool
    public var audioDetected: Bool
    public var isScreenShareCell: Bool = false
    public var isReceivingHiResVideo: Bool = false
    public var isReceivingLowResVideo: Bool = false
    public var isRecording: Bool = false
    public var absentParticipantState: AbsentParticipantState = .notInCall
    public var raisedHand: Bool = false

    public init(
        chatId: HandleEntity,
        participantId: HandleEntity,
        clientId: HandleEntity,
        isModerator: Bool,
        video: CallParticipantAudioVideoFlag,
        audio: CallParticipantAudioVideoFlag,
        isVideoHiRes: Bool,
        isVideoLowRes: Bool,
        canReceiveVideoHiRes: Bool,
        canReceiveVideoLowRes: Bool,
        name: String?,
        sessionRecoverable: Bool,
        isSpeakerPinned: Bool,
        hasCamera: Bool,
        isLowResCamera: Bool,
        isHiResCamera: Bool,
        hasScreenShare: Bool,
        isLowResScreenShare: Bool,
        isHiResScreenShare: Bool,
        audioDetected: Bool,
        isRecording: Bool,
        absentParticipantState: AbsentParticipantState,
        raisedHand: Bool
    ) {
        self.chatId = chatId
        self.participantId = participantId
        self.clientId = clientId
        self.isModerator = isModerator
        self.video = video
        self.audio = audio
        self.isVideoHiRes = isVideoHiRes
        self.isVideoLowRes = isVideoLowRes
        self.canReceiveVideoHiRes = canReceiveVideoHiRes
        self.canReceiveVideoLowRes = canReceiveVideoLowRes
        self.name = name
        self.sessionRecoverable = sessionRecoverable
        self.isSpeakerPinned = isSpeakerPinned
        self.hasCamera = hasCamera
        self.isLowResCamera = isLowResCamera
        self.isHiResCamera = isHiResCamera
        self.hasScreenShare = hasScreenShare
        self.isLowResScreenShare = isLowResScreenShare
        self.isHiResScreenShare = isHiResScreenShare
        self.audioDetected = audioDetected
        self.isRecording = isRecording
        self.absentParticipantState = absentParticipantState
        self.raisedHand = raisedHand
    }
    
    public func remoteVideoFrame(width: Int, height: Int, buffer: Data!, isHiRes: Bool) {
        if hasScreenShare {
            if (isHiRes && isHiResCamera) || (!isHiRes && isLowResCamera) {
                videoDataDelegate?.videoFrameData(width: width, height: height, buffer: buffer, type: .cameraVideo)
            } else if (isHiRes && isHiResScreenShare) || (!isHiRes && isLowResScreenShare) {
                videoDataDelegate?.videoFrameData(width: width, height: height, buffer: buffer, type: .screenShare)
                speakerVideoDataDelegate?.videoFrameData(width: width, height: height, buffer: buffer, type: .screenShare)
            }
        } else {
            if (isHiRes && isHiResCamera) || (!isHiRes && isLowResCamera) {
                videoDataDelegate?.videoFrameData(width: width, height: height, buffer: buffer, type: .cameraVideo)
                speakerVideoDataDelegate?.videoFrameData(width: width, height: height, buffer: buffer, type: .cameraVideo)
            }
        }
    }
}

extension CallParticipantEntity: Equatable {
    public static func == (lhs: CallParticipantEntity, rhs: CallParticipantEntity) -> Bool {
        guard lhs.clientId != .invalid && rhs.clientId != .invalid else {
            // Participant is not in call so clientId does not exists, for 'Not in Call' tab
            return lhs.participantId == rhs.participantId
        }
        // Participant is in call, for 'In call' and 'Waiting room' tabs
        return lhs.participantId == rhs.participantId && lhs.clientId == rhs.clientId && lhs.isScreenShareCell == rhs.isScreenShareCell
    }
}

extension CallParticipantEntity: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(participantId)
        hasher.combine(clientId)
        hasher.combine(isScreenShareCell)
    }
}
