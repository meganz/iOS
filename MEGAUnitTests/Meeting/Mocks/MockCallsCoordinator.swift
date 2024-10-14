@testable import MEGA
import MEGADomain

final class MockCallsCoordinator: CallsCoordinatorProtocol, @unchecked Sendable {
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var muteCall_CalledTimes = 0
    var reportIncomingCall_CalledTimes = 0
    var reportEndCall_CalledTimes = 0
    var disablePassCodeIfNeeded_CalledTimes = 0
    var startCallResult_ToReturn = false
    var answerCallResult_ToReturn = false
    var endCallResult_ToReturn = false
    var muteCallResult_ToReturn = false
    var configureWebRTCAudioSession_CalledTimes = 0
    
    var incomingCallForUnknownChat: IncomingCallForUnknownChat?
    var reportIncomingCallExpectationClosure: (() -> Void)?

    nonisolated init() { }
    
    func startCall(_ callActionSync: CallActionSync) async -> Bool {
        startCall_CalledTimes += 1
        return startCallResult_ToReturn
    }
    
    func answerCall(_ callActionSync: CallActionSync) async -> Bool {
        answerCall_CalledTimes += 1
        return answerCallResult_ToReturn
    }
    
    func endCall(_ callActionSync: CallActionSync) async -> Bool {
        endCall_CalledTimes += 1
        return endCallResult_ToReturn
    }
    
    func muteCall(_ callActionSync: CallActionSync) async -> Bool {
        muteCall_CalledTimes += 1
        return muteCallResult_ToReturn
    }
    
    func reportIncomingCall(in chatId: ChatIdEntity, completion: @escaping () -> Void) {
        reportIncomingCall_CalledTimes += 1
        reportIncomingCallExpectationClosure?()
    }
    
    func reportEndCall(_ call: CallEntity) {
        reportEndCall_CalledTimes += 1
    }
    
    func disablePassCodeIfNeeded() {
        disablePassCodeIfNeeded_CalledTimes += 1
    }
    
    func configureWebRTCAudioSession() {
        configureWebRTCAudioSession_CalledTimes += 1
    }
}
