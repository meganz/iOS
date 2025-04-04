@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeHandle_Additions_Tests: XCTestCase {
    
    func testValidNode_notFound() {
        XCTAssertNil(HandleEntity(1).validNode(in: MockSdk()), "valid node should not be found")
    }
    
    func testValidNode_nodeInRubbishBin() {
        let node = MockNode(handle: 1)
        let sdk = MockSdk(nodes: [node], rubbishNodes: [node])
        XCTAssertNil(HandleEntity(1).validNode(in: sdk), "valid node should not be found")
    }
    
    func testValidNode_vaildNode() {
        let node = MockNode(handle: 1)
        let sdk = MockSdk(nodes: [node])
        XCTAssert(HandleEntity(1).validNode(in: sdk) == node, "valid node should be found")
    }
}
