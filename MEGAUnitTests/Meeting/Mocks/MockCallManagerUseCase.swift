@testable import MEGA

final class MockCallManagerUseCase: CallManagerUseCaseProtocol {
    var endCall_calledTimes = 0
    var muteUnmute_CalledTimes = 0
    var addCall_CalledTimes = 0
    var startCall_CalledTimes = 0
    
    func endCall(_ call: CallEntity) {
        endCall_calledTimes += 1
    }
    
    func muteUnmuteCall(callId: MEGAHandle, chatId: MEGAHandle, muted: Bool) {
        muteUnmute_CalledTimes += 1
    }
    
    func addCall(_ call: CallEntity) {
        addCall_CalledTimes += 1
    }
    
    func startCall(_ call: CallEntity) {
        startCall_CalledTimes += 1
    }
}
