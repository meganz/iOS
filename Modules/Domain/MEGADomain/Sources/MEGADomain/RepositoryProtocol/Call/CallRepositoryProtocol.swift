import Combine

public protocol CallRepositoryProtocol: Sendable {
    func call(for chatId: HandleEntity) -> CallEntity?
    func answerCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, localizedCameraName: String?) async throws -> CallEntity
    func startCall(for chatId: HandleEntity, enableVideo: Bool, enableAudio: Bool, notRinging: Bool, localizedCameraName: String?) async throws -> CallEntity
    func hangCall(for callId: HandleEntity)
    func endCall(for callId: HandleEntity)
    func addPeer(toCall call: CallEntity, peerId: UInt64)
    func removePeer(fromCall call: CallEntity, peerId: UInt64)
    func allowUsersJoinCall(_ call: CallEntity, users: [UInt64])
    func kickUsersFromCall(_ call: CallEntity, users: [UInt64])
    func pushUsersIntoWaitingRoom(for scheduledMeeting: ScheduledMeetingEntity, users: [UInt64])
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64)
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64)
    func localAvFlagsChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never>
    func callStatusChaged(forCallId callId: HandleEntity) -> AnyPublisher<CallEntity, Never>
    func callWaitingRoomUsersUpdate(forCall call: CallEntity) -> AnyPublisher<CallEntity, Never>
    func onCallUpdate() -> AnyPublisher<CallEntity, Never>
    func callAbsentParticipant(inChat chatId: ChatIdEntity, userId: HandleEntity, timeout: Int)
    func muteUser(inChat chatRoom: ChatRoomEntity, clientId: ChatIdEntity) async throws
    func setCallLimit(inChat chatRoom: ChatRoomEntity, duration: Int?, maxUsers: Int?, maxClientPerUser: Int?, maxClients: Int?, divider: Int?) async throws
    func enableAudioForCall(in chatRoom: ChatRoomEntity) async throws
    func disableAudioForCall(in chatRoom: ChatRoomEntity) async throws
    func enableAudioMonitor(forCall call: CallEntity)
    func disableAudioMonitor(forCall call: CallEntity)
    func raiseHand(forCall call: CallEntity) async throws
    func lowerHand(forCall call: CallEntity) async throws
}
