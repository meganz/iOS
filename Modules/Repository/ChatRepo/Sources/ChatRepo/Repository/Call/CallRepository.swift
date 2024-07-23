import Combine
import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class CallRepository: NSObject, CallRepositoryProtocol, Sendable {
    
    public static var newRepo: CallRepository {
        CallRepository(
            chatSdk: .sharedChatSdk,
            callSessionRepository: CallSessionRepository.newRepo,
            chatRepository: ChatRepository.newRepo
        )
    }
    
    private let chatSdk: MEGAChatSdk
    private let chatRepository: any ChatRepositoryProtocol
    private let callRepositoryCallbacksActor: CallRepositoryCallbacksActor
    private let callLimitNoPresent = 0xFFFFFFFF
    
    private let waitingRoomChanges: Set<CallEntity.ChangeType> = [
        .waitingRoomComposition,
        .waitingRoomUsersEntered,
        .waitingRoomUsersDeny,
        .waitingRoomUsersAllow,
        .waitingRoomUsersLeave
    ]
    
    public init(
        chatSdk: MEGAChatSdk,
        callSessionRepository: some CallSessionRepositoryProtocol,
        chatRepository: some ChatRepositoryProtocol
    ) {
        self.chatSdk = chatSdk
        self.chatRepository = chatRepository
        self.callRepositoryCallbacksActor = CallRepositoryCallbacksActor(
            chatSdk: chatSdk,
            callSessionRepository: callSessionRepository,
            chatRepository: chatRepository
        )
    }

    public func startListeningForCallInChat(_ chatId: HandleEntity, callbacksDelegate: any CallCallbacksRepositoryProtocol) {
        Task {
            await callRepositoryCallbacksActor.startListeningForCallInChat(chatId: chatId, callbacksDelegate: callbacksDelegate)
        }
    }
    
    public func stopListeningForCall() {
        Task {
            await callRepositoryCallbacksActor.stopListeningForCall()
        }
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
        async let chatOnline: Void = chatRepository.listenForChatOnline(chatId)
        async let callAvailability: Void = chatRepository.listenForCallAvailability(chatId)
        
        _ = await [chatOnline, callAvailability]
        
        return try await withCheckedThrowingContinuation { continuation in
            let answerCallChatRequestDelegate = ChatRequestDelegate { [weak self] requestCompletion in
                switch requestCompletion {
                case .success:
                    guard let megaChatCall = self?.chatSdk.chatCall(forChatId: chatId) else {
                        continuation.resume(throwing: CallErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: megaChatCall.toCallEntity())
                case .failure(let error):
                    let errorEntity: CallErrorEntity = switch error.type {
                        case .MEGAChatErrorTooMany:
                            .tooManyParticipants
                        default:
                            .generic
                    }
                    continuation.resume(throwing: errorEntity)
                }
            }
            if let localizedCameraName {
                chatSdk.setChatVideoInDevices(localizedCameraName)
            }
            chatSdk.answerChatCall(chatId, enableVideo: enableVideo, enableAudio: enableAudio, delegate: answerCallChatRequestDelegate)
        }
    }
    
    public func startCall(
        for chatId: HandleEntity,
        enableVideo: Bool,
        enableAudio: Bool,
        notRinging: Bool,
        localizedCameraName: String?
    ) async throws -> CallEntity {
        _ = await chatRepository.listenForChatOnline(chatId)
        
        return try await withCheckedThrowingContinuation { continuation in
            let delegate = ChatRequestDelegate { [weak self] completion in
                switch completion {
                case .success:
                    guard let call = self?.chatSdk.chatCall(forChatId: chatId) else {
                        continuation.resume(throwing: CallErrorEntity.generic)
                        return
                    }
                    continuation.resume(returning: call.toCallEntity())
                case .failure(let error):
                    switch error.type {
                    case .MEGAChatErrorTooMany:
                        continuation.resume(throwing: CallErrorEntity.tooManyParticipants)
                    default:
                        continuation.resume(throwing: CallErrorEntity.generic)
                    }
                }
            }
            if let localizedCameraName {
                chatSdk.setChatVideoInDevices(localizedCameraName)
            }
            chatSdk.startCall(inChat: chatId, enableVideo: enableVideo, enableAudio: enableAudio, notRinging: notRinging, delegate: delegate)
        }
    }
    
    public func createActiveSessions() {
        Task {
            await callRepositoryCallbacksActor.createActiveSessions()
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
        chatRepository.monitorChatCallUpdate(for: callId, changeTypes: [.localAVFlags])
    }
    
    public func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        chatRepository.monitorChatCallUpdate(for: callId, changeTypes: [.status])
    }
    
    public func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        chatRepository.monitorChatCallUpdate(for: call.callId, changeTypes: waitingRoomChanges)
    }
    
    public func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        chatRepository.monitorChatCallUpdate()
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
}

