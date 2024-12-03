import Combine
import MEGADomain
import MEGADomainMock

final class MockCallRepository: CallRepositoryProtocol, @unchecked Sendable {    
    func call(for chatId: HandleEntity) -> CallEntity? {
        nil
    }
    
    func answerCall(for chatId: MEGADomain.HandleEntity, enableVideo: Bool, enableAudio: Bool, localizedCameraName: String?) async throws -> MEGADomain.CallEntity {
        CallEntity()
    }
    
    func startCall(for chatId: MEGADomain.HandleEntity, enableVideo: Bool, enableAudio: Bool, notRinging: Bool, localizedCameraName: String?) async throws -> MEGADomain.CallEntity {
        CallEntity()
    }
    
    func hangCall(for callId: HandleEntity) {
        
    }
    
    func endCall(for callId: HandleEntity) {
        
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        
    }
    
    func allowUsersJoinCall(_ call: CallEntity, users: [UInt64]) {
        
    }
    
    func kickUsersFromCall(_ call: CallEntity, users: [UInt64]) {
        
    }
    
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [UInt64]) {
        
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        
    }
    
    func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        Just(CallEntity()).eraseToAnyPublisher()
    }
    
    func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never> {
        Just(CallEntity()).eraseToAnyPublisher()
    }
    
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never> {
        Just(CallEntity()).eraseToAnyPublisher()
    }
    
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int) {
        
    }
    
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws {
        
    }
    
    func setCallLimit(inChat chatRoom: ChatRoomEntity, duration: Int?, maxUsers: Int?, maxClientPerUser: Int?, maxClients: Int?, divider: Int?) async throws {
        
    }
    
    func enableAudioForCall(in chatRoom: ChatRoomEntity) async throws {
        
    }
    
    func disableAudioForCall(in chatRoom: ChatRoomEntity) async throws {
        
    }
    
    func enableAudioMonitor(forCall call: CallEntity) {
        
    }
    
    func disableAudioMonitor(forCall call: CallEntity) {
        
    }
    
    var errorToThrow: (any Error)?
    
    var raiseHandCalls: [CallEntity] = []
    func raiseHand(forCall call: CallEntity) async throws {
        raiseHandCalls.append(call)
        if let errorToThrow {
            throw errorToThrow
        }
    }
    
    var lowerHandCalls: [CallEntity] = []
    func lowerHand(forCall call: CallEntity) async throws {
        lowerHandCalls.append(call)
        if let errorToThrow {
            throw errorToThrow
        }
    }
}
