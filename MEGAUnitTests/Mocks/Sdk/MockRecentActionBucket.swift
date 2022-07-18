import Foundation
@testable import MEGA

final class MockRecentActionBucket: MEGARecentActionBucket {
    private let _timestamp: Date
    private let _email: String
    private let _parentHandle: MEGAHandle
    private let _isUpdate: Bool
    private let _isMedia: Bool
    private let _nodeList: MEGANodeList
    
    init(
        timestamp: Date = Date(),
        email: String = "name@email.com",
        parentHandle: MEGAHandle = 1,
        isUpdate: Bool = false,
        isMedia: Bool = false,
        nodeList: MEGANodeList = MockNodeList()
    ) {
        _timestamp = timestamp
        _email = email
        _parentHandle = parentHandle
        _isUpdate = isUpdate
        _isMedia = isMedia
        _nodeList = nodeList
        super.init()
    }
    
    override var timestamp: Date! {
        _timestamp
    }
    
    override var userEmail: String! {
        _email
    }
    
    override var parentHandle: UInt64 {
        _parentHandle
    }
    
    override var isUpdate: Bool {
        _isUpdate
    }
    
    override var isMedia: Bool {
        _isMedia
    }
    
    override var nodesList: MEGANodeList! {
        _nodeList
    }
}
