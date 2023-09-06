@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

fileprivate extension MEGANode {
    static let rootNode = MockNode(handle: 1, nodeType: .folder)
}

final class NodeRepositoryTests: XCTestCase {
    class Harness {
        let sharedFolderSdk = MockSdk()
        let sdk: MockSdk
        let sut: NodeRepository
        
        init (
            megaRootNode: MEGANode = .rootNode,
            nodes: [MEGANode] = []
        ) {
            
            sdk = MockSdk(megaRootNode: megaRootNode)
            
            sut = NodeRepository(
                sdk: sdk,
                sharedFolderSdk: sharedFolderSdk,
                chatSdk: MockChatSDK()
            )
            sdk.setNodes(nodes)
        }
    }
    
    func testParentTreeArray_severalFolderLevels() async {
        let grandParentNode = MockNode(handle: 2, nodeType: .folder, parentHandle: 1)
        let parentNode = MockNode(handle: 3, nodeType: .folder, parentHandle: 2)
        let childNode = MockNode(handle: 4, nodeType: .file, parentHandle: 3)
        
        let harness = Harness(nodes: [.rootNode, grandParentNode, parentNode, childNode])
        harness.sdk.setShareAccessLevel(.accessOwner)
        
        let childNodeParentTreeArray = await harness.sut.parents(of: childNode.toNodeEntity())
        XCTAssertEqual(childNodeParentTreeArray, [grandParentNode, parentNode].toNodeEntities())
        
        let parentNodeParentTreeArray = await harness.sut.parents(of: parentNode.toNodeEntity())
        XCTAssertEqual(parentNodeParentTreeArray, [grandParentNode, parentNode].toNodeEntities())
        
        let grandParentNodeParentTreeArray = await harness.sut.parents(of: grandParentNode.toNodeEntity())
        XCTAssertEqual(grandParentNodeParentTreeArray, [grandParentNode.toNodeEntity()])
    }
    
    func testParentTreeArray_rootNodeChild_file() async {
        let rootNodeChild = MockNode(handle: 5, nodeType: .file, parentHandle: 1)
        let harness = Harness(nodes: [.rootNode, rootNodeChild])
        harness.sdk.setShareAccessLevel(.accessOwner)
        
        let rootNodeParentTreeArray = await harness.sut.parents(of: rootNodeChild.toNodeEntity())
        XCTAssertTrue(rootNodeParentTreeArray.isEmpty)
    }
    
    func testChildNode_parentNotFound_shouldReturnNil() async {
        let harness = Harness()
        let childNode = await harness.sut.childNode(
            parent: NodeEntity(handle: 4),
            name: "Test",
            type: .folder
        )
        
        XCTAssertNil(childNode)
    }
    
    func testChildNode_nodeFound_shouldReturnNode() async throws {
        let name = "Test"
        let nodeType = MEGANodeType.folder
        let expectedNode = MockNode(handle: 3, name: name, nodeType: nodeType)
        let parent = MockNode(handle: 86)
        let harness = Harness(nodes: [parent, expectedNode])
        
        let childNode = await harness.sut.childNode(
            parent: parent.toNodeEntity(),
            name: name,
            type: try XCTUnwrap(NodeTypeEntity(nodeType: nodeType))
        )
        
        XCTAssertEqual(childNode, expectedNode.toNodeEntity())
    }
    
    func testChildNode_nodeNotFound_shouldReturnNil() async {
        let parent = MockNode(handle: 86)
        let harness = Harness(nodes: [parent])
        
        let childNode = await harness.sut.childNode(
            parent: parent.toNodeEntity(),
            name: "Test",
            type: .folder
        )
        
        XCTAssertNil(childNode)
    }
    
    func testChildrenOfParent_returnEmptyArray_whenNoChildrenFound() async {
        let root = MockNode(handle: 1, nodeType: .folder)
        let harness = Harness(nodes: [root] )
        let result = await harness.sut.children(of: root.toNodeEntity())
        XCTAssertEqual(result, [])
    }
    
    func testChildrenOfParent_returnChildrenArray_whenNoChildrenFound() async {
        let root = MockNode(handle: 1, nodeType: .folder)
        let child0 = MockNode(handle: 2, nodeType: .file, parentHandle: 1)
        let child1 = MockNode(handle: 3, nodeType: .file, parentHandle: 1)
        let child2 = MockNode(handle: 4, nodeType: .folder, parentHandle: 1)
        let grandChild = MockNode(handle: 5, nodeType: .file, parentHandle: 4)
        
        let children = [child0, child1, child2]
        let harness = Harness(nodes: [root] + children + [grandChild])
        let result = await harness.sut.children(of: root.toNodeEntity())
        XCTAssertEqual(result, children.toNodeEntities())
    }
}
