import MEGADomain

struct CallEntity {
    enum CallStatusType: Int {
        case undefined = -1
        case initial = 0
        case userNoPresent
        case connecting
        case joining
        case inProgress
        case terminatingUserParticipation
        case destroyed
    }
    
    enum SessionStatusType: Int {
        case initial
        case inProgress
        case destroyed
        case noSession
    }
    
    enum TermCodeType: Int {
        case invalid = -1
        case userHangup = 0
        case tooManyParticipants
        case reject
        case error
    }
    
    enum ChangeType: Int {
        case noChanges = 0x00
        case status = 0x01
        case localAVFlags = 0x02
        case ringingStatus = 0x04
        case callComposition = 0x08
        case onHold = 0x10
        case callSpeak = 0x20
        case audioLevel = 0x40
        case networkQuality = 0x80
        case outgoingRingingStop = 0x100
    }
    
    enum ConfigurationType: Int {
        case audio
        case video
        case anyFlag
    }
    
    enum CompositionChangeType: Int {
        case peerRemoved = -1
        case noChange
        case peerAdded
    }
    
    let status: CallStatusType?
    let chatId: HandleEntity
    let callId: HandleEntity
    let changeTye: ChangeType?
    let duration: Int64
    let initialTimestamp: Int64
    let finalTimestamp: Int64
    let hasLocalAudio: Bool
    let hasLocalVideo: Bool
    let termCodeType: TermCodeType?
    let isRinging: Bool
    let callCompositionChange: CompositionChangeType?
    let numberOfParticipants: Int
    let isOnHold: Bool
    let sessionClientIds: [HandleEntity]
    let clientSessions: [ChatSessionEntity]
    let participants: [HandleEntity]
    let uuid: UUID
}
