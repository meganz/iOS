import Foundation
@testable import MEGA

final class MockChatRoom: MEGAChatRoom {
    private let peerPrivilage: MEGAChatRoomPrivilege
    
    init(peerPrivilage: MEGAChatRoomPrivilege = .unknown) {
        self.peerPrivilage = peerPrivilage
        super.init()
    }
    
    override func peerPrivilege(byHandle userHande: MEGAHandle) -> Int {
        peerPrivilage.rawValue
    }
    
    override var authorizationToken: String {
        ""
    }
}
