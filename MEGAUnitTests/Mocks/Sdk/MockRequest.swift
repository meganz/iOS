import Foundation
@testable import MEGA
import MEGADomain

final class MockRequest: MEGARequest {
    private let handle: HandleEntity
    
    var megaSetHandle: HandleEntity = HandleEntity.invalid
    var megaSetElementHandle: HandleEntity = HandleEntity.invalid
    var megaSet: MEGASet?
    var megaSetName: String?
    var updateSet = true
    var megaSetElementName: String?
    var megaElementInSet: [MEGASetElement] = []
    var megaSetElementOrder: Int64 = 0
    
    init(handle: HandleEntity) {
        self.handle = handle
        
        super.init()
    }
    
    override var nodeHandle: HandleEntity { handle }
    override var set: MEGASet? { megaSet }
    override var text: String? { updateSet ? megaSetName : megaSetElementName }
    override var parentHandle: UInt64 { updateSet ? megaSetHandle : megaSetElementHandle }
    override var elementsInSet: [MEGASetElement] { megaElementInSet }
    override var number: NSNumber { NSNumber(value: megaSetElementOrder) }
}
