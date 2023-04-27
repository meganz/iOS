import Foundation
@testable import MEGA
import MEGADomain

final class MockChatRoom: MEGAChatRoom {
    private let peerPrivilage: MEGAChatRoomPrivilege
    private let ownPrivilage: MEGAChatRoomPrivilege
    
    init(peerPrivilage: MEGAChatRoomPrivilege = .unknown, ownPrivilage: MEGAChatRoomPrivilege = .unknown) {
        self.peerPrivilage = peerPrivilage
        self.ownPrivilage = ownPrivilage
        
        super.init()
    }
    
    override var ownPrivilege: MEGAChatRoomPrivilege {
        ownPrivilage
    }
    
    override func peerPrivilege(byHandle userHande: HandleEntity) -> Int {
        peerPrivilage.rawValue
    }
    
    override var authorizationToken: String {
        ""
    }
}
