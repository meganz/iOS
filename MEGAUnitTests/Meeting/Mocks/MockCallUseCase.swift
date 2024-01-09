import Combine
@testable import MEGA
import MEGADomain

final class MockCallUseCase: CallUseCaseProtocol {
    var startListeningForCall_CalledTimes = 0
    var stopListeningForCall_CalledTimes = 0
    var createActiveSessions_calledTimes = 0
    var hangCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var addPeer_CalledTimes = 0
    var removePeer_CalledTimes = 0
    var allowedUsersJoinCall = [HandleEntity]()
    var allowUsersJoinCall_CalledTimes = 0
    var kickUsersFromCall_CalledTimes = 0
    var pushUsersIntoWaitingRoom_CalledTimes = 0
    var makePeerAsModerator_CalledTimes = 0
    var removePeerAsModerator_CalledTimes = 0
    var callAbsentParticipant_CalledTimes = 0
    var muteParticipant_CalledTimes = 0

    var call: CallEntity?
    var callCompletion: Result<CallEntity, CallErrorEntity>
    var answerCallCompletion: Result<CallEntity, CallErrorEntity>
    
    var callbacksDelegate: (any CallCallbacksUseCaseProtocol)?
    var networkQuality: NetworkQuality = .bad
    var chatRoom: ChatRoomEntity?
    var video: Bool = false
    var audio: Bool = false
    var chatSession: ChatSessionEntity?
    var participantHandle: HandleEntity = .invalid
    var callWaitingRoomUsersUpdateSubject = PassthroughSubject<CallEntity, Never>()
    var callUpdateSubject: PassthroughSubject<CallEntity, Never>
    var muteParticipantCompletion: Result<Void, GenericErrorEntity>
    
    init(
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
    
    func startListeningForCallInChat<T: CallCallbacksUseCaseProtocol>(_ chatId: HandleEntity, callbacksDelegate: T) {
        startListeningForCall_CalledTimes += 1
    }
    
    func stopListeningForCall() {
        stopListeningForCall_CalledTimes += 1
    }
    
    func call(for chatId: HandleEntity) -> CallEntity? {
        call
    }
    
    func answerCall(for chatId: HandleEntity, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(answerCallCompletion)
    }
    
    func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        switch answerCallCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        switch callCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    func startCallNoRinging(for scheduledMeeting: MEGADomain.ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<MEGADomain.CallEntity, MEGADomain.CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func startCallNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        switch callCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func startMeetingInWaitingRoomChat(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> CallEntity {
        switch callCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    func startMeetingInWaitingRoomChatNoRinging(for scheduledMeeting: ScheduledMeetingEntity, enableVideo: Bool, enableAudio: Bool) async throws -> MEGADomain.CallEntity {
        switch callCompletion {
        case .success(let callEntity):
            return callEntity
        case .failure(let failure):
            throw failure
        }
    }
    
    func joinCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func createActiveSessions() {
        createActiveSessions_calledTimes += 1
    }
    
    func hangCall(for callId: HandleEntity) {
        hangCall_CalledTimes += 1
    }
    
    func endCall(for callId: HandleEntity) {
        endCall_CalledTimes += 1
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        addPeer_CalledTimes += 1
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        removePeer_CalledTimes += 1
    }
    
    func allowUsersJoinCall(_ call: CallEntity, users: [HandleEntity]) {
        allowedUsersJoinCall = users
        allowUsersJoinCall_CalledTimes += 1
    }
    
    func kickUsersFromCall(_ call: CallEntity, users: [HandleEntity]) {
        kickUsersFromCall_CalledTimes += 1
    }
    
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [HandleEntity]) {
        pushUsersIntoWaitingRoom_CalledTimes += 1
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        makePeerAsModerator_CalledTimes += 1
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        removePeerAsModerator_CalledTimes += 1
    }
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        callWaitingRoomUsersUpdateSubject.eraseToAnyPublisher()
    }
    
    func onCallUpdate() -> AnyPublisher<CallEntity, Never> {
        callUpdateSubject.eraseToAnyPublisher()
    }
    
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        callAbsentParticipant_CalledTimes += 1
    }
    
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        switch muteParticipantCompletion {
        case .success:
            muteParticipant_CalledTimes += 1
        case .failure(let error):
            throw error
        }
    }
}

extension MockCallUseCase: CallCallbacksRepositoryProtocol {
    
    func createdSession(_ session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.participantJoined(participant: CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func destroyedSession(_ session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.participantLeft(participant: CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func avFlagsUpdated(for session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.updateParticipant(CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func audioLevel(for session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.audioLevel(for: CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func callTerminated(_ call: CallEntity) {
        callbacksDelegate?.callTerminated(call)
    }
    
    func ownPrivilegeChanged(to privilege: ChatRoomPrivilegeEntity, in chatRoom: ChatRoomEntity) {
        guard let chatRoom = self.chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.ownPrivilegeChanged(to: chatRoom.ownPrivilege, in: chatRoom)
    }
    
    func participantAdded(with handle: HandleEntity) {
        callbacksDelegate?.participantAdded(with: participantHandle)
    }
    
    func participantRemoved(with handle: HandleEntity) {
        callbacksDelegate?.participantRemoved(with: participantHandle)
    }
    
    func connecting() {
        callbacksDelegate?.connecting()
    }
    
    func inProgress() {
        callbacksDelegate?.inProgress()
    }
    
    func onHiResSessionChanged(_ session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.highResolutionChanged(for: CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func onLowResSessionChanged(_ session: ChatSessionEntity, in chatId: HandleEntity) {
        guard let chatSession = chatSession, let chatRoom = chatRoom else {
            MEGALogDebug("Error getting mock properties")
            return
        }
        callbacksDelegate?.lowResolutionChanged(for: CallParticipantEntity(session: chatSession, chatId: chatRoom.chatId))
    }
    
    func localAvFlagsUpdated(video: Bool, audio: Bool) {
        callbacksDelegate?.localAvFlagsUpdated(video: video, audio: audio)
    }
    
    func chatTitleChanged(chatRoom: ChatRoomEntity) {
        callbacksDelegate?.chatTitleChanged(chatRoom: chatRoom)
    }
    
    func networkQualityChanged(_ quality: NetworkQuality) {
        callbacksDelegate?.networkQualityChanged(networkQuality)
    }
    
    func outgoingRingingStopReceived() {
        callbacksDelegate?.outgoingRingingStopReceived()
    }
    
    func waitingRoomUsersAllow(with handles: [HandleEntity]) {
        callbacksDelegate?.waitingRoomUsersAllow(with: handles)
    }
}
