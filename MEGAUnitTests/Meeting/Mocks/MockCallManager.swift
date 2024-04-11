@testable import MEGA
import MEGADomain

final class MockCallManager: CallManagerProtocol {
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var callUUID_CalledTimes = 0
    var callForUUID_CalledTimes = 0
    var removeCall_CalledTimes = 0
    
    func startCall(in chatRoom: ChatRoomEntity, hasVideo: Bool, notRinging: Bool) {
        startCall_CalledTimes += 1
    }
    
    func answerCall(in chatRoom: ChatRoomEntity) {
        answerCall_CalledTimes += 1
    }
    
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool) {
        endCall_CalledTimes += 1
    }
    
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID? {
        callUUID_CalledTimes += 1
        return nil
    }

    func call(forUUID uuid: UUID) -> CallActionSync? {
        callForUUID_CalledTimes += 1
        return nil
    }
    
    func removeCall(withUUID uuid: UUID) {
        removeCall_CalledTimes += 1
    }
}
