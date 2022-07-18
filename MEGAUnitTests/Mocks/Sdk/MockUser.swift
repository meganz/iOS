import Foundation
@testable import MEGA

final class MockUser: MEGAUser {
    private let _handle: MEGAHandle
    private let _visibility: MEGAUserVisibility
    
    init(handle: MEGAHandle = 0, visibility: MEGAUserVisibility = .visible) {
        _handle = handle
        _visibility = visibility
        super.init()
    }
    
    override var handle: MEGAHandle {
        _handle
    }
    
    override var visibility: MEGAUserVisibility {
        _visibility
    }
}
