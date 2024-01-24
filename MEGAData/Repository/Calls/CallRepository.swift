import ChatRepo
import Combine
import MEGADomain
import MEGASwift

final class CallRepository: NSObject, CallRepositoryProtocol {

    static var newRepo: CallRepository {
        CallRepository(chatSdk: .shared, callActionManager: .shared)
    }
    
    private let chatSdk: MEGAChatSdk
    private let callActionManager: CallActionManager
    private var callbacksDelegate: (any CallCallbacksRepositoryProtocol)?

    private var callId: HandleEntity?
    private var call: CallEntity?
    
    private var callUpdateListeners = [CallUpdateListener]()
    private var callWaitingRoomUsersUpdateListener: CallWaitingRoomUsersUpdateListener?
    private var onCallUpdateListener: OnCallUpdateListener?

    init(chatSdk: MEGAChatSdk, callActionManager: CallActionManager) {
        self.chatSdk = chatSdk
        self.callActionManager = callActionManager
    }
    
    func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: any CallCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = call.toCallEntity()
            self.callId = call.callId
        }

        chatSdk.add(self as any MEGAChatCallDelegate)
        chatSdk.add(self as any MEGAChatDelegate)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func stopListeningForCall() {
        chatSdk.remove(self as any MEGAChatCallDelegate)
        chatSdk.remove(self as any MEGAChatDelegate)
        self.call = nil
        self.callId = MEGAInvalidHandle
        self.callbacksDelegate = nil
    }
    
    func call(for chatId: HandleEntity) -> CallEntity? {
        guard let chatCall = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return chatCall.toCallEntity()
    }
    
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = MEGAChatAnswerCallRequestDelegate { [weak self] (error)  in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                let callEntity = call.toCallEntity()
                self?.call = callEntity
                self?.callId = callEntity.callId
                completion(.success(callEntity))
            } else {
                switch error.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }
        
        callActionManager.answerCall(chatId: chatId, enableVideo: false, enableAudio: true, delegate: delegate)
    }
    
    func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        return try await withAsyncThrowingValue { completion in
            callActionManager.answerCall(chatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio) { [weak self] result in
                switch result {
                case .success:
                    guard let self,
                          let megaChatCall = chatSdk.chatCall(forChatId: chatId) else {
                        completion(.failure(CallErrorEntity.generic))
                        return
                    }
                    let callEntity = megaChatCall.toCallEntity()
                    call = callEntity
                    callId = callEntity.callId
                    completion(.success(callEntity))
                case .failure(let error):
                    switch error.type {
                    case .MEGAChatErrorTooMany:
                        completion(.failure(CallErrorEntity.tooManyParticipants))
                    default:
                        completion(.failure(CallErrorEntity.generic))
                    }
                }
            }
        }
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = createStartMeetingRequestDelegate(for: chatId, completion: completion)
        
        callActionManager.startCall(chatId: chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
    }
    
    @MainActor
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio) { result in
                switch result {
                case .success(let callEntity):
                    continuation.resume(returning: callEntity)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        let delegate = createStartMeetingRequestDelegate(for: scheduledMeeting.chatId, completion: completion)
        
        callActionManager.startCallNoRinging(chatId: scheduledMeeting.chatId, scheduledId: scheduledMeeting.scheduledId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: delegate)
    }
    
    @MainActor
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio) { result in
                switch result {
                case .success(let callEntity):
                    continuation.resume(returning: callEntity)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        let call = try await callActionManager.startMeetingInWaitingRoomChat(
            chatId: scheduledMeeting.chatId,
            enableVideo: enableVideo,
            enableAudio: enableAudio
        )
        updateCall(call)
        return call
    }
    
    func startMeetingInWaitingRoomChatNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        let call = try await callActionManager.startMeetingInWaitingRoomChatNoRinging(
            chatId: scheduledMeeting.chatId,
            scheduledId: scheduledMeeting.scheduledId,
            enableVideo: enableVideo,
            enableAudio: enableAudio
        )
        updateCall(call)
        return call
    }
    
    func createActiveSessions() {
        guard let call, !call.clientSessions.isEmpty, let chatRoom = chatSdk.chatRoom(forChatId: call.chatId) else {
            return
        }
        call.clientSessions.forEach {
            callbacksDelegate?.createdSession($0, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: $0.peerId).toChatRoomPrivilegeEntity())
        }
    }
    
    func hangCall(for callId: HandleEntity) {
        chatSdk.hangChatCall(callId)
    }
    
    func endCall(for callId: HandleEntity) {
        chatSdk.endChatCall(callId)
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        chatSdk.invite(toChat: call.chatId, user: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        chatSdk.remove(fromChat: call.chatId, userHandle: peerId)
    }
    
    func allowUsersJoinCall(_ call: CallEntity, users: [UInt64]) {
        chatSdk.allowUsersJoinCall(call.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    func kickUsersFromCall(_ call: CallEntity, users: [UInt64]) {
        chatSdk.kickUsers(fromCall: call.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [UInt64]) {
        chatSdk.pushUsers(intoWaitingRoom: scheduledMeeting.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.moderator.rawValue)
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .localAVFlags)
            .monitor
            .eraseToAnyPublisher()
    }
    
    func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .status)
            .monitor
            .eraseToAnyPublisher()
    }
    
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        let callWaitingRoomUsersUpdate = CallWaitingRoomUsersUpdateListener(sdk: chatSdk, callId: call.callId)
        callWaitingRoomUsersUpdateListener = callWaitingRoomUsersUpdate

        return callWaitingRoomUsersUpdate
            .monitor
    }
    
    func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        let onCallUpdate = OnCallUpdateListener(sdk: chatSdk)
        onCallUpdateListener = onCallUpdate

        return onCallUpdate
            .monitor
    }
    
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        chatSdk.ringIndividual(inACall: chatId, userId: userId, timeout: timeout)
    }
    
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.mutePeers(chatRoom.chatId, client: clientId, delegate: ChatRequestDelegate(completion: { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }))
        }
    }
    
    private func callUpdateListener(forCallId callId: HandleEntity, change: CallEntity.ChangeType) -> CallUpdateListener {
        guard let callUpdateListener = callUpdateListeners.filter({ $0.callId == callId && change == $0.changeType }).first else {
            let callUpdateListener = CallUpdateListener(sdk: chatSdk, callId: callId, changeType: change)
            callUpdateListeners.append(callUpdateListener)
            return callUpdateListener
        }

        return callUpdateListener
    }
    
    private func createStartMeetingRequestDelegate(for chatId: ChatIdEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) -> MEGAChatStartCallRequestDelegate {
        return MEGAChatStartCallRequestDelegate { [weak self] (error) in
            if error.type == .MEGAChatErrorTypeOk {
                guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                    completion(.failure(.generic))
                    return
                }
                self?.call = call.toCallEntity()
                self?.callId = call.callId
                completion(.success(call.toCallEntity()))
            } else {
                switch error.type {
                case .MEGAChatErrorTooMany:
                    completion(.failure(.tooManyParticipants))
                default:
                    completion(.failure(.generic))
                }
            }
        }
    }
    
    private func updateCall(_ call: CallEntity) {
        self.call = call
        self.callId = call.callId
    }
}