private actor CallRepositoryCallbacksActor {
    private var callSessionRepository: any CallSessionRepositoryProtocol
    private var chatRepository: any ChatRepositoryProtocol
    private let chatSdk: MEGAChatSdk
    private var callEntity: CallEntity?
    private var subscriptions: Set<AnyCancellable> = []
    private weak var callbacksDelegate: (any CallCallbacksRepositoryProtocol)?
    
    init(
        chatSdk: MEGAChatSdk,
        callSessionRepository: some CallSessionRepositoryProtocol,
        chatRepository: some ChatRepositoryProtocol
    ) {
        self.chatSdk = chatSdk
        self.callSessionRepository = callSessionRepository
        self.chatRepository = chatRepository
    }
    
    func startListeningForCallInChat(chatId: HandleEntity, callbacksDelegate: some CallCallbacksRepositoryProtocol) {
        var callId: HandleEntity?
        
        if let call = chatSdk.chatCall(forChatId: chatId)?.toCallEntity() {
            self.callEntity = call
            callId = call.callId
        }
        
        self.callbacksDelegate = callbacksDelegate
        
        callSessionRepository
            .onCallSessionUpdate()
            .filter { $0.1.callId == callId }
            .sink { [weak self] session, _ in
                guard let self else { return }
                Task {
                    await self.processChatSessionUpdate(session, chatId: chatId)
                }
            }.store(in: &subscriptions)
        
        chatRepository
            .monitorChatCallUpdate()
            .filter { $0.callId == callId }
            .sink { [weak self] callEntity in
                guard let self else { return }
                Task {
                    await self.processChatCallUpdate(callEntity)
                }
            }.store(in: &subscriptions)
        
        chatRepository
            .monitorChatListItemSingleUpdate()
            .filter { $0.chatId == chatId }
            .sink { [weak self] chatListItemEntity in
                guard let self else { return }
                Task {
                    await self.processChatListItemUpdate(chatListItemEntity)
                }
            }.store(in: &subscriptions)
        
    }
    
    func stopListeningForCall() {
        callEntity = nil
        subscriptions.forEach { $0.cancel() }
    }
    
    func createActiveSessions() {
        guard let callEntity, !callEntity.clientSessions.isEmpty, let chatRoom = chatSdk.chatRoom(forChatId: callEntity.chatId) else {
            return
        }
        callEntity.clientSessions.forEach {
            callbacksDelegate?.createdSession($0, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: $0.peerId).toChatRoomPrivilegeEntity())
        }
    }
    
    private func processChatSessionUpdate(_ session: ChatSessionEntity, chatId: HandleEntity) {
        guard let chatRoom = chatSdk.chatRoom(forChatId: chatId) else { return }
        
        if session.changeType == .status {
            switch session.statusType {
            case .inProgress:
                callbacksDelegate?.createdSession(session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            case .destroyed:
                callbacksDelegate?.destroyedSession(session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            default:
                break
            }
        }
        
        if session.statusType == .inProgress {
            if session.changeType == .remoteAvFlags {
                callbacksDelegate?.avFlagsUpdated(for: session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.changeType == .audioLevel {
                callbacksDelegate?.audioLevel(for: session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.changeType == .onHiRes {
                callbacksDelegate?.onHiResSessionChanged(session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
            
            if session.changeType == .onLowRes {
                callbacksDelegate?.onLowResSessionChanged(session, in: chatRoom.toChatRoomEntity(), privilege: chatRoom.peerPrivilege(byHandle: session.peerId).toChatRoomPrivilegeEntity())
            }
        }
    }
    
    private func processChatCallUpdate(_ callEntity: CallEntity) {
        self.callEntity = callEntity
        guard let call = chatSdk.chatCall(forCallId: callEntity.callId) else { return }
        
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
    
    private func processChatListItemUpdate(_ chatListItemEntity: ChatListItemEntity) {
        switch chatListItemEntity.changeType {
        case .ownPrivilege:
            guard let chatRoom = chatSdk.chatRoom(forChatId: chatListItemEntity.chatId) else {
                return
            }
            callbacksDelegate?.ownPrivilegeChanged(to: chatListItemEntity.ownPrivilege, in: chatRoom.toChatRoomEntity())
        case .title:
            guard let chatRoom = chatSdk.chatRoom(forChatId: chatListItemEntity.chatId) else { return }
            callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom.toChatRoomEntity())
        default:
            break
        }
    }
}
