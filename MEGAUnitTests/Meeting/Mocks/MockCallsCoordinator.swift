@testable import MEGA
import MEGADomain

final class MockCallsCoordinator: CallsCoordinatorProtocol {
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var muteCall_CalledTimes = 0
    var reportIncomingCall_CalledTimes = 0
    var reportEndCall_CalledTimes = 0
    var disablePassCodeIfNeeded_CalledTimes = 0

    func startCall(_ callActionSync: CallActionSync) async -> Bool {
        startCall_CalledTimes += 1
        return false
    }
    
    func answerCall(_ callActionSync: CallActionSync) async -> Bool {
        answerCall_CalledTimes += 1
        return false
    }
    
    func endCall(_ callActionSync: CallActionSync) async -> Bool {
        endCall_CalledTimes += 1
        return false
    }
    
    func muteCall(_ callActionSync: CallActionSync) async -> Bool {
        muteCall_CalledTimes += 1
        return false
    }
    
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void) {
        reportIncomingCall_CalledTimes += 1
    }
    
    func reportEndCall(_ call: CallEntity) {
        reportEndCall_CalledTimes += 1
    }
    
    func disablePassCodeIfNeeded() {
        disablePassCodeIfNeeded_CalledTimes += 1
    }
}
