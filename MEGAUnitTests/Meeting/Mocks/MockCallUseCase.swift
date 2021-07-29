@testable import MEGA

final class MockCallUseCase: CallsUseCaseProtocol {
    var startListeningForCall_CalledTimes = 0
    var stopListeningForCall_CalledTimes = 0
    var callCompletion: Result<CallEntity, CallErrorEntity> = .failure(.generic)
    var createActiveSessions_calledTimes = 0
    var hangCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var addPeer_CalledTimes = 0
    var removePeer_CalledTimes = 0
    var makePeerAsModerator_CalledTimes = 0
    var removePeerAsModerator_CalledTimes = 0
    var callEntity: CallEntity?

    func startListeningForCallInChat(_ chatId: MEGAHandle, callbacksDelegate: CallsCallbacksUseCaseProtocol) {
        startListeningForCall_CalledTimes += 1
    }
    
    func stopListeningForCall() {
        stopListeningForCall_CalledTimes += 1
    }
    
    func call(for chatId: MEGAHandle) -> CallEntity? {
        return callEntity
    }
    
    func answerIncomingCall(for chatId: MEGAHandle, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func startOutgoingCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func joinActiveCall(for chatId: MEGAHandle, enableVideo: Bool, enableAudio: Bool, completion: @escaping (Result<CallEntity, CallErrorEntity>) -> Void) {
        completion(callCompletion)
    }
    
    func createActiveSessions() {
        createActiveSessions_calledTimes += 1
    }
    
    func hangCall(for callId: MEGAHandle) {
        hangCall_CalledTimes += 1
    }
    
    func endCall(for callId: MEGAHandle) {
        endCall_CalledTimes += 1
    }
    
    func addPeer(toCall call: CallEntity, peerId: UInt64) {
        addPeer_CalledTimes += 1
    }
    
    func removePeer(fromCall call: CallEntity, peerId: UInt64) {
        removePeer_CalledTimes += 1
    }
    
    func makePeerAModerator(inCall call: CallEntity, peerId: UInt64) {
        makePeerAsModerator_CalledTimes += 1
    }
    
    func removePeerAsModerator(inCall call: CallEntity, peerId: UInt64) {
        removePeerAsModerator_CalledTimes += 1
    }
}
