import MEGADomain

extension MEGAChatCall {
    func toCallEntity() -> CallEntity {
        CallEntity(with: self)
    }
}

fileprivate extension CallEntity {
    init(with call: MEGAChatCall) {
        let sessionClientIds = (0..<call.sessionsClientId.size).map { call.sessionsClientId.megaHandle(at: $0) }
        self.init(status: call.status.toCallStatusType(),
                  chatId: call.chatId,
                  callId: call.callId,
                  changeType: call.changes.toChangeTypeEntity(),
                  duration: call.duration,
                  initialTimestamp: call.initialTimeStamp,
                  finalTimestamp: call.finalTimeStamp,
                  hasLocalAudio: call.hasLocalAudio,
                  hasLocalVideo: call.hasLocalVideo,
                  termCodeType: call.termCode.toTermCodeTypeEntity(),
                  isRinging: call.isRinging,
                  callCompositionChange: call.callCompositionChange.toCompositionChangeTypeEntity(),
                  numberOfParticipants: call.numParticipants,
                  isOnHold: call.isOnHold,
                  sessionClientIds: sessionClientIds,
                  clientSessions: sessionClientIds.compactMap { call.session(forClientId: UInt64($0))?.toChatSessionEntity() },
                  participants: (0..<call.participants.size).map { call.participants.megaHandle(at: $0) },
                  waitingRoomStatus: call.waitingRoomJoiningStatus.toWaitingRoomStatusEntity(),
                  waitingRoom: call.waitingRoom.toWaitingRoomEntity(),
                  waitingRoomHandleList: call.waitingRoomHandleList.toHandleEntityArray() ?? [],
                  uuid: call.uuid)
    }
}

extension MEGAChatCallStatus {
    func toCallStatusType() -> CallEntity.CallStatusType {
        switch self {
        case .undefined:
            return .undefined
        case .initial:
            return .initial
        case .userNoPresent:
            return .userNoPresent
        case .waitingRoom:
            return .waitingRoom
        case .connecting:
            return .connecting
        case .joining:
            return .joining
        case .inProgress:
            return .inProgress
        case .terminatingUserParticipation:
            return .terminatingUserParticipation
        case .destroyed:
            return .destroyed
        @unknown default:
            return .undefined
        }
    }
}

extension MEGAChatCallTermCode {
    func toTermCodeTypeEntity() -> CallEntity.TermCodeType {
        switch self {
        case .invalid:
            return .invalid
        case .userHangup:
            return .userHangup
        case .tooManyParticipants:
            return .tooManyParticipants
        case .callReject:
            return .reject
        case .error:
            return .error
        case .noParticipate:
            return .noParticipate
        case .tooManyClients:
            return .tooManyClients
        case .protocolVersion:
            return .protocolVersion
        case .kicked:
            return .kicked
        case .waitingRoomTimeout:
            return .waitingRoomTimeout
        @unknown default:
            return .invalid
        }
    }
}

extension MEGAChatCallChangeType {
    func toChangeTypeEntity() -> CallEntity.ChangeType {
        switch self {
        case .noChanges:
            return .noChanges
        case .status:
            return .status
        case .localAVFlags:
            return .localAVFlags
        case .ringingStatus:
            return .ringingStatus
        case .callComposition:
            return .callComposition
        case .callOnHold:
            return .onHold
        case .callSpeak:
            return .callSpeak
        case .audioLevel:
            return .audioLevel
        case .networkQuality:
            return .networkQuality
        case .outgoingRingingStop:
            return .outgoingRingingStop
        case .ownPermissions:
            return .ownPermission
        case .genericNotification:
            return .genericNotification
        case .waitingRoomAllow:
            return .waitingRoomAllow
        case .waitingRoomDeny:
            return .waitingRoomDeny
        case .waitingRoomComposition:
            return .waitingRoomComposition
        case .waitingRoomUsersEntered:
            return .waitingRoomUsersEntered
        case .waitingRoomUsersLeave:
            return .waitingRoomUsersLeave
        case .waitingRoomUsersAllow:
            return .waitingRoomUsersAllow
        case .waitingRoomUsersDeny:
            return .waitingRoomUsersDeny
        case .waitingRoomPushedFromCall:
            return .waitingRoomPushedFromCall
        @unknown default:
            return .noChanges
        }
    }
}

extension MEGAChatCallCompositionChange {
    func toCompositionChangeTypeEntity() -> CallEntity.CompositionChangeType {
        switch self {
        case .peerRemoved:
            return .peerRemoved
        case .noChange:
            return .noChange
        case .peerAdded:
            return .peerAdded
        @unknown default:
            return .noChange
        }
    }
}

extension MEGAChatCallNotificationType {
    func toNotificationTypeEntity() -> CallEntity.NotificationType {
        switch self {
        case .invalid:
            return .invalid
        case .sfuError:
            return .serverError
        case .sfuDeny:
            return .sfuDeny
        @unknown default:
            return .invalid
        }
    }
}
