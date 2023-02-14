import Foundation
@testable import MEGA
import MEGADomain

final class MockShare: MEGAShare {
    private let sharedUserEmail: String?
    private let sharedNodeHandle: HandleEntity
    private let accessLevel: ShareAccessLevelEntity
    private let createdDate: Date
    private let isSharedNodePending: Bool
    private let isSharedNodeVerified: Bool
    
    init(nodeHandle: HandleEntity,
         sharedUserEmail: String? = nil,
         accessLevel: ShareAccessLevelEntity = .unknown,
         createdDate: Date = Date(),
         isPending: Bool = false,
         isVerified: Bool = false) {
        self.sharedNodeHandle = nodeHandle
        self.sharedUserEmail = sharedUserEmail
        self.accessLevel = accessLevel
        self.isSharedNodePending = isPending
        self.isSharedNodeVerified = isVerified
        self.createdDate = createdDate
        super.init()
    }
    
    override var nodeHandle: UInt64 { sharedNodeHandle }
    
    override var timestamp: Date { createdDate }
}
