

struct CallEntity {
    enum CallStatusType {
        case undefined
        case initial
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
        case UserHangup = 0
        case reqCancel
        case reject
        case answerElseWhere
        case rejectElseWhere
        case answerTimeout
        case ringOutTimeout
        case appTerminating
        case busy = 9
        case notFinished
        case destroyByCallCollision = 19
        case error = 21
    }
    
    enum ChangeType: Int {
        case noChanges = 0x00
        case status = 0x01
        case localAVFlags = 0x02
        case ringingStatus = 0x04
        case callComposition = 0x08
        case onHold = 0x10
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
    let chatId: UInt64
    let callId: UInt64
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
    let sessionClientIds: [UInt64]
    let clientSessions: [ChatSessionEntity]
    let participants: [UInt64]
    let uuid: UUID
}
