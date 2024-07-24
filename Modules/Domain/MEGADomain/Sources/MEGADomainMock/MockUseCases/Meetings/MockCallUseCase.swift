import Combine
import MEGADomain

public final class MockCallUseCase: CallUseCaseProtocol {
    
    public var startListeningForCall_CalledTimes = 0
    var stopListeningForCall_CalledTimes = 0
    public var createActiveSessions_calledTimes = 0
    public var hangCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    public var addPeer_CalledTimes = 0
    var removePeer_CalledTimes = 0
    public var allowedUsersJoinCall = [HandleEntity]()
    public var allowUsersJoinCall_CalledTimes = 0
    public var kickUsersFromCall_CalledTimes = 0
    var pushUsersIntoWaitingRoom_CalledTimes = 0
    var makePeerAsModerator_CalledTimes = 0
    var removePeerAsModerator_CalledTimes = 0
    public var callAbsentParticipant_CalledTimes = 0
    public var muteParticipant_CalledTimes = 0
    public var enableAudioMonitor_CalledTimes = 0
    public var disableAudioMonitor_CalledTimes = 0
    public var raiseHand_CalledTimes = 0
    public var lowerHand_CalledTimes = 0

    public var call: CallEntity?
    public var callCompletion: Result<CallEntity, CallErrorEntity>
    var answerCallCompletion: Result<CallEntity, CallErrorEntity>
    
    public var callbacksDelegate: (any CallCallbacksUseCaseProtocol)?
    var networkQuality: NetworkQuality = .bad
    public var chatRoom: ChatRoomEntity?
    var video: Bool = false
    var audio: Bool = false
    var chatSession: ChatSessionEntity?
    var participantHandle: HandleEntity = .invalid
    public var callWaitingRoomUsersUpdateSubject = PassthroughSubject<CallEntity, Never>()
    public var callUpdateSubject: PassthroughSubject<CallEntity, Never>
    var muteParticipantCompletion: Result<Void, GenericErrorEntity>
    public var enableDisableAudioError: GenericErrorEntity?
    
    public init(
        call: CallEntity? = CallEntity(),
        callCompletion: Result<CallEntity, CallErrorEntity> = .failure(.generic),
        answerCallCompletion: Result<CallEntity, CallErrorEntity> = .failure(.generic),
        callUpdateSubject: PassthroughSubject<CallEntity, Never> = .init(),
        muteParticipantCompletion: Result<Void, GenericErrorEntity> = .success(())
    ) {
        self.call = call
        self.callCompletion = callCompletion
        self.answerCallCompletion = answerCallCompletion
        self.callUpdateSubject = callUpdateSubject
        self.muteParticipantCompletion = muteParticipantCompletion
    }
    
    public func startListeningForCallInChat<T: CallCallbacksUseCaseProtocol>(_ chatId: HandleEntity, callbacksDelegate: T) {
        startListeningForCall_CalledTimes += 1
    }
    
    public func stopListeningForCall() {
        stopListeningForCall_CalledTimes += 1
    }
    
    public func call(for chatId: HandleEntity) -> CallEntity? {
        call
    }
    
