@testable import MEGA
import MEGADomain

final class MockCallCoordinatorUseCase: CallCoordinatorUseCaseProtocol {
    var endCall_calledTimes = 0
    var muteUnmute_CalledTimes = 0
    var addCall_CalledTimes = 0
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var addCallRemoved_CalledTimes = 0
    var removeCallRemoved_CalledTimes = 0

    func endCall(_ call: CallEntity) {
        endCall_calledTimes += 1
    }
    
    func muteUnmuteCall(_ call: CallEntity, muted: Bool) {
        muteUnmute_CalledTimes += 1
    }
    
    func addCall(_ call: CallEntity) {
        addCall_CalledTimes += 1
    }
    
    func startCall(_ call: CallEntity) {
        startCall_CalledTimes += 1
    }
    
    func answerCall(_ call: CallEntity) {
        answerCall_CalledTimes += 1
    }
    
    func addCallRemoved(handler: @escaping (UUID?) -> Void) {
        addCallRemoved_CalledTimes += 1
    }
    
    func removeCallRemovedHandler() {
        removeCallRemoved_CalledTimes += 1
    }
}
