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
    
    public let statusType: StatusType?
    public let termCode: ChatSessionTermCode?
    public let hasAudio: Bool
    public let hasVideo: Bool
    public let peerId: HandleEntity
    public let clientId: HandleEntity
    public let audioDetected: Bool
    public let isOnHold: Bool
    public let changes: Int
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
    
    public init(
        statusType: StatusType?,
        termCode: ChatSessionTermCode?,
        hasAudio: Bool, 
        hasVideo: Bool,
        peerId: HandleEntity,
        clientId: HandleEntity,
        audioDetected: Bool,
        isOnHold: Bool,
        changes: Int,
        isHighResolution: Bool,
        isLowResolution: Bool,
        canReceiveVideoHiRes: Bool,
        canReceiveVideoLowRes: Bool,
        hasCamera: Bool,
        isLowResCamera: Bool,
        isHiResCamera: Bool,
        hasScreenShare: Bool,
        isLowResScreenShare: Bool,
        isHiResScreenShare: Bool
    ) {
        self.statusType = statusType
        self.termCode = termCode
        self.hasAudio = hasAudio
        self.hasVideo = hasVideo
        self.peerId = peerId
        self.clientId = clientId
        self.audioDetected = audioDetected
        self.isOnHold = isOnHold
        self.changes = changes
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
    }
}