    public func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, localizedCameraName: String?) async throws -> MEGADomain.CallEntity {
        switch answerCallCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    public func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, notRinging: Bool, localizedCameraName: String?) async throws -> MEGADomain.CallEntity {
        switch callCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    public func createActiveSessions() {
        createActiveSessions_calledTimes += 1
    }
    
    public func hangCall(for callId: HandleEntity) {
        hangCall_CalledTimes += 1
    }
    
    public func endCall(for callId: HandleEntity) {
        endCall_CalledTimes += 1
    }
    
    public func addPeer(toCall call: CallEntity, peerId: UInt64) {
        addPeer_CalledTimes += 1
    }
    
    public func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        removePeer_CalledTimes += 1
    }
    
    public func allowUsersJoinCall(_ call: CallEntity, users: [HandleEntity]) {
        allowedUsersJoinCall = users
        allowUsersJoinCall_CalledTimes += 1
    }
    
    public func kickUsersFromCall(_ call: CallEntity, users: [HandleEntity]) {
        kickUsersFromCall_CalledTimes += 1
    }
    
    public func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [HandleEntity]) {
        pushUsersIntoWaitingRoom_CalledTimes += 1
    }
    
    public func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        makePeerAsModerator_CalledTimes += 1
    }
    
    public func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        removePeerAsModerator_CalledTimes += 1
    }
    public func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        callWaitingRoomUsersUpdateSubject.eraseToAnyPublisher()
    }
    
    public func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        callUpdateSubject.eraseToAnyPublisher()
    }
    
    public func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        callAbsentParticipant_CalledTimes += 1
    }
    
    public func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        switch muteParticipantCompletion {
        case .success:
            muteParticipant_CalledTimes += 1
        case .failure(let error):
            throw error
        }
    }
    
    public func setCallLimit(inChat chatRoom: ChatRoomEntity, duration: Int?, maxUsers: Int?, maxClientPerUser: Int?, maxClients: Int?, divider: Int?) async throws { }
    
    public func enableAudioForCall(in chatRoom: MEGADomain.ChatRoomEntity) async throws {
        guard let enableDisableAudioError else {
            return
        }
        throw enableDisableAudioError
    }
    
    public func disableAudioForCall(in chatRoom: MEGADomain.ChatRoomEntity) async throws {
        guard let enableDisableAudioError else {
            return
        }
        throw enableDisableAudioError
    }
    
    public func enableAudioMonitor(forCall call: MEGADomain.CallEntity) {
        enableAudioMonitor_CalledTimes += 1
    }
    
    public func disableAudioMonitor(forCall call: MEGADomain.CallEntity) {
        disableAudioMonitor_CalledTimes += 1
    }
    
    public func raiseHand(forCall call: MEGADomain.CallEntity) async throws {
        raiseHand_CalledTimes += 1
    }
    
    public func lowerHand(forCall call: MEGADomain.CallEntity) async throws {
        lowerHand_CalledTimes += 1
    }
}

extension MockCallUseCase: CallCallbacksRepositoryProtocol {
    
    public func createdSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.participantJoined(participant: CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func destroyedSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.participantLeft(participant: CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func avFlagsUpdated(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.updateParticipant(CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func audioLevel(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func callTerminated(_ call: CallEntity) {
        callbacksDelegate?.callTerminated(call)
    }
    
    public func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        guard let chatRoom = self.chatRoom else {
            return
        }
        callbacksDelegate?.ownPrivilegeChanged(to: chatRoom.ownPrivilege, in: chatRoom)
    }
    
    public func participantAdded(with handle: HandleEntity) {
        callbacksDelegate?.participantAdded(with: participantHandle)
    }
    
    public func participantRemoved(with handle: HandleEntity) {
        callbacksDelegate?.participantRemoved(with: participantHandle)
    }
    
    public func connecting() {
        callbacksDelegate?.connecting()
    }
    
    public func inProgress() {
        callbacksDelegate?.inProgress()
    }
    
    public func onHiResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.highResolutionChanged(for: CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func onLowResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        guard let chatSession = chatSession, let chat = self.chatRoom else {
            return
        }
        callbacksDelegate?.lowResolutionChanged(for: CallParticipantEntity(session: chatSession, chatRoom: chat, privilege: privilege, raisedHand: false))
    }
    
    public func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    public func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
    
    public func networkQualityChanged(_ quality: NetworkQuality) {
        callbacksDelegate?.networkQualityChanged(networkQuality)
    }
    
    public func outgoingRingingStopReceived() {
        callbacksDelegate?.outgoingRingingStopReceived()
    }
    
    public func waitingRoomUsersAllow(with handles: [HandleEntity]) {
        callbacksDelegate?.waitingRoomUsersAllow(with: handles)
    }
    
    public func mutedByClient(handle: HandleEntity) {
        callbacksDelegate?.mutedByClient(handle: handle)
    }
}
