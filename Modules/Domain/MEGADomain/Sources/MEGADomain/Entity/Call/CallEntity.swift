import Foundation

public struct CallEntity: Sendable {
    public enum CallStatusType: Sendable {
        case undefined
        case initial
        case userNoPresent
        case waitingRoom
        case connecting
        case joining
        case inProgress
        case terminatingUserParticipation
        case destroyed
    }
    
    public enum TermCodeType: Sendable {
        case invalid
        case userHangup
        case tooManyParticipants
        case reject
        case error
        case noParticipate
        case tooManyClients
        case protocolVersion
        case kicked
        case waitingRoomTimeout
        case callDurationLimit
        case callUsersLimit
    }
    
    public enum ChangeType: Sendable {
        case noChanges
        case status
        case localAVFlags
        case ringingStatus
        case callComposition
        case onHold
        case callSpeak
        case audioLevel
        case networkQuality
        case outgoingRingingStop
        case ownPermission
        case genericNotification
        case waitingRoomAllow
        case waitingRoomDeny
        case waitingRoomComposition
        case waitingRoomUsersEntered
        case waitingRoomUsersLeave
        case waitingRoomUsersAllow
        case waitingRoomUsersDeny
        case waitingRoomPushedFromCall
        case speakRequested
        case callWillEnd
        case callLimitsUpdated
        case callRaiseHand
    }
    
    public enum ConfigurationType: Sendable {
        case audio
        case video
        case anyFlag
    }
    
    public enum CompositionChangeType: Sendable {
        case peerRemoved
        case noChange
        case peerAdded
    }
    
    public enum NotificationType: Sendable {
        case invalid
        case serverError
        case sfuDeny
    }
    
    public let status: CallStatusType?
    public let chatId: HandleEntity
    public let callId: HandleEntity
    public let changeType: ChangeType?
    public let duration: Int64
    public let initialTimestamp: Int64
    public let finalTimestamp: Int64
    public let callWillEndTimestamp: Int64
    public let hasLocalAudio: Bool
    public let hasLocalVideo: Bool
    public let termCodeType: TermCodeType?
    public let callLimits: CallLimitsEntity
    public let isRinging: Bool
    public let callCompositionChange: CompositionChangeType?
    public let numberOfParticipants: Int
    public let isOnHold: Bool
    public let isOwnClientCaller: Bool
    public let sessionClientIds: [HandleEntity]
    public let clientSessions: [ChatSessionEntity]
    public let participants: [HandleEntity]
    public let waitingRoomStatus: WaitingRoomStatus
    public let waitingRoom: WaitingRoomEntity?
    public let waitingRoomHandleList: [HandleEntity]
    public let raiseHandsList: [HandleEntity]
    public let auxHandle: HandleEntity
    public let peeridCallCompositionChange: HandleEntity
    public let networkQuality: NetworkQuality

    public let uuid: UUID
    
    public init(
        status: CallStatusType?,
        chatId: HandleEntity,
        callId: HandleEntity,
        changeType: ChangeType?,
        duration: Int64,
        initialTimestamp: Int64,
        finalTimestamp: Int64,
        callWillEndTimestamp: Int64,
        hasLocalAudio: Bool,
        hasLocalVideo: Bool,
        termCodeType: TermCodeType?,
        callLimits: CallLimitsEntity,
        isRinging: Bool,
        callCompositionChange: CompositionChangeType?,
        numberOfParticipants: Int,
        isOnHold: Bool,
        isOwnClientCaller: Bool,
        sessionClientIds: [HandleEntity],
        clientSessions: [ChatSessionEntity],
        participants: [HandleEntity],
        waitingRoomStatus: WaitingRoomStatus,
        waitingRoom: WaitingRoomEntity?,
        waitingRoomHandleList: [HandleEntity],
        raiseHandsList: [HandleEntity],
        auxHandle: HandleEntity,
        networkQuality: NetworkQuality,
        peeridCallCompositionChange: HandleEntity,
        uuid: UUID
    ) {
        self.status = status
        self.chatId = chatId
        self.callId = callId
        self.changeType = changeType
        self.duration = duration
        self.initialTimestamp = initialTimestamp
        self.finalTimestamp = finalTimestamp
        self.callWillEndTimestamp = callWillEndTimestamp
        self.hasLocalAudio = hasLocalAudio
        self.hasLocalVideo = hasLocalVideo
        self.termCodeType = termCodeType
        self.callLimits = callLimits
        self.isRinging = isRinging
        self.callCompositionChange = callCompositionChange
        self.numberOfParticipants = numberOfParticipants
        self.isOnHold = isOnHold
        self.isOwnClientCaller = isOwnClientCaller
        self.sessionClientIds = sessionClientIds
        self.clientSessions = clientSessions
        self.participants = participants
        self.waitingRoomStatus = waitingRoomStatus
        self.waitingRoom = waitingRoom
        self.waitingRoomHandleList = waitingRoomHandleList
        self.raiseHandsList = raiseHandsList
        self.auxHandle = auxHandle
        self.networkQuality = networkQuality
        self.peeridCallCompositionChange = peeridCallCompositionChange
        self.uuid = uuid
    }
    
    public var isActiveCall: Bool {
        switch status {
        case .joining, .connecting, .inProgress:
            return true
        default:
            return false
        }
    }
}

public struct CallLimitsEntity: Sendable {
    public let durationLimit: Int
    public let maxUsers: Int
    public let maxClientsPerUser: Int
    public let maxClients: Int
    
    public init(durationLimit: Int, maxUsers: Int, maxClientsPerUser: Int, maxClients: Int) {
        self.durationLimit = durationLimit
        self.maxUsers = maxUsers
        self.maxClientsPerUser = maxClientsPerUser
        self.maxClients = maxClients
    }
}

extension CallEntity: Hashable {
    public static func == (lhs: CallEntity, rhs: CallEntity) -> Bool {
        lhs.callId == rhs.callId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(callId)
    }
}

extension CallEntity: Identifiable {
    public var id: HandleEntity { callId }
}

extension CallLimitsEntity {
    public static let noLimits = -1
}
