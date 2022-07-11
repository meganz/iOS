import Foundation
@testable import MEGA

final class MockNodeList: MEGANodeList {
    private let nodes: [MEGANode]
    
    init(nodes: [MEGANode] = []) {
        self.nodes = nodes
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(value: nodes.count)
    }
    
    override func node(at index: Int) -> MEGANode! {
        nodes[index]
    }
}
