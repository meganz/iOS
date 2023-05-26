import MEGASdk

public final class MockShare: MEGAShare {
    private let sharedUserEmail: String?
    private let sharedNodeHandle: MEGAHandle
    private let createdDate: Date
    private let isSharedNodePending: Bool
    private let isSharedNodeVerified: Bool
    
    public init(nodeHandle: MEGAHandle,
                sharedUserEmail: String? = nil,
                createdDate: Date = Date(),
                isPending: Bool = false,
                isVerified: Bool = false) {
        self.sharedNodeHandle = nodeHandle
        self.sharedUserEmail = sharedUserEmail
        self.isSharedNodePending = isPending
        self.isSharedNodeVerified = isVerified
        self.createdDate = createdDate
        super.init()
    }
    
    public override var nodeHandle: UInt64 { sharedNodeHandle }
    
    public override var timestamp: Date { createdDate }
}
