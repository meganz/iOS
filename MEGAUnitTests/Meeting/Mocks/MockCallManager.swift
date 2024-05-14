@testable import MEGA
import MEGADomain

final class MockCallManager: CallManagerProtocol {
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var muteCall_CalledTimes = 0
    var callUUID_CalledTimes = 0
    var callForUUID_CalledTimes = 0
    var removeCall_CalledTimes = 0
    var removeAllCalls_CalledTimes = 0
    var addIncomingCall_CalledTimes = 0
    var callForUUIDToReturn: CallActionSync?
    var updateCallMuted_CalledTimes = 0

    func startCall(in chatRoom: ChatRoomEntity, chatIdBase64Handle: String, hasVideo: Bool, notRinging: Bool, isJoiningActiveCall: Bool) {
        startCall_CalledTimes += 1
    }
    
    func answerCall(in chatRoom: ChatRoomEntity) {
        answerCall_CalledTimes += 1
    }
    
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool) {
        endCall_CalledTimes += 1
    }
    
    func muteCall(in chatRoom: MEGADomain.ChatRoomEntity, muted: Bool) {
        muteCall_CalledTimes += 1
    }
    
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID? {
        callUUID_CalledTimes += 1
        return nil
    }

    func call(forUUID uuid: UUID) -> CallActionSync? {
        callForUUID_CalledTimes += 1
        return callForUUIDToReturn
    }
    
    func removeCall(withUUID uuid: UUID) {
        removeCall_CalledTimes += 1
    }
    
    func removeAllCalls() {
        removeAllCalls_CalledTimes += 1
    }
    
    func addIncomingCall(withUUID uuid: UUID, chatRoom: ChatRoomEntity) {
        addIncomingCall_CalledTimes += 1
    }
    
    func updateCall(withUUID uuid: UUID, muted: Bool) {
        updateCallMuted_CalledTimes += 1
    }
}
