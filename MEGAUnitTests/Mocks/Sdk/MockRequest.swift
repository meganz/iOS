import Foundation
@testable import MEGA

final class MockRequest: MEGARequest {
    private let handle: HandleEntity
    
    init(handle: HandleEntity) {
        self.handle = handle
        super.init()
    }
    
    override var nodeHandle: HandleEntity { handle }
}
