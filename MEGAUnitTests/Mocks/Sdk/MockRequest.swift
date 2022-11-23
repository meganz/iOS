import Foundation
@testable import MEGA
import MEGADomain

final class MockRequest: MEGARequest {
    private let handle: HandleEntity
    
    var magaSetHandle: HandleEntity = HandleEntity.invalid
    var megaSet: MEGASet?
    var megaSetName: String?
    
    init(handle: HandleEntity) {
        self.handle = handle
        
        super.init()
    }
    
    override var nodeHandle: HandleEntity { handle }
    override var set: MEGASet? { megaSet }
    override var text: String? { megaSetName }
    override var parentHandle: UInt64 { magaSetHandle }
}
