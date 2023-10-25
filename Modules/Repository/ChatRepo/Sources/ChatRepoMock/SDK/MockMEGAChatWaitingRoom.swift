import MEGAChatSdk
import MEGASdk

public final class MockMEGAChatWaitingRoom: MEGAChatWaitingRoom {
    private let _userStatus: MEGAChatWaitingRoomStatus
    private let _users: MEGAHandleList?
    
    public init(
        userStatus: MEGAChatWaitingRoomStatus = .allowed,
        users: MEGAHandleList? = nil
    ) {
        _userStatus = userStatus
        _users = users
        super.init()
    }
    
    public override func userStatus(_ userId: UInt64) -> MEGAChatWaitingRoomStatus {
        _userStatus
    }
    
    public override var users: MEGAHandleList? {
        _users
    }
}
