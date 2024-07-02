import Combine
import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class CallRepository: NSObject, CallRepositoryProtocol {
    
    public static var newRepo: CallRepository {
        CallRepository(chatSdk: .sharedChatSdk)
    }
    
    private let chatSdk: MEGAChatSdk
    private var callbacksDelegate: (any CallCallbacksRepositoryProtocol)?
    
    private var callId: HandleEntity?
    private var call: CallEntity?
    
    private var callUpdateListeners = [CallUpdateListener]()
    private var callWaitingRoomUsersUpdateListener: CallWaitingRoomUsersUpdateListener?
    private var onCallUpdateListener: OnCallUpdateListener?
    
    private var callAvailabilityListener: CallAvailabilityListener?
    private var chatOnlineListener: ChatOnlineListener?
    
    private let callLimitNoPresent = 0xFFFFFFFF
    
    public init(chatSdk: MEGAChatSdk) {
        self.chatSdk = chatSdk
    }

    public func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: any CallCallbacksRepositoryProtocol) {
        if let call = chatSdk.chatCall(forChatId: chatId) {
            self.call = call.toCallEntity()
            self.callId = call.callId
        }
        
        chatSdk.add(self as any MEGAChatCallDelegate)
        chatSdk.add(self as any MEGAChatDelegate)
        self.callbacksDelegate = callbacksDelegate
    }
    
    public func stopListeningForCall() {
        chatSdk.remove(self as any MEGAChatCallDelegate)
        chatSdk.remove(self as any MEGAChatDelegate)
        self.call = nil
        self.callId = .invalid
        self.callbacksDelegate = nil
    }
    
    public func call(for chatId: HandleEntity) -> CallEntity? {
        guard let chatCall = chatSdk.chatCall(forChatId: chatId) else { return nil }
        return chatCall.toCallEntity()
    }
    
    public func answerCall(
        for chatId: HandleEntity,
        enableVideo: Bool,
        enableAudio: Bool,
        localizedCameraName: String?
    ) async throws -> CallEntity {
        return try await withAsyncThrowingValue { completion in
            answerCall(
                chatId: chatId,
                enableVideo: enableVideo,
                enableAudio: enableAudio,
                localizedCameraName: localizedCameraName
            ) { [weak self] result in
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
    
    public func startCall(
        for chatId: HandleEntity,
        enableVideo: Bool,
        enableAudio: Bool,
        notRinging: Bool,
        localizedCameraName: String?
    ) async throws -> CallEntity {
        try await startCall(
            chatId: chatId,
            enableVideo: enableVideo,
            enableAudio: enableAudio,
            notRinging: notRinging,
            localizedCameraName: localizedCameraName
        )
    }
    
    public func createActiveSessions() {
        guard let call, !call.clientSessions.isEmpty, let chatRoom = chatSdk.chatRoom(forChatId: call.chatId) else {
            return
        }
        call.clientSessions.forEach {
            callbacksDelegate?.createdSession($0, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: $0.peerId).toChatRoomPrivilegeEntity())
        }
    }
    
    public func hangCall(for callId: HandleEntity) {
        chatSdk.hangChatCall(callId)
    }
    
    public func endCall(for callId: HandleEntity) {
        chatSdk.endChatCall(callId)
    }
    
    public func addPeer(toCall call: CallEntity, peerId: UInt64) {
        chatSdk.invite(toChat: call.chatId, user: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    public func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        chatSdk.remove(fromChat: call.chatId, userHandle: peerId)
    }
    
    public func allowUsersJoinCall(_ call: CallEntity, users: [UInt64]) {
        chatSdk.allowUsersJoinCall(call.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    public func kickUsersFromCall(_ call: CallEntity, users: [UInt64]) {
        chatSdk.kickUsers(fromCall: call.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    public func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [UInt64]) {
        chatSdk.pushUsers(intoWaitingRoom: scheduledMeeting.chatId, usersHandles: users.map(NSNumber.init(value:)))
    }
    
    public func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.moderator.rawValue)
    }
    
    public func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        chatSdk.updateChatPermissions(call.chatId, userHandle: peerId, privilege: MEGAChatRoomPrivilege.standard.rawValue)
    }
    
    public func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .localAVFlags)
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        callUpdateListener(forCallId: callId, change: .status)
            .monitor
            .eraseToAnyPublisher()
    }
    
    public func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        let callWaitingRoomUsersUpdate = CallWaitingRoomUsersUpdateListener(sdk: chatSdk, callId: call.callId)
        callWaitingRoomUsersUpdateListener = callWaitingRoomUsersUpdate
        
        return callWaitingRoomUsersUpdate
            .monitor
    }
    
    public func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        let onCallUpdate = OnCallUpdateListener(sdk: chatSdk)
        onCallUpdateListener = onCallUpdate
        
        return onCallUpdate
            .monitor
    }
    
    public func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        chatSdk.ringIndividual(inACall: chatId, userId: userId, timeout: timeout)
    }
    
    public func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
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
    
    public func setCallLimit(
        inChat chatRoom: ChatRoomEntity,
        duration: Int? = nil,
        maxUsers: Int? = nil,
        maxClientPerUser: Int? = nil,
        maxClients: Int? = nil,
        divider: Int? = nil
    ) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.setLimitsInCall(
                chatRoom.chatId,
                duration: duration ?? callLimitNoPresent,
                maxUsers: maxUsers ?? callLimitNoPresent,
                maxClientsPerUser: maxClientPerUser ?? callLimitNoPresent,
                maxClients: maxClients ?? callLimitNoPresent,
                divider: divider ?? callLimitNoPresent,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            )
        }
    }
    
    public func enableAudioForCall(in chatRoom: ChatRoomEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.enableAudio(
                forChat: chatRoom.chatId,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            )
        }
    }
    
    public func disableAudioForCall(in chatRoom: ChatRoomEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.disableAudio(
                forChat: chatRoom.chatId,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            )
        }
    }
    
    public func enableAudioMonitor(forCall call: CallEntity) {
        guard !chatSdk.isAudioLevelMonitorEnabled(forChatId: call.chatId) else { return }
        chatSdk.enableAudioMonitor(true, chatId: call.chatId)
    }
    
    public func disableAudioMonitor(forCall call: CallEntity) {
        guard chatSdk.isAudioLevelMonitorEnabled(forChatId: call.chatId) else { return }
        chatSdk.enableAudioMonitor(false, chatId: call.chatId)
    }
    
    public func raiseHand(forCall call: CallEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.raiseHandToSpeak(
                forCall: call.chatId,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            )
        }
    }
    
    public func lowerHand(forCall call: CallEntity) async throws {
        try await withAsyncThrowingValue { completion in
            chatSdk.lowerHandToStopSpeak(
                forCall: call.chatId,
                delegate: ChatRequestDelegate(completion: { result in
                    switch result {
                    case .success:
                        completion(.success(()))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                })
            )
        }
    }
    
    // MARK: - Private
    private func callUpdateListener(forCallId callId: HandleEntity, change: CallEntity.ChangeType) -> CallUpdateListener {
        guard let callUpdateListener = callUpdateListeners.filter({ $0.callId == callId && change == $0.changeType }).first else {
            let callUpdateListener = CallUpdateListener(sdk: chatSdk, callId: callId, changeType: change)
            callUpdateListeners.append(callUpdateListener)
            return callUpdateListener
        }
        
        return callUpdateListener
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
    
    public func onChatSessionUpdate(_ api: MEGAChatSdk, chatId: UInt64, callId: UInt64, session: MEGAChatSession) {
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
    
    public func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
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
                break
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
    public func onChatListItemUpdate(_ api: MEGAChatSdk, item: MEGAChatListItem) {
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

extension CallRepository {
    private func startCall(chatId: ChatIdEntity, enableVideo: Bool, enableAudio: Bool, notRinging: Bool, localizedCameraName: String?) async throws -> CallEntity {
        try await withCheckedThrowingContinuation { continuation in
            chatOnlineListener = ChatOnlineListener(
                chatId: chatId,
                sdk: chatSdk
            ) { [weak self] chatId in
                guard let self else { return }
                chatOnlineListener = nil
                let delegate = ChatRequestDelegate { [weak self] completion in
                    switch completion {
                    case .success:
                        guard let self, let call = chatSdk.chatCall(forChatId: chatId) else {
                            continuation.resume(with: .failure(CallErrorEntity.generic))
                            return
                        }
                        continuation.resume(with: .success(call.toCallEntity()))
                    case .failure(let error):
                        switch error.type {
                        case .MEGAChatErrorTooMany:
                            continuation.resume(with: .failure(CallErrorEntity.tooManyParticipants))
                        default:
                            continuation.resume(with: .failure(CallErrorEntity.generic))
                        }
                    }
                }
                if let localizedCameraName {
                    chatSdk.setChatVideoInDevices(localizedCameraName)
                }
                chatSdk.startCall(inChat: chatId, enableVideo: enableVideo, enableAudio: enableAudio, notRinging: notRinging, delegate: delegate)
            }
        }
    }
    
    private func answerCall(chatId: UInt64, enableVideo: Bool, enableAudio: Bool, localizedCameraName: String?, completion: @escaping MEGAChatRequestCompletion) {
        let group = DispatchGroup()
        
        group.enter()
        chatOnlineListener = ChatOnlineListener(
            chatId: chatId,
            sdk: chatSdk
        ) { [weak self] _ in
            guard let self else { return }
            chatOnlineListener = nil
            group.leave()
        }
        
        group.enter()
        callAvailabilityListener = CallAvailabilityListener(
            chatId: chatId,
            sdk: self.chatSdk
        ) { [weak self] _, _ in
            guard let self else { return }
            callAvailabilityListener = nil
            group.leave()
        }
        
        group.notify(queue: .main) { [self] in
            let answerCallChatRequestDelegate = ChatRequestDelegate { requestCompletion in
                switch requestCompletion {
                case .success(let request):
                    completion(.success(request))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            if let localizedCameraName {
                chatSdk.setChatVideoInDevices(localizedCameraName)
            }
            chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallChatRequestDelegate)
        }
    }
}

/// ChatOnlineListener is a helper class to listen for the chat online status.
/// It will notify to the listener when the chat is online.
private final class ChatOnlineListener: NSObject {
    private let chatId: UInt64
    typealias Completion = (_ chatId: UInt64) -> Void
    private var completion: Completion?
    private let sdk: MEGAChatSdk

    init(chatId: UInt64,
         sdk: MEGAChatSdk,
         completion: @escaping Completion) {
        self.chatId = chatId
        self.sdk = sdk
        self.completion = completion
        super.init()
        
        if sdk.chatConnectionState(chatId) == .online {
            completion(chatId)
            self.completion = nil
        } else {
            addListener()
        }
    }
    
    private func addListener() {
        sdk.add(self as (any MEGAChatDelegate))
    }
    
    private func removeListener() {
        sdk.remove(self as (any MEGAChatDelegate))
    }
}

extension ChatOnlineListener: MEGAChatDelegate {
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        if self.chatId == chatId,
           newState == MEGAChatConnection.online.rawValue {
            removeListener()
            completion?(chatId)
            self.completion = nil
        }
    }
}

/// CallAvailabilityListener is a helper class to listen for the call availability.
/// It will notify to the listener when the call is available.
private final class CallAvailabilityListener: NSObject {
    private let chatId: UInt64
    typealias Completion = (_ chatId: UInt64, _ call: MEGAChatCall) -> Void
    private var completion: Completion?
    private let sdk: MEGAChatSdk

    init(chatId: UInt64,
         sdk: MEGAChatSdk,
         completion: @escaping Completion) {
        self.chatId = chatId
        self.sdk = sdk
        self.completion = completion
        super.init()
        
        if let call = sdk.chatCall(forChatId: chatId) {
            completion(chatId, call)
            self.completion = nil
        } else {
            addListener()
        }
    }
    
    private func addListener() {
        sdk.add(self as (any MEGAChatCallDelegate))
    }
    
    private func removeListener() {
        sdk.remove(self as (any MEGAChatCallDelegate))
    }
}

extension CallAvailabilityListener: MEGAChatCallDelegate {
    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        if call.chatId == chatId {
            removeListener()
            completion?(chatId, call)
            self.completion = nil
        }
    }
}
