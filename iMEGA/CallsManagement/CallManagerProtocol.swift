import MEGADomain

/// Define entry points for call actions (start, mute, end call..) from any place (app UI, CallKit, links...)
/// and management of calls in progress
protocol CallManagerProtocol: AnyObject {
    func startCall(in chatRoom: ChatRoomEntity, chatIdBase64Handle: String, hasVideo: Bool, notRinging: Bool, isJoiningActiveCall: Bool)
    func answerCall(in chatRoom: ChatRoomEntity)
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool)
    func muteCall(in chatRoom: ChatRoomEntity, muted: Bool)
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID?
    func call(forUUID uuid: UUID) -> CallActionSync?
    func removeCall(withUUID uuid: UUID)
    func removeAllCalls()
    func addCall(withUUID uuid: UUID, chatRoom: ChatRoomEntity)
    func updateCall(withUUID uuid: UUID, muted: Bool)
}
