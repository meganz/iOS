import Foundation
@testable import MEGA

final class MockRequest: MEGARequest {
    private let handle: MEGAHandle
    
    init(handle: MEGAHandle) {
        self.handle = handle
        super.init()
    }
    
    override var nodeHandle: MEGAHandle { handle }
}
