import XCTest
@testable import MEGA
import MEGADomain

final class NodeRepositoryTests: XCTestCase {

    func test_isNode_desdendantOf_ancestor() {
        let grandParentNode = MockNode(handle: 1)
        let parentNode = MockNode(handle: 2, parentHandle: 1)
        let childNode = MockNode(handle: 3, parentHandle: 2)
        
        let sdk = MockSdk(nodes: [grandParentNode, parentNode, childNode])
        let repo = NodeRepository(sdk: sdk, sharedFolderSdk: MockFolderSdk(), chatSdk: MockChatSDK())
        
        XCTAssertTrue(repo.isNode(childNode.toNodeEntity(), descendantOf: grandParentNode.toNodeEntity()))
        XCTAssertTrue(repo.isNode(childNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity()))
        XCTAssertFalse(repo.isNode(parentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity()))
        XCTAssertFalse(repo.isNode(grandParentNode.toNodeEntity(), descendantOf: parentNode.toNodeEntity()))
        XCTAssertFalse(repo.isNode(grandParentNode.toNodeEntity(), descendantOf: childNode.toNodeEntity()))
    }
}
