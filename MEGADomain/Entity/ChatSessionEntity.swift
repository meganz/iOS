


struct ChatSessionEntity {
    enum StatusType: Int {
        case invalid = 0xFF
        case initial = 0
        case inProgress
        case destroyed
    }
    
    let statusType: StatusType?
    let hasAudio: Bool
    let hasVideo: Bool
    let peerId: UInt64
    let clientId: UInt64
    let audioDetected: Bool
    let isOnHold: Bool
    let changes: Int
    let isHighResolution: Bool
}

