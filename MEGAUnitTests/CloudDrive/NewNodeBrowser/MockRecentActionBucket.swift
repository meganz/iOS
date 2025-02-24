@testable import MEGA
import MEGADomain

struct MockRecentActionBucketTrampoline: RecentActionBucket {
    func removing(_ handles: [HandleEntity]) -> MockRecentActionBucketTrampoline {
        assertionFailure("Not implemented")
        return self
    }
    
    var isUpdate: Bool = false
    var parentNodeToReturn: NodeEntity?
    
    func parentNode() -> NodeEntity? {
        parentNodeToReturn
    }
    
    var timestamp: Date?
    
    var nodes: [NodeEntity] = []
    
    func allNodes() -> [NodeEntity] {
        nodes
    }
    
    func nodeAt(idx: Int) -> MEGADomain.NodeEntity? {
        nodes[idx]
    }
    
    var nodeCount: Int {
        nodes.count
    }
    
    var isMedia: Bool = false
    
    var parentHandle: HandleEntity = .invalid
    
}
