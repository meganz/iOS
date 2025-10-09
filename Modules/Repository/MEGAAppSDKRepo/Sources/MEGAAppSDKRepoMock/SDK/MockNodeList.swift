import MEGASdk

public final class MockNodeList: MEGANodeList, @unchecked Sendable {
    private let nodes: [MEGANode]
    
    public init(nodes: [MEGANode] = []) {
        self.nodes = nodes
        super.init()
    }
    
    public override var size: Int {
        nodes.count
    }
    
    public override func node(at index: Int) -> MEGANode? {
        nodes[safe: index]
    }
}
