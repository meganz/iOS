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
    var updateSetCover = false
    var megaSetElementName: String?
    var megaElementInSet: [MEGASetElement] = []
    var megaSetElementOrder: Int64 = 0
    var megaCoverId: HandleEntity = HandleEntity.invalid
    
    init(handle: HandleEntity) {
        self.handle = handle
        
        super.init()
    }
    
    override var nodeHandle: HandleEntity { updateSetCover ? megaCoverId : handle }
    override var set: MEGASet? { megaSet }
    override var text: String? { updateSet ? megaSetName : megaSetElementName }
    override var parentHandle: UInt64 { updateSet ? megaSetHandle : megaSetElementHandle }
    override var elementsInSet: [MEGASetElement] { megaElementInSet }
    override var number: NSNumber { NSNumber(value: megaSetElementOrder) }
}
