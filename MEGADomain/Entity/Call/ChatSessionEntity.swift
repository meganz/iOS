
struct ChatSessionEntity {
    enum StatusType: Int {
        case invalid = 0xFF
        case initial = 0
        case inProgress
        case destroyed
    }
    
    enum ChatSessionTermCode: Int {
        case invalid = -1
        case recoverable
        case nonRecoverable
    }
    
    let statusType: StatusType?
    let termCode: ChatSessionTermCode?
    let hasAudio: Bool
    let hasVideo: Bool
    let peerId: UInt64
    let clientId: UInt64
    let audioDetected: Bool
    let isOnHold: Bool
    let changes: Int
    let isHighResolution: Bool
    let isLowResolution: Bool
    let canReceiveVideoHiRes: Bool
    let canReceiveVideoLowRes: Bool
}

