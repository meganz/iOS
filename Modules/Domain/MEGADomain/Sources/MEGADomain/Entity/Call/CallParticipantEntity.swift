import Foundation
import MEGASwift

public enum VideoFrameType {
    case cameraVideo
    case screenShare
}

public enum AbsentParticipantState: Sendable {
    case notInCall
    case calling
    case noResponse
}

public protocol CallParticipantVideoDelegate: AnyObject {
    func videoFrameData(width: Int, height: Int, buffer: Data!, type: VideoFrameType)
}

public final class CallParticipantEntity: @unchecked Sendable {
    public enum CallParticipantAudioVideoFlag: Sendable {
        case off
        case on
        case unknown
    }
    private let _clientId: Atomic<HandleEntity>
    private let _name: Atomic<String?>
    private let _isModerator: Atomic<Bool>
    private let _video: Atomic<CallParticipantAudioVideoFlag>
    private let _audio: Atomic<CallParticipantAudioVideoFlag>
    private let _isVideoHiRes: Atomic<Bool>
    private let _isVideoLowRes: Atomic<Bool>
    private let _canReceiveVideoHiRes: Atomic<Bool>
    private let _canReceiveVideoLowRes: Atomic<Bool>
    private let _videoDataDelegate = WeakAtomic(wrappedValue: nil)
    private let _speakerVideoDataDelegate = WeakAtomic(wrappedValue: nil)
    private let _isSpeakerPinned: Atomic<Bool>
    private let _sessionRecoverable: Atomic<Bool>
    private let _hasCamera: Atomic<Bool>
    private let _isLowResCamera: Atomic<Bool>
    private let _isHiResCamera: Atomic<Bool>
    private let _hasScreenShare: Atomic<Bool>
    private let _isLowResScreenShare: Atomic<Bool>
    private let _isHiResScreenShare: Atomic<Bool>
    private let _audioDetected: Atomic<Bool>
    private let _isScreenShareCell: Atomic<Bool>
    private let _isReceivingHiResVideo: Atomic<Bool>
    private let _isReceivingLowResVideo: Atomic<Bool>
    private let _isRecording: Atomic<Bool>
    private let _absentParticipantState: Atomic<AbsentParticipantState>
    private let _raisedHand: Atomic<Bool>
    
    public let chatId: HandleEntity
    public let participantId: HandleEntity
    
    public var clientId: HandleEntity {
        get {
            _clientId.wrappedValue
        }
        
        set {
            _clientId.mutate { $0 = newValue }
        }
    }
    
    public var name: String? {
        get {
            _name.wrappedValue
        }
        
        set {
            _name.mutate { $0 = newValue }
        }
    }
    
    public var isModerator: Bool {
        get {
            _isModerator.wrappedValue
        }
        
        set {
            _isModerator.mutate { $0 = newValue }
        }
    }
    
    public var video: CallParticipantAudioVideoFlag {
        get {
            _video.wrappedValue
        }
        
        set {
            _video.mutate { $0 = newValue }
        }
    }
    
    public var audio: CallParticipantAudioVideoFlag {
        get {
            _audio.wrappedValue
        }
        
        set {
            _audio.mutate { $0 = newValue }
        }
    }
    
    public var isVideoHiRes: Bool {
        get {
            _isVideoHiRes.wrappedValue
        }
        
        set {
            _isVideoHiRes.mutate { $0 = newValue }
        }
    }
    
    public var isVideoLowRes: Bool {
        get {
            _isVideoLowRes.wrappedValue
        }
        
        set {
            _isVideoLowRes.mutate { $0 = newValue }
        }
    }
    
    public var canReceiveVideoHiRes: Bool {
        get {
            _canReceiveVideoHiRes.wrappedValue
        }
        
        set {
            _canReceiveVideoHiRes.mutate { $0 = newValue }
        }
    }
    
    public var canReceiveVideoLowRes: Bool {
        get {
            _canReceiveVideoLowRes.wrappedValue
        }
        
        set {
            _canReceiveVideoLowRes.mutate { $0 = newValue }
        }
    }
    
    public var videoDataDelegate: (any CallParticipantVideoDelegate)? {
        get {
            _videoDataDelegate.wrappedValue as? CallParticipantVideoDelegate
        }
        
        set {
            _videoDataDelegate.mutate { $0 = newValue }
        }
    }

    public weak var speakerVideoDataDelegate: (any CallParticipantVideoDelegate)? {
        get {
            _speakerVideoDataDelegate.wrappedValue as? CallParticipantVideoDelegate
        }
        
        set {
            _speakerVideoDataDelegate.mutate { $0 = newValue }
        }
    }
    
    public var isSpeakerPinned: Bool {
        get {
            _isSpeakerPinned.wrappedValue
        }
        
        set {
            _isSpeakerPinned.mutate { $0 = newValue }
        }
    }
    
    public var sessionRecoverable: Bool {
        get {
            _sessionRecoverable.wrappedValue
        }
        
        set {
            _sessionRecoverable.mutate { $0 = newValue }
        }
    }
    
