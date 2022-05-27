import XCTest
@testable import MEGA

final class NodeHandle_Additions_Tests: XCTestCase {
    
    func testValidNode_notFound() {
        XCTAssertNil(NodeHandle(1).validNode(in: MockSDK()), "valid node should not be found")
    }
    
    func testValidNode_nodeInRubbishBin() {
        let rubbinBinNode = MockNode(handle: 1, inRubbishBin: true)
        let sdk = MockSDK(withNodes: [rubbinBinNode])
        XCTAssertNil(NodeHandle(1).validNode(in: sdk), "valid node should not be found")
    }
    
    func testValidNode_vaildNode() {
        let node = MockNode(handle: 1)
        let sdk = MockSDK(withNodes: [node])
        XCTAssert(NodeHandle(1).validNode(in: sdk) == node, "valid node should be found")
    }
}

final fileprivate class MockNode: MEGANode {
    let _handle: MEGAHandle
    let inRubbishBin: Bool

    init(handle: MEGAHandle = 0, inRubbishBin: Bool = false) {
        _handle = handle
        self.inRubbishBin = inRubbishBin
        super.init()
    }
}

final fileprivate class MockSDK: MEGASdk {
    private let nodes: [MockNode]
    
    init(withNodes nodes: [MockNode] = []) {
        self.nodes = nodes
        super.init()
    }
    
    override func node(forHandle handle: MEGAHandle) -> MEGANode? {
        nodes.filter({ $0._handle == handle }).first
    }
    
    override func isNode(inRubbish node: MEGANode) -> Bool {
        guard let mockNode = node as? MockNode else { return false }
        return mockNode.inRubbishBin
    }
}
