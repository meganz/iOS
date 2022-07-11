import XCTest
@testable import MEGA

final class NodeHandle_Additions_Tests: XCTestCase {
    
    func testValidNode_notFound() {
        XCTAssertNil(NodeHandle(1).validNode(in: MockSdk()), "valid node should not be found")
    }
    
    func testValidNode_nodeInRubbishBin() {
        let node = MockNode(handle: 1)
        let sdk = MockSdk(nodes: [node], rubbishNodes: [node])
        XCTAssertNil(NodeHandle(1).validNode(in: sdk), "valid node should not be found")
    }
    
    func testValidNode_vaildNode() {
        let node = MockNode(handle: 1)
        let sdk = MockSdk(nodes: [node])
        XCTAssert(NodeHandle(1).validNode(in: sdk) == node, "valid node should be found")
    }
}
