import MEGAChatSdk
import MEGADomain

public extension MEGAChatCall {
    func toCallEntity() -> CallEntity {
        CallEntity(with: self)
    }
}

fileprivate extension CallEntity {
    init(with call: MEGAChatCall) {
        let sessionClientIds = (0..<(call.sessionsClientId?.size ?? 0)).compactMap { call.sessionsClientId?.megaHandle(at: $0) }
        self.init(
            status: call.status.toCallStatusType(),
            chatId: call.chatId,
            callId: call.callId,
            changeType: call.changes.toChangeTypeEntity(),
            duration: call.duration,
            initialTimestamp: call.initialTimeStamp,
            finalTimestamp: call.finalTimeStamp,
            callWillEndTimestamp: call.callWillEndTimeStamp,
            hasLocalAudio: call.hasLocalAudio,
            hasLocalVideo: call.hasLocalVideo,
            termCodeType: call.termCode.toTermCodeTypeEntity(),
            callLimits: CallLimitsEntity(
                durationLimit: call.durationLimit,
                maxUsers: call.usersLimit,
                maxClientsPerUser: call.clientsPerUserLimit,
                maxClients: call.clientsLimit),
            isRinging: call.isRinging,
            callCompositionChange: call.callCompositionChange.toCompositionChangeTypeEntity(),
            numberOfParticipants: call.numParticipants,
            isOnHold: call.isOnHold,
            isOwnClientCaller: call.isOwnClientCaller,
            sessionClientIds: sessionClientIds,
            clientSessions: sessionClientIds.compactMap { call.session(forClientId: UInt64($0))?.toChatSessionEntity() },
            participants: (0..<(call.participants?.size ?? 0)).compactMap { call.participants?.megaHandle(at: $0) },
            waitingRoomStatus: call.waitingRoomJoiningStatus.toWaitingRoomStatusEntity(),
            waitingRoom: call.waitingRoom?.toWaitingRoomEntity(),
            waitingRoomHandleList: call.waitingRoomHandleList?.toHandleEntityArray() ?? [],
            raiseHandsList: call.raiseHandsList?.toHandleEntityArray() ?? [],
            auxHandle: call.auxHandle,
            networkQuality: call.networkQuality == .bad ? .bad : .good,
            peeridCallCompositionChange: call.peeridCallCompositionChange,
            uuid: call.uuid
        )
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
        case .callDurationLimit:
            return .callDurationLimit
        case .callUsersLimit:
            return .callUsersLimit
        @unknown default:
            return .invalid
        }
    }
}

public extension MEGAChatCallChangeType {
    func toChangeTypeEntity() -> CallEntity.ChangeType {
        switch self {
        case .noChanges:
            .noChanges
        case .status:
            .status
        case .localAVFlags:
            .localAVFlags
        case .ringingStatus:
            .ringingStatus
        case .callComposition:
            .callComposition
        case .callOnHold:
            .onHold
        case .callSpeak:
            .callSpeak
        case .audioLevel:
            .audioLevel
        case .networkQuality:
            .networkQuality
        case .outgoingRingingStop:
            .outgoingRingingStop
        case .ownPermissions:
            .ownPermission
        case .genericNotification:
            .genericNotification
        case .waitingRoomAllow:
            .waitingRoomAllow
        case .waitingRoomDeny:
            .waitingRoomDeny
        case .waitingRoomComposition:
            .waitingRoomComposition
        case .waitingRoomUsersEntered:
            .waitingRoomUsersEntered
        case .waitingRoomUsersLeave:
            .waitingRoomUsersLeave
        case .waitingRoomUsersAllow:
            .waitingRoomUsersAllow
        case .waitingRoomUsersDeny:
            .waitingRoomUsersDeny
        case .waitingRoomPushedFromCall:
            .waitingRoomPushedFromCall
        case .speakRequested:
            .speakRequested
        case .callWillEnd:
            .callWillEnd
        case .callLimitsUpdated:
            .callLimitsUpdated
        case .callRaiseHand:
            .callRaiseHand
        @unknown default:
            .noChanges
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

public extension CallEntity {
    func toMEGAChatCall() -> MEGAChatCall? {
        MEGAChatSdk.sharedChatSdk.chatCall(forCallId: callId)
    }
}