private final class CallUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    let changeType: CallEntity.ChangeType
    let callId: HandleEntity
    
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, callId: HandleEntity, changeType: CallEntity.ChangeType) {
        self.sdk = sdk
        self.changeType = changeType
        self.callId = callId
        super.init()
        sdk.add(self)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard call.callId == callId, call.changes.toChangeTypeEntity() == changeType else {
            return
        }
        source.send(call.toCallEntity())
    }
}

extension CallRepository: MEGAChatCallDelegate {
    
    func onChatSessionUpdate(_ api: MEGAChatSdk, chatId: UInt64, callId: UInt64, session: MEGAChatSession) {
        if self.callId != callId {
            return
        }
                
        guard let chatRoom = api.chatRoom(forChatId: chatId) else { return }
        
        if session.hasChanged(.status) {
            switch session.status {
            case .inProgress:
                callbacksDelegate?.createdSession(session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            case .destroyed:
                callbacksDelegate?.destroyedSession(session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            default:
                break
            }
        }
        
        if session.status == .inProgress {
            if session.hasChanged(.remoteAvFlags) {
                callbacksDelegate?.avFlagsUpdated(for: session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.hasChanged(.audioLevel) {
                callbacksDelegate?.audioLevel(for: session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.hasChanged(.onHiRes) {
                callbacksDelegate?.onHiResSessionChanged(session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.hasChanged(.onLowRes) {
                callbacksDelegate?.onLowResSessionChanged(session.toChatSessionEntity(), in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
        }
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        guard callId == call.callId else {
            return
        }
        
        self.call = call.toCallEntity()
        
        if call.hasChanged(for: .localAVFlags) {
            callbacksDelegate?.localAvFlagsUpdated(video: call.hasLocalVideo, audio: call.hasLocalAudio)
            if call.auxHandle != .invalid {
                callbacksDelegate?.mutedByClient(handle: call.auxHandle)
            }
        }
        
        if call.hasChanged(for: .networkQuality) {
            switch call.networkQuality {
            case .bad:
                callbacksDelegate?.networkQualityChanged(.bad)
            case .good:
                callbacksDelegate?.networkQualityChanged(.good)
            @unknown default:
                MEGALogDebug("Call network quality has an unkown status")
            }
        }
        
        if call.hasChanged(for: .outgoingRingingStop) {
            callbacksDelegate?.outgoingRingingStopReceived()
        }
        
        switch call.status {
        case .undefined:
            break
        case .initial:
            break
        case .connecting:
            callbacksDelegate?.connecting()
        case .joining:
            break
        case .inProgress:
            if call.hasChanged(for: .status) {
                callbacksDelegate?.inProgress()
            }
            
            if call.hasChanged(for: .callComposition) {
                if call.peeridCallCompositionChange == chatSdk.myUserHandle {
                    return
                }
                switch call.callCompositionChange {
                case .peerAdded:
                    callbacksDelegate?.participantAdded(with: call.peeridCallCompositionChange)
                case .peerRemoved:
                    callbacksDelegate?.participantRemoved(with: call.peeridCallCompositionChange)
                default:
                    break
                }
            }
            
            if call.hasChanged(for: .waitingRoomUsersAllow) {
                guard let usersHandle = call.waitingRoomHandleList.toHandleEntityArray() else { return }
                callbacksDelegate?.waitingRoomUsersAllow(with: usersHandle)
            }
        case .terminatingUserParticipation, .destroyed:
            callbacksDelegate?.callTerminated(call.toCallEntity())
        case .userNoPresent:
            break
        case .waitingRoom:
            break
        @unknown default:
            fatalError("Call status has an unkown status")
        }
    }
}

extension CallRepository: MEGAChatDelegate {
    func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
        guard let chatId = call?.chatId,
              item.chatId == chatId else {
            return
        }
        
        switch item.changes {
        case .ownPrivilege:
            guard let chatRoom = chatSdk.chatRoom(forChatId: chatId) else {
                return
            }
            callbacksDelegate?.ownPrivilegeChanged(to: item.ownPrivilege.toChatRoomPrivilegeEntity(), in: chatRoom.toChatRoomEntity())
        case .title:
            guard let chatRoom = chatSdk.chatRoom(forChatId: item.chatId) else { return }
            callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom.toChatRoomEntity())
        default:
            break
        }
    }
}

private final class CallWaitingRoomUsersUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    let callId: HandleEntity
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk, callId: HandleEntity) {
        self.sdk = sdk
        self.callId = callId
        super.init()
        sdk.add(self, queueType: .globalBackground)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        let waitingRoomChanges: Set<Bool> = [
            call.hasChanged(for: .waitingRoomComposition),
            call.hasChanged(for: .waitingRoomUsersEntered),
            call.hasChanged(for: .waitingRoomUsersDeny),
            call.hasChanged(for: .waitingRoomUsersAllow),
            call.hasChanged(for: .waitingRoomUsersLeave)
        ]
        
        if callId == call.callId,
           waitingRoomChanges.contains(true) {
            source.send(call.toCallEntity())
        }
    }
}

private final class OnCallUpdateListener: NSObject, MEGAChatCallDelegate {
    private let sdk: MEGAChatSdk
    private let source = PassthroughSubject<CallEntity, Never>()
    
    var monitor: AnyPublisher<CallEntity, Never> {
        source.eraseToAnyPublisher()
    }
    
    init(sdk: MEGAChatSdk) {
        self.sdk = sdk
        super.init()
        sdk.add(self, queueType: .globalBackground)
    }
    
    deinit {
        sdk.remove(self)
    }
    
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        source.send(call.toCallEntity())
    }
}