    public var hasCamera: Bool {
        get {
            _hasCamera.wrappedValue
        }
        
        set {
            _hasCamera.mutate { $0 = newValue }
        }
    }
    
    public var isLowResCamera: Bool {
        get {
            _isLowResCamera.wrappedValue
        }
        
        set {
            _isLowResCamera.mutate { $0 = newValue }
        }
    }
    
    public var isHiResCamera: Bool {
        get {
            _isHiResCamera.wrappedValue
        }
        
        set {
            _isHiResCamera.mutate { $0 = newValue }
        }
    }
    
    public var hasScreenShare: Bool {
        get {
            _hasScreenShare.wrappedValue
        }
        
        set {
            _hasScreenShare.mutate { $0 = newValue }
        }
    }
    
    public var isLowResScreenShare: Bool {
        get {
            _isLowResScreenShare.wrappedValue
        }
        
        set {
            _isLowResScreenShare.mutate { $0 = newValue }
        }
    }
    
    public var isHiResScreenShare: Bool {
        get {
            _isHiResScreenShare.wrappedValue
        }
        
        set {
            _isHiResScreenShare.mutate { $0 = newValue }
        }
    }
    
    public var audioDetected: Bool {
        get {
            _audioDetected.wrappedValue
        }
        
        set {
            _audioDetected.mutate { $0 = newValue }
        }
    }
    
    public var isScreenShareCell: Bool {
        get {
            _isScreenShareCell.wrappedValue
        }
        
        set {
            _isScreenShareCell.mutate { $0 = newValue }
        }
    }
    
    public var isReceivingHiResVideo: Bool {
        get {
            _isReceivingHiResVideo.wrappedValue
        }
        
        set {
            _isReceivingHiResVideo.mutate { $0 = newValue }
        }
    }
    
    public var isReceivingLowResVideo: Bool {
        get {
            _isReceivingLowResVideo.wrappedValue
        }
        
        set {
            _isReceivingLowResVideo.mutate { $0 = newValue }
        }
    }
    
    public var isRecording: Bool {
        get {
            _isRecording.wrappedValue
        }
        
        set {
            _isRecording.mutate { $0 = newValue }
        }
    }
    
    public var absentParticipantState: AbsentParticipantState {
        get {
            _absentParticipantState.wrappedValue
        }
        
        set {
            _absentParticipantState.mutate { $0 = newValue }
        }
    }
    
    public var raisedHand: Bool {
        get {
            _raisedHand.wrappedValue
        }
        
        set {
            _raisedHand.mutate { $0 = newValue }
        }
    }
    
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
        isRecording: Bool = false,
        absentParticipantState: AbsentParticipantState = .notInCall,
        raisedHand: Bool = false,
        isScreenShareCell: Bool = false,
        isReceivingHiResVideo: Bool = false,
        isReceivingLowResVideo: Bool = false
    ) {
        self.chatId = chatId
        self.participantId = participantId
        self._clientId = Atomic(wrappedValue: clientId)
        self._isModerator = Atomic(wrappedValue: isModerator)
        self._video = Atomic(wrappedValue: video)
        self._audio = Atomic(wrappedValue: audio)
        self._isVideoHiRes = Atomic(wrappedValue: isVideoHiRes)
        self._isVideoLowRes = Atomic(wrappedValue: isVideoLowRes)
        self._canReceiveVideoHiRes = Atomic(wrappedValue: canReceiveVideoHiRes)
        self._canReceiveVideoLowRes = Atomic(wrappedValue: canReceiveVideoLowRes)
        self._name = Atomic(wrappedValue: name)
        self._sessionRecoverable = Atomic(wrappedValue: sessionRecoverable)
        self._isSpeakerPinned = Atomic(wrappedValue: isSpeakerPinned)
        self._hasCamera = Atomic(wrappedValue: hasCamera)
        self._isLowResCamera = Atomic(wrappedValue: isLowResCamera)
        self._isHiResCamera = Atomic(wrappedValue: isHiResCamera)
        self._hasScreenShare = Atomic(wrappedValue: hasScreenShare)
        self._isLowResScreenShare = Atomic(wrappedValue: isLowResScreenShare)
        self._isHiResScreenShare = Atomic(wrappedValue: isHiResScreenShare)
        self._audioDetected = Atomic(wrappedValue: audioDetected)
        self._isRecording = Atomic(wrappedValue: isRecording)
        self._absentParticipantState = Atomic(wrappedValue: absentParticipantState)
        self._raisedHand = Atomic(wrappedValue: raisedHand)
        self._isScreenShareCell = Atomic(wrappedValue: isScreenShareCell)
        self._isReceivingHiResVideo = Atomic(wrappedValue: isReceivingHiResVideo)
        self._isReceivingLowResVideo = Atomic(wrappedValue: isReceivingLowResVideo)
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
    /// Two call participants must have same participantId, clientId and isScreenShareCell to be equal
    /// participantId (aka user handle) and clientId (same participant could join from different devices at same time) are SDK values
    /// isScreenShareCell is a property for a copy of a participant that renders sharing screen stream
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
