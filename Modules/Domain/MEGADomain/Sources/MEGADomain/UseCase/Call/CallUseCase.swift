import Combine

public protocol CallUseCaseProtocol {
    func startListeningForCallInChat<T: CallCallbacksUseCaseProtocol>(_ chatId: HandleEntity, callbacksDelegate: T)
    func stopListeningForCall()
    func call(for chatId: HandleEntity) -> CallEntity?
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void)
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity
    func startMeetingInWaitingRoomChatNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity
    func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity
    func createActiveSessions()
    func hangCall(for callId: HandleEntity)
    func endCall(for callId: HandleEntity)
    func addPeer(toCall call: CallEntity, peerId: HandleEntity)
    func removePeer(fromCall call: CallEntity, peerId: HandleEntity)
    func allowUsersJoinCall(_ call: CallEntity, users: [HandleEntity])
    func kickUsersFromCall(_ call: CallEntity, users: [HandleEntity])
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [HandleEntity])
    func makePeerAModerator(inCall call: CallEntity, peerId: HandleEntity)
    func removePeerAsModerator(inCall call: CallEntity, peerId: HandleEntity)
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never>
    func onCallUpdate() -> AnyPublisher<CallEntity, Never>
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int)
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws
}

public protocol CallCallbacksUseCaseProtocol: AnyObject {
    func participantJoined(participant: CallParticipantEntity)
    func participantLeft(participant: CallParticipantEntity)
    func waitingRoomUsersAllow(with handles: [HandleEntity])
    func updateParticipant(_ participant: CallParticipantEntity)
    func highResolutionChanged(for participant: CallParticipantEntity)
    func lowResolutionChanged(for participant: CallParticipantEntity)
    func audioLevel(for participant: CallParticipantEntity)
    func callTerminated(_ call: CallEntity)
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity)
    func participantAdded(with handle: HandleEntity)
    func participantRemoved(with handle: HandleEntity)
    func connecting()
    func inProgress()
    func localAvFlagsUpdated(video: Bool, audio: Bool)
    func chatTitleChanged(chatRoom: ChatRoomEntity)
    func networkQualityChanged(_ quality: NetworkQuality)
    func outgoingRingingStopReceived()
    func mutedByClient(handle: HandleEntity)
}

// Default implementation for optional callbacks
public extension CallCallbacksUseCaseProtocol {
    func highResolutionChanged(for participant: CallParticipantEntity) { }
    func lowResolutionChanged(for participant: CallParticipantEntity) { }
    func audioLevel(for participant: CallParticipantEntity) { }
    func callTerminated(_ call: CallEntity) { }
    func participantAdded(with handle: HandleEntity) { }
    func participantRemoved(with handle: HandleEntity) { }
    func connecting() { }
    func inProgress() { }
    func localAvFlagsUpdated(video: Bool, audio: Bool) { }
    func chatTitleChanged(chatRoom: ChatRoomEntity) { }
    func networkQualityChanged(_ quality: NetworkQuality) { }
    func outgoingRingingStopReceived() { }
    func waitingRoomUsersAllow(with handles: [HandleEntity]) { }
    func mutedByClient(handle: HandleEntity) { }
}

public final class CallUseCase<T: CallRepositoryProtocol>: CallUseCaseProtocol {
    
    private let repository: T
    private weak var callbacksDelegate: (any CallCallbacksUseCaseProtocol)?

    public init(repository: T) {
        self.repository = repository
    }
    
    public func startListeningForCallInChat<S: CallCallbacksUseCaseProtocol>(_ chatId: HandleEntity, callbacksDelegate: S) {
        repository.startListeningForCallInChat(chatId, callbacksDelegate: self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    public func stopListeningForCall() {
        self.callbacksDelegate = nil
        repository.stopListeningForCall()
    }
    
    public func call(for chatId: HandleEntity) -> CallEntity? {
        repository.call(for: chatId)
    }
    
    public func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.answerCall(for: chatId, completion: completion)
    }
    
    public func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.answerCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    public func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    public func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    public func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    public func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    public func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startMeetingInWaitingRoomChat(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    public func startMeetingInWaitingRoomChatNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startMeetingInWaitingRoomChatNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }

    public func createActiveSessions() {
        repository.createActiveSessions()
    }
    
    public func hangCall(for callId: HandleEntity) {
        repository.hangCall(for: callId)
    }
    
    public func endCall(for callId: HandleEntity) {
        repository.endCall(for: callId)
    }
    
    public func addPeer(toCall call: CallEntity, peerId: HandleEntity) {
        repository.addPeer(toCall: call, peerId: peerId)
    }
    
    public func removePeer(fromCall call: CallEntity, peerId: HandleEntity) {
        repository.removePeer(fromCall: call, peerId: peerId)
    }
    
    public func allowUsersJoinCall(_ call: CallEntity, users: [HandleEntity]) {
        repository.allowUsersJoinCall(call, users: users)
    }
    
    public func kickUsersFromCall(_ call: CallEntity, users: [HandleEntity]) {
        repository.kickUsersFromCall(call, users: users)
    }
    
    public func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [HandleEntity]) {
        repository.pushUsersIntoWaitingRoom(for: scheduledMeeting, users: users)
    }
    
    public func makePeerAModerator(inCall call: CallEntity, peerId: HandleEntity) {
        repository.makePeerAModerator(inCall: call, peerId: peerId)
    }
    
    public func removePeerAsModerator(inCall call: CallEntity, peerId: HandleEntity) {
        repository.removePeerAsModerator(inCall: call, peerId: peerId)
    }
    
    public func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        repository.callWaitingRoomUsersUpdate(forCall: call)
    }
    
    public func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        repository.onCallUpdate()
    }
    
    public func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        repository.callAbsentParticipant(inChat: chatId, userId: userId, timeout: timeout)
    }
    
    public func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        try await repository.muteUser(inChat: chatRoom, clientId: clientId)
    }
}

extension CallUseCase: CallCallbacksRepositoryProtocol {

    public func createdSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.participantJoined(participant: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func destroyedSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.participantLeft(participant: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func avFlagsUpdated(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.updateParticipant(CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func audioLevel(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func callTerminated(_ call: CallEntity) {
        callbacksDelegate?.callTerminated(call)
    }
    
    public func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        callbacksDelegate?.ownPrivilegeChanged(to: privilege, in: chatRoom)
    }
    
    public func participantAdded(with handle: HandleEntity) {
        callbacksDelegate?.participantAdded(with: handle)
    }
    
    public func participantRemoved(with handle: HandleEntity) {
        callbacksDelegate?.participantRemoved(with: handle)
    }
    
    public func connecting() {
        callbacksDelegate?.connecting()
    }
    
    public func inProgress() {
        callbacksDelegate?.inProgress()
    }
    
    public func onHiResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.highResolutionChanged(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func onLowResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.lowResolutionChanged(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    public func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    public func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
    
    public func networkQualityChanged(_ quality: NetworkQuality) {
        callbacksDelegate?.networkQualityChanged(quality)
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
