public struct ChatSessionEntity: Sendable {
    public enum StatusType: Sendable {
        case invalid
        case inProgress
        case destroyed
    }
    
    public enum ChatSessionTermCode: Sendable {
        case invalid
        case recoverable
        case nonRecoverable
    }
    
    public enum ChangeType: Sendable {
        case noChanges
        case status
        case remoteAvFlags
        case speakRequested
        case onLowRes
        case onHiRes
        case onHold
        case audioLevel
        case permission
        case speakPermission
        case onRecording
    }
    
    public let statusType: StatusType?
    public let termCode: ChatSessionTermCode?
    public let hasAudio: Bool
    public let hasVideo: Bool
    public let peerId: HandleEntity
    public let clientId: HandleEntity
    public let audioDetected: Bool
    public let isOnHold: Bool
    public let changeType: ChangeType
    public let isHighResolution: Bool
    public let isLowResolution: Bool
    public let canReceiveVideoHiRes: Bool
    public let canReceiveVideoLowRes: Bool
    public let hasCamera: Bool
    public let isLowResCamera: Bool
    public let isHiResCamera: Bool
    public let hasScreenShare: Bool
    public let isLowResScreenShare: Bool
    public let isHiResScreenShare: Bool
    public let isModerator: Bool
    public let onRecording: Bool
    
    public init(
        statusType: StatusType?,
        termCode: ChatSessionTermCode?,
        hasAudio: Bool, 
        hasVideo: Bool,
        peerId: HandleEntity,
        clientId: HandleEntity,
        audioDetected: Bool,
        isOnHold: Bool,
        changeType: ChangeType,
        isHighResolution: Bool,
        isLowResolution: Bool,
        canReceiveVideoHiRes: Bool,
        canReceiveVideoLowRes: Bool,
        hasCamera: Bool,
        isLowResCamera: Bool,
        isHiResCamera: Bool,
        hasScreenShare: Bool,
        isLowResScreenShare: Bool,
        isHiResScreenShare: Bool,
        isModerator: Bool,
        onRecording: Bool
    ) {
        self.statusType = statusType
        self.termCode = termCode
        self.hasAudio = hasAudio
        self.hasVideo = hasVideo
        self.peerId = peerId
        self.clientId = clientId
        self.audioDetected = audioDetected
        self.isOnHold = isOnHold
        self.changeType = changeType
        self.isHighResolution = isHighResolution
        self.isLowResolution = isLowResolution
        self.canReceiveVideoHiRes = canReceiveVideoHiRes
        self.canReceiveVideoLowRes = canReceiveVideoLowRes
        self.hasCamera = hasCamera
        self.isLowResCamera = isLowResCamera
        self.isHiResCamera = isHiResCamera
        self.hasScreenShare = hasScreenShare
        self.isLowResScreenShare = isLowResScreenShare
        self.isHiResScreenShare = isHiResScreenShare
        self.isModerator = isModerator
        self.onRecording = onRecording
    }
}
