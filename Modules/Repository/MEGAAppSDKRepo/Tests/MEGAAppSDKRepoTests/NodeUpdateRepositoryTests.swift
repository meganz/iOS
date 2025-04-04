import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class NodeUpdateRepositoryTests: XCTestCase {
    func testShouldProcessOnNodesUpdate_onUpdateNodesParentHandleMatch_shouldReturnTrue() {
        let parentNode = NodeEntity(handle: 1)
        let updateNode = NodeEntity(handle: 2, parentHandle: parentNode.handle)
        let repository = NodeUpdateRepository(sdk: MockSdk())
        XCTAssertTrue(repository.shouldProcessOnNodesUpdate(parentNode: parentNode, childNodes: [], updatedNodes: [updateNode]))
    }
    
    func testShouldProcessOnNodesUpdate_onChildNodeMatchingUpdateNode_shouldReturnTrue() {
        let parentNode = NodeEntity(handle: 1)
        let updateNode = NodeEntity(handle: 2)
        
        let repository = NodeUpdateRepository(sdk: MockSdk())
        XCTAssertTrue(repository.shouldProcessOnNodesUpdate(parentNode: parentNode, childNodes: [updateNode], updatedNodes: [updateNode]))
    }
    
    func testShouldProcessOnNodesUpdate_onUpdateNodeMatchingBase64HandAndParentNodeHandle_shouldReturnTrue() {
        let parentNode = NodeEntity(handle: 1)
        let updateNode = NodeEntity(handle: 2, base64Handle: "A", restoreParentHandle: 4, parentHandle: 2)
        
        let repository = NodeUpdateRepository(sdk: MockSdk())
        XCTAssertTrue(repository.shouldProcessOnNodesUpdate(parentNode: parentNode, childNodes: [updateNode], updatedNodes: [updateNode]))
    }
    
    func testShouldProcessOnNodesUpdate_onUpdateNodeNotMatchingBase64Handle_shouldReturnFalse() {
        let repository = NodeUpdateRepository(sdk: MockSdk())
        let childNode = NodeEntity(base64Handle: "A")
        let updateNode = NodeEntity(base64Handle: "B")
        
        XCTAssertFalse(repository.shouldProcessOnNodesUpdate(parentNode: NodeEntity(handle: 1), childNodes: [childNode], updatedNodes: [updateNode]))
    }
}
