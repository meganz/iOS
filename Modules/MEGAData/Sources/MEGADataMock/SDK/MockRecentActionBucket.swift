import MEGASdk

public final class MockRecentActionBucket: MEGARecentActionBucket {
    private let _timestamp: Date
    private let _email: String
    private let _parentHandle: MEGAHandle
    private let _isUpdate: Bool
    private let _isMedia: Bool
    private let _nodeList: MEGANodeList
    
    public init(
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
    
    public override var timestamp: Date! {
        _timestamp
    }
    
    public override var userEmail: String! {
        _email
    }
    
    public override var parentHandle: UInt64 {
        _parentHandle
    }
    
    public override var isUpdate: Bool {
        _isUpdate
    }
    
    public override var isMedia: Bool {
        _isMedia
    }
    
    public override var nodesList: MEGANodeList! {
        _nodeList
    }
}
