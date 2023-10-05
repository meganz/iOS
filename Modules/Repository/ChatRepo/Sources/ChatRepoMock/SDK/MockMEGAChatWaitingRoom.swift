import MEGAChatSdk
import MEGASdk

public final class MockMEGAChatWaitingRoom: MEGAChatWaitingRoom {
    private let _peerStatus: MEGAChatWaitingRoomStatus
    private let _peers: MEGAHandleList?
    
    public init(
        peerStatus: MEGAChatWaitingRoomStatus = .allowed,
        peers: MEGAHandleList? = nil
    ) {
        _peerStatus = peerStatus
        _peers = peers
        super.init()
    }
    
    public override func peerStatus(_ peerId: UInt64) -> MEGAChatWaitingRoomStatus {
        _peerStatus
    }
    
    public override var peers: MEGAHandleList? {
        _peers
    }
}
