@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class NodeRepositoryTests: XCTestCase {
    let rootNode = MockNode(handle: 1, nodeType: .folder)
    var repository: NodeRepository!
    var sdk: MockSdk!
    
    override func setUp() {
        super.setUp()
        
        sdk = MockSdk(megaRootNode: rootNode)
        repository = NodeRepository(sdk: sdk, sharedFolderSdk: MockSdk(), chatSdk: MockChatSDK())
    }
    
    func testParentTreeArray_severalFolderLevels() async {
        let grandParentNode = MockNode(handle: 2, nodeType: .folder, parentHandle: 1)
        let parentNode = MockNode(handle: 3, nodeType: .folder, parentHandle: 2)
        let childNode = MockNode(handle: 4, nodeType: .file, parentHandle: 3)
    
        sdk.setNodes([rootNode, grandParentNode, parentNode, childNode])
        sdk.setShareAccessLevel(.accessOwner)
        
        let childNodeParentTreeArray = await repository?.parents(of: childNode.toNodeEntity())
        XCTAssertEqual(childNodeParentTreeArray, [grandParentNode, parentNode].toNodeEntities())
        
        let parentNodeParentTreeArray = await repository?.parents(of: parentNode.toNodeEntity())
        XCTAssertEqual(parentNodeParentTreeArray, [grandParentNode, parentNode].toNodeEntities())
        
        let grandParentNodeParentTreeArray = await repository?.parents(of: grandParentNode.toNodeEntity())
        XCTAssertEqual(grandParentNodeParentTreeArray, [grandParentNode.toNodeEntity()])
    }
    
    func testParentTreeArray_rootNodeChild_file() async {
        let rootNodeChild = MockNode(handle: 5, nodeType: .file, parentHandle: 1)
        
        sdk.setNodes([rootNode, rootNodeChild])
        sdk.setShareAccessLevel(.accessOwner)
        
        let rootNodeParentTreeArray = await repository?.parents(of: rootNodeChild.toNodeEntity())
        XCTAssertTrue(rootNodeParentTreeArray?.isEmpty ?? false)
    }
    
    func testChildNode_parentNotFound_shouldReturnNil() async {
        let sut = makeNodeRepository()
        
        let childNode = await sut.childNode(parent: NodeEntity(handle: 4),
                                            name: "Test", type: .folder)
        
        XCTAssertNil(childNode)
    }
    
    func testChildNode_nodeFound_shouldReturnNode() async throws {
        let name = "Test"
        let nodeType = MEGANodeType.folder
        let expectedNode = MockNode(handle: 3, name: name, nodeType: nodeType)
        let parent = MockNode(handle: 86)
        let sut = makeNodeRepository(sdk: MockSdk(nodes: [parent, expectedNode]))
        
        let childNode = await sut.childNode(parent: parent.toNodeEntity(),
                                            name: name,
                                            type: try XCTUnwrap(NodeTypeEntity(nodeType: nodeType)))
        
        XCTAssertEqual(childNode,
                       expectedNode.toNodeEntity())
    }
    
    func testChildNode_nodeNotFound_shouldReturnNil() async {
        let parent = MockNode(handle: 86)
        let sut = makeNodeRepository(sdk: MockSdk(nodes: [parent]))
        
        let childNode = await sut.childNode(parent: parent.toNodeEntity(),
                                            name: "Test",
                                            type: .folder)
        
        XCTAssertNil(childNode)
    }
    
    // MARK: - Private
    private func makeNodeRepository(sdk: MEGASdk = MockSdk(),
                                    sharedFolderSdk: MEGASdk = MockSdk(),
                                    chatSDk: MEGAChatSdk = MockChatSDK()
    ) -> NodeRepository {
        NodeRepository(sdk: sdk,
                       sharedFolderSdk: sharedFolderSdk,
                       chatSdk: chatSDk)
    }
}
