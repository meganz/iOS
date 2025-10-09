import MEGAChatSdk
import MEGASdk

public final class MockMEGAChatCall: MEGAChatCall, @unchecked Sendable {
    
    private let _status: MEGAChatCallStatus
    private let _chatId: UInt64
    private let _callId: UInt64
    private let _changes: MEGAChatCallChangeType
    private let _waitingRoom: MEGAChatWaitingRoom
    private let _waitingRoomHandleList: MEGAHandleList
    
    public init(
        status: MEGAChatCallStatus = .undefined,
        chatId: UInt64 = 1,
        callId: UInt64 = 1,
        changes: MEGAChatCallChangeType = .noChanges,
        waitingRoom: MEGAChatWaitingRoom = MockMEGAChatWaitingRoom(),
        waitingRoomHandleList: MEGAHandleList = .init()
    ) {
        _status = status
        _chatId = chatId
        _callId = callId
        _changes = changes
        _waitingRoom = waitingRoom
        _waitingRoomHandleList = waitingRoomHandleList
        super.init()
    }
    
    public override var status: MEGAChatCallStatus {
        _status
    }
    
    public override var chatId: UInt64 {
        _chatId
    }
    
    public override var callId: UInt64 {
        _callId
    }
    
    public override var changes: MEGAChatCallChangeType {
        _changes
    }
    
    public override var waitingRoom: MEGAChatWaitingRoom {
        _waitingRoom
    }
    
    public override var waitingRoomHandleList: MEGAHandleList {
        _waitingRoomHandleList
    }
}
