import MEGADomain

protocol RecentActionBucket: Sendable {
    var timestamp: Date? { get }
    var nodeCount: Int { get }
    var isMedia: Bool { get }
    var isUpdate: Bool { get }
    var parentHandle: HandleEntity { get }
    
    func allNodes() -> [NodeEntity]
    func nodeAt(idx: Int) -> NodeEntity?
    func parentNode() -> NodeEntity?
}
