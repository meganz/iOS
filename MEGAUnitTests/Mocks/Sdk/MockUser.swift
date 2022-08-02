import Foundation
@testable import MEGA

final class MockUser: MEGAUser {
    private let _handle: HandleEntity
    private let _visibility: MEGAUserVisibility
    
    init(handle: HandleEntity = 0, visibility: MEGAUserVisibility = .visible) {
        _handle = handle
        _visibility = visibility
        super.init()
    }
    
    override var handle: HandleEntity {
        _handle
    }
    
    override var visibility: MEGAUserVisibility {
        _visibility
    }
}
