@testable import MEGA
import MEGADomain

final class MockCallController: CallControllerProtocol {
    init(expectationClosure: (() -> Void)? = nil) {
        self.expectationClosure = expectationClosure
    }
    
    var configureCallsCoordinator = 0
    var startCall_CalledTimes = 0
    var answerCall_CalledTimes = 0
    var endCall_CalledTimes = 0
    var muteCall_CalledTimes = 0
    
    var expectationClosure: (() -> Void)?
        
    func configureCallsCoordinator(_ callsCoordinator: MEGA.CallsCoordinator) {
        configureCallsCoordinator += 1
    }
    
    func startCall(with actionSync: CallActionSync) {
        startCall_CalledTimes += 1
    }
    
    func answerCall(in chatRoom: ChatRoomEntity, withUUID uuid: UUID) {
        answerCall_CalledTimes += 1
    }
    
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool) {
        endCall_CalledTimes += 1
        expectationClosure?()
    }
    
    func muteCall(in chatRoom: MEGADomain.ChatRoomEntity, muted: Bool) {
        muteCall_CalledTimes += 1
    }
}
