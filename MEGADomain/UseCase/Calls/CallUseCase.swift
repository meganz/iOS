import Combine
import MEGADomain

protocol CallUseCaseProtocol {
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

protocol CallCallbacksUseCaseProtocol: AnyObject {
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
}

// Default implementation for optional callbacks
extension CallCallbacksUseCaseProtocol {
    func highResolutionChanged(for participant: CallParticipantEntity) { }
    func lowResolutionChanged(for participant: CallParticipantEntity) { }
    func audioLevel(for attende: CallParticipantEntity) { }
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
}

final class CallUseCase<T: CallRepositoryProtocol>: NSObject, CallUseCaseProtocol {
    
    private let repository: T
    private weak var callbacksDelegate: (any CallCallbacksUseCaseProtocol)?

    init(repository: T) {
        self.repository = repository
    }
    
    func startListeningForCallInChat<S: CallCallbacksUseCaseProtocol>(_ chatId: HandleEntity, callbacksDelegate: S) {
        repository.startListeningForCallInChat(chatId, callbacksDelegate: self)
        self.callbacksDelegate = callbacksDelegate
    }
    
    func stopListeningForCall() {
        self.callbacksDelegate = nil
        repository.stopListeningForCall()
    }
    
    func call(for chatId: HandleEntity) -> CallEntity? {
        repository.call(for: chatId)
    }
    
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.answerCall(for: chatId, completion: completion)
    }
    
    func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.answerCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startCall(for: chatId, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        repository.startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio, completion: completion)
    }
    
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startCallNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startMeetingInWaitingRoomChat(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }
    
    func startMeetingInWaitingRoomChatNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        try await repository.startMeetingInWaitingRoomChatNoRinging(for: scheduledMeeting, enableVideo: enableVideo, enableAudio: enableAudio)
    }

    func createActiveSessions() {
        repository.createActiveSessions()
    }
    
    func hangCall(for callId: HandleEntity) {
        repository.hangCall(for: callId)
    }
    
    func endCall(for callId: HandleEntity) {
        repository.endCall(for: callId)
    }
    
    func addPeer(toCall call: CallEntity, peerId: HandleEntity) {
        repository.addPeer(toCall: call, peerId: peerId)
    }
    
    func removePeer(fromCall call: CallEntity, peerId: HandleEntity) {
        repository.removePeer(fromCall: call, peerId: peerId)
    }
    
    func allowUsersJoinCall(_ call: CallEntity, users: [HandleEntity]) {
        repository.allowUsersJoinCall(call, users: users)
    }
    
    func kickUsersFromCall(_ call: CallEntity, users: [HandleEntity]) {
        repository.kickUsersFromCall(call, users: users)
    }
    
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [HandleEntity]) {
        repository.pushUsersIntoWaitingRoom(for: scheduledMeeting, users: users)
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: HandleEntity) {
        repository.makePeerAModerator(inCall: call, peerId: peerId)
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: HandleEntity) {
        repository.removePeerAsModerator(inCall: call, peerId: peerId)
    }
    
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        repository.callWaitingRoomUsersUpdate(forCall: call)
    }
    
    func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        repository.onCallUpdate()
    }
    
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        repository.callAbsentParticipant(inChat: chatId, userId: userId, timeout: timeout)
    }
    
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        try await repository.muteUser(inChat: chatRoom, clientId: clientId)
    }
}

extension CallUseCase: CallCallbacksRepositoryProtocol {

    func createdSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.participantJoined(participant: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func destroyedSession(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.participantLeft(participant: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func avFlagsUpdated(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.updateParticipant(CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func audioLevel(for session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func callTerminated(_ call: CallEntity) {
        callbacksDelegate?.callTerminated(call)
    }
    
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        callbacksDelegate?.ownPrivilegeChanged(to: privilege, in: chatRoom)
    }
    
    func participantAdded(with handle: HandleEntity) {
        callbacksDelegate?.participantAdded(with: handle)
    }
    
    func participantRemoved(with handle: HandleEntity) {
        callbacksDelegate?.participantRemoved(with: handle)
    }
    
    func connecting() {
        callbacksDelegate?.connecting()
    }
    
    func inProgress() {
        callbacksDelegate?.inProgress()
    }
    
    func onHiResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.highResolutionChanged(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func onLowResSessionChanged(_ session: ChatSessionEntity, in chatRoom: ChatRoomEntity, privilege: ChatRoomPrivilegeEntity) {
        callbacksDelegate?.lowResolutionChanged(for: CallParticipantEntity(session: session, chatRoom: chatRoom, privilege: privilege))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
    
    func networkQualityChanged(_ quality: NetworkQuality) {
        callbacksDelegate?.networkQualityChanged(quality)
    }
    
    func outgoingRingingStopReceived() {
        callbacksDelegate?.outgoingRingingStopReceived()
    }
    
    func waitingRoomUsersAllow(with handles: [HandleEntity]) {
        callbacksDelegate?.waitingRoomUsersAllow(with: handles)
    }
}
