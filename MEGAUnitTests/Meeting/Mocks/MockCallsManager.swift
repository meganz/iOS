@testable import MEGA
import MEGADomain

final class MockCallsManager: CallsManagerProtocol {
    struct Incoming: Equatable {
        var uuid: UUID
        var chatRoom: ChatRoomEntity
    }
    
    var callUUID_CalledTimes = 0
    var callForUUID_CalledTimes = 0
    var removeCall_CalledTimes = 0
    var removeAllCalls_CalledTimes = 0
    var updateCallMuted_CalledTimes = 0
    var updateEndForAllCall_CalledTimes = 0
    var addCall_CalledTimes = 0
    
    var incomingCalls = [Incoming]()
    var callForUUIDToReturn: CallActionSync?
    
    var endCallExpectationClosure: (() -> Void)?
    
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID? {
        callUUID_CalledTimes += 1
        return incomingCalls.first(where: { $0.chatRoom == chatRoom })?.uuid
    }

    func call(forUUID uuid: UUID) -> CallActionSync? {
        callForUUID_CalledTimes += 1
        return callForUUIDToReturn
    }
    
    func removeCall(withUUID uuid: UUID) {
        removeCall_CalledTimes += 1
        endCallExpectationClosure?()
    }
    
    func removeAllCalls() {
        removeAllCalls_CalledTimes += 1
    }
    
    func updateCall(withUUID uuid: UUID, muted: Bool) {
        updateCallMuted_CalledTimes += 1
    }
    
    func updateEndForAllCall(withUUID uuid: UUID) {
        updateEndForAllCall_CalledTimes += 1
    }
    
    func addCall(_ call: CallActionSync, withUUID uuid: UUID) {
        incomingCalls.append(.init(uuid: uuid, chatRoom: call.chatRoom))
        addCall_CalledTimes += 1
    }
}
