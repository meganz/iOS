import Foundation
@testable import MEGA
import MEGADomain

final class MockChatRoom: MEGAChatRoom {
    private let peerPrivilage: MEGAChatRoomPrivilege
    
    init(peerPrivilage: MEGAChatRoomPrivilege = .unknown) {
        self.peerPrivilage = peerPrivilage
        super.init()
    }
    
    override func peerPrivilege(byHandle userHande: HandleEntity) -> Int {
        peerPrivilage.rawValue
    }
    
    override var authorizationToken: String {
        ""
    }
}
