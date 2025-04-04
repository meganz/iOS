import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import MEGASwift
import XCTest

final class NodeRepositoryTests: XCTestCase {
    class Harness {
        let sharedFolderSdk = MockSdk()
        let sdk: MockSdk
        let sut: NodeRepository
        
        init (
            megaRootNode: MEGANode = .rootNode,
            nodes: [MEGANode] = [],
            isNodeInheritingSensitivity: Bool = false
        ) {
            
            sdk = MockSdk(megaRootNode: megaRootNode,
                          isNodeInheritingSensitivity: isNodeInheritingSensitivity)
            
            sut = NodeRepository(
                sdk: sdk,
                sharedFolderSdk: sharedFolderSdk,
                nodeUpdatesProvider: MockNodeUpdatesProvider()
            )
            sdk.setNodes(nodes)
        }
    }
    
    let defaultHandle: UInt64 = 123
    let invalidHandle: UInt64 = 999
    let defaultNodeName = "testNode"
    
    // MARK: - Helper functions
    private func defaultNode(parentHandle: MEGAHandle? = nil) -> MockNode {
        MockNode(
            handle: defaultHandle,
            name: defaultNodeName,
            parentHandle: parentHandle ?? defaultParentNode().handle
        )
    }
    
    private func defaultParentNode() -> MockNode {
        MockNode(
            handle: 1,
            name: "parent",
            nodeType: .folder
        )
    }
    
    private func parentNodeAndChildren(childrenType: MEGANodeType = .file) -> [MockNode] {
        let parentNode = defaultParentNode()
        let childrenNodes = children(of: parentNode.handle, type: childrenType)
        
        return [parentNode] + childrenNodes
    }
    
    private func children(of parent: MEGAHandle, type: MEGANodeType = .file) -> [MockNode] {
        let childNode1 = MockNode(handle: 2, name: "child1", nodeType: type, parentHandle: parent)
        let childNode2 = MockNode(handle: 3, name: "child2", nodeType: type, parentHandle: parent)
        
        return [childNode1, childNode2]
    }
    
    private func defaultLink() throws -> URL {
        try XCTUnwrap(URL(string: "http://example.com"), "URL should be correctly formed and not nil.")
    }
    
    private func makeSUT(
        fileLinkNode: MockNode? = nil,
        error: MEGAErrorType = .apiOk,
        sdkNodes: [MockNode] = [],
        sharedFolderNodes: [MockNode] = [],
        rubbishBinNodes: [MockNode] = [],
        rubbishBinNode: MockNode? = nil,
        rootNode: MockNode? = nil,
        createdFolderHandle: MEGAHandle? = nil,
        isNodeInheritingSensitivity: Bool = false,
        accessLevel: MEGAShareType = .accessOwner,
        nodeUpdatesProvider: some NodeUpdatesProviderProtocol = MockNodeUpdatesProvider()
    ) -> NodeRepository {
        
        let mockSdk = MockSdk(
            fileLinkNode: fileLinkNode,
            nodes: sdkNodes,
            rubbishNodes: rubbishBinNodes,
            megaRootNode: rootNode,
            rubbishBinNode: rubbishBinNode,
            megaSetError: error,
            isNodeInheritingSensitivity: isNodeInheritingSensitivity,
            createdFolderHandle: createdFolderHandle,
            shareAccessLevel: accessLevel
        )
        let mockSharedFolderSdk = MockSdk(nodes: sharedFolderNodes)
        
        let sut = NodeRepository(
            sdk: mockSdk,
            sharedFolderSdk: mockSharedFolderSdk,
            nodeUpdatesProvider: nodeUpdatesProvider
        )
        
        return sut
    }
    
    private func assertNodeForHandleReturnsCorrectResult(sut: NodeRepository, expectedNode: MockNode) throws {
        let result = try XCTUnwrap(sut.nodeForHandle(expectedNode.handle), "Expected non-nil result for node handle \(expectedNode.handle)")
        
        XCTAssertEqual(
            result.handle,
            expectedNode.handle,
            "Expected handle to match for node \(String(describing: expectedNode.name))"
        )
        XCTAssertEqual(
            result.name,
            expectedNode.name,
            "Expected node name to match for node \(String(describing: expectedNode.name))"
        )
    }
    
    private func executeNodeForFileLinkTest(
        link: URL,
        megaErrorType: MEGAErrorType,
        expectedErrorEntity: NodeErrorEntity,
        expectationDescription: String
    ) async {
        let sut = makeSUT(error: megaErrorType)
        
        do {
            let node = try await sut.nodeFor(fileLink: FileLinkEntity(linkURL: link))
            XCTFail("Expected failure with error \(expectedErrorEntity), but received success with node: \(node)")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(
                error,
                expectedErrorEntity,
                "Expected error '\(expectedErrorEntity)' but received \(error)"
            )
        } catch {
            XCTFail("Expected failure with NodeErrorEntity, but found: \(error)")
        }
    }
    
    private typealias NodeRetrievalClosure = () -> NodeEntity?
    
    private func testTheExistenceOfANodeOfType(
        nodeName: String,
        expectedNode: MockNode? = nil,
        retrieveNode: NodeRetrievalClosure,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
       let result = retrieveNode()
       if let expectedNode {
           XCTAssertNotNil(result, "Expected \(nodeName) to be not nil", file: file, line: line)
           XCTAssertEqual(result?.handle, expectedNode.handle, "Expected handles to match for \(nodeName)", file: file, line: line)
       } else {
           XCTAssertNil(result, "Expected \(nodeName) to be nil", file: file, line: line)
       }
   }
    
    // MARK: - Node for handle
    func testNodeForHandle_nodeExistsInSDK_returnsNodeEntity() throws {
        let expectedNode = defaultNode()
        let sut = makeSUT(sdkNodes: [expectedNode])
        
        try assertNodeForHandleReturnsCorrectResult(
            sut: sut,
            expectedNode: expectedNode
        )
    }

    func testNodeForHandle_nodeExistsInSharedFolderSDK_returnsNodeEntity() throws {
        let expectedNode = defaultNode()
        let sut = makeSUT(sharedFolderNodes: [expectedNode])

        try assertNodeForHandleReturnsCorrectResult(
            sut: sut,
            expectedNode: expectedNode
        )
    }

    func testNodeForHandle_nodeNotFoundInSDK_returnsNil() {
        let sut = makeSUT()

        let result = sut.nodeForHandle(invalidHandle)

        XCTAssertNil(result)
    }
    
    // MARK: - Node for file Link
    func testNodeForFileLink_validLink_completesWithNode() async {
        do {
            let link = try defaultLink()
            let expectedNode = defaultNode()
            let sut = makeSUT(fileLinkNode: expectedNode)
            let fileLink = FileLinkEntity(linkURL: link)
            
            let node = try await sut.nodeFor(fileLink: fileLink)
            XCTAssertEqual(node.handle, expectedNode.handle, "Node handle should match the expected handle.")
            XCTAssertEqual(node.name, expectedNode.name, "Node name should match the expected name.")
        } catch {
            XCTFail("Expected success with a node, but received failure with error: \(error)")
        }
    }

    func testNodeForFileLink_invalidLink_completesWithFailure() async throws {
        let link = try defaultLink()
        
        await executeNodeForFileLinkTest(
            link: link,
            megaErrorType: .apiENoent,
            expectedErrorEntity: .nodeNotFound,
            expectationDescription: "Node fetch for invalid file link should complete with failure."
        )
    }
    
    func testNodeForFileLink_validLinkMissingNode_completesWithFailure() async throws {
        let link = try defaultLink()
        
        await executeNodeForFileLinkTest(
            link: link,
            megaErrorType: .apiOk,
            expectedErrorEntity: .nodeNotFound,
            expectationDescription: "Node fetch for invalid file link should complete with failure."
        )
    }
    
    func testNodeForFileLinkAsync_validLink_returnsNodeEntity() async throws {
        let link = try defaultLink()
        let expectedNode = defaultNode()
        let sut = makeSUT(fileLinkNode: expectedNode)
        
        do {
            let node = try await sut.nodeFor(fileLink: FileLinkEntity(linkURL: link))
            XCTAssertEqual(node.handle, expectedNode.handle)
            XCTAssertEqual(node.name, expectedNode.name)
        } catch {
            XCTFail("Expected success but received error: \(error)")
        }
    }

    func testNodeForFileLinkAsync_invalidLink_throwsNodeNotFoundError() async throws {
        let link = try defaultLink()
        let sut = makeSUT()

        do {
            _ = try await sut.nodeFor(fileLink: FileLinkEntity(linkURL: link))
            XCTFail("Expected error but received success")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(error, .nodeNotFound)
        } catch {
            XCTFail("Received unexpected error type")
        }
    }
    
    // MARK: - Child Node Named
    func testChildNodeNamed_nodeFound_returnsNodeEntity() {
        let parentNode = MockNode(handle: 1)
        let childNode = MockNode(handle: 2, name: "child", parentHandle: parentNode.handle)
        let sut = makeSUT(sdkNodes: [parentNode, childNode])

        let result = sut.childNodeNamed(name: childNode.name, in: parentNode.handle)

        XCTAssertNotNil(result, "Expected to find a child node named '\(String(describing: childNode.name))' under parent handle \(parentNode.handle), but found none.")
        XCTAssertEqual(result?.handle, childNode.handle, "Expected child node handle to be \(childNode.handle), but found \(String(describing: result?.handle)).")
    }

    func testChildNodeNamed_noParentNode_returnsNil() {
        let childNode = MockNode(handle: 2, name: "child")
        let sut = makeSUT(sdkNodes: [childNode])

        let result = sut.childNodeNamed(name: childNode.name, in: 1)

        XCTAssertNil(result, "Expected not to find a child node named '\(String(describing: childNode.name))' under a non-existent parent, but a node was found.")
    }

    func testChildNodeNamed_noChildNode_returnsNil() {
        let parentNode = MockNode(handle: 1)
        let sut = makeSUT(sdkNodes: [parentNode])

        let result = sut.childNodeNamed(name: parentNode.name, in: parentNode.handle)

        XCTAssertNil(result, "Expected not to find a child node named '\(String(describing: parentNode.name))' under its own handle, but a node was found.")
    }
    
    // MARK: - Child node for parent
    func testChildNode_found_returnsNodeEntity() async {
        let parentNode = MockNode(handle: 1)
        let childNode = MockNode(handle: 2, name: "child", nodeType: .file, parentHandle: parentNode.handle)
        let sut = makeSUT(sdkNodes: [parentNode, childNode])

        let result = await sut.childNode(parent: parentNode.toNodeEntity(), name: childNode.name, type: .file)

        XCTAssertNotNil(result, "Expected to find a child node named '\(String(describing: childNode.name))', but found none.")
        XCTAssertEqual(result?.handle, childNode.handle, "Expected child node handle to be \(childNode.handle), but found \(String(describing: result?.handle)).")
    }

    func testChildNode_noParent_returnsNil() async {
        let parentNode = MockNode(handle: 1)
        let childNode = MockNode(handle: 2, name: "child", nodeType: .file)
        let sut = makeSUT(sdkNodes: [childNode])

        let result = await sut.childNode(parent: parentNode.toNodeEntity(), name: childNode.name, type: .folder)

        XCTAssertNil(result, "Expected not to find a child node named '\(String(describing: childNode.name))' under a non-existent parent, but a node was found.")
    }

    func testChildNode_noChildNode_returnsNil() async {
        let parentNode = MockNode(handle: 1)
        let sut = makeSUT(sdkNodes: [parentNode])
        
        let result = await sut.childNode(parent: parentNode.toNodeEntity(), name: "childNode", type: .file)
        
        XCTAssertNil(result, "Expected not to find a child node named 'childNode' under parent handle \(parentNode.handle), but a node was found.")
    }
    
    // MARK: - Rubbish bin node
    func testRubbishNode_whenExists_returnsNodeEntity() {
        let expectedNode = MockNode(
            handle: 1,
            name: "Rubbish Bin",
            nodeType: .rubbish
        )
        
        let sut = makeSUT(rubbishBinNode: expectedNode)
        
        testTheExistenceOfANodeOfType(
            nodeName: expectedNode.name,
            expectedNode: expectedNode,
            retrieveNode: sut.rubbishNode
        )
    }

    func testRubbishNode_whenMissing_returnsNil() {
        let sut = makeSUT()
        
        testTheExistenceOfANodeOfType(
            nodeName: "Rubbish Bin",
            retrieveNode: sut.rubbishNode
        )
    }

    // MARK: - Root node
    func testRootNode_exists_returnsNodeEntity() {
        let expectedNode = MockNode(
            handle: 1,
            name: "Root Node",
            nodeType: .folder
        )
        let sut = makeSUT(rootNode: expectedNode)

        testTheExistenceOfANodeOfType(
            nodeName: expectedNode.name,
            expectedNode: expectedNode,
            retrieveNode: sut.rootNode
        )
    }

    func testRootNode_notExists_returnsNil() {
        let sut = makeSUT()
        
        testTheExistenceOfANodeOfType(
            nodeName: "Root Node",
            retrieveNode: sut.rootNode
        )
    }
    
    // MARK: - Parents of node
    func testParentsOfNode_inTheRootDirectory_returnsRootNode() async throws {
        let parent = defaultParentNode()
        let children = children(of: parent.handle)
        let sut = makeSUT(sdkNodes: [parent] + children)
        let child1 = try XCTUnwrap(children.first)
        
        let parents = await sut.parents(of: child1.toNodeEntity())

        XCTAssertEqual(parents.count, 1, "Should find one parent node.")
        XCTAssertEqual(parents.first?.name, parent.name, "Parent node should be '\(String(describing: parent.name))'.")
    }
    
    func testParentsOfNode_forANodeBelongingToASubfolder_returnsTheEntireParentsTree() async throws {
        let rootNode = MockNode(handle: 1000, name: "Root", nodeType: .folder)
        let grandParent = MockNode(handle: 1001, name: "parent", nodeType: .folder, parentHandle: rootNode.handle)
        let parent = MockNode(handle: 1002, name: "parent2", nodeType: .folder, parentHandle: grandParent.handle)
        let children = children(of: parent.handle)
        let child1 = try XCTUnwrap(children.first)
        let sut = makeSUT(
            sdkNodes: [rootNode, grandParent, parent] + children,
            rootNode: rootNode
        )
        
        let parents = await sut.parents(of: child1.toNodeEntity())
        
        let parentNames = parents.map(\.name)

        XCTAssertEqual(parents.count, 2, "Should find one parent node.")
        XCTAssertEqual(parentNames, [grandParent.name, parent.name], "Parent names should be \(String(describing: grandParent.name)), '\(String(describing: parent.name))'.")
    }
    
    func testParentsOfNode_inRubbishBin_returnsRubbishAndRootNode() async throws {
        let rubbishBinNode = MockNode(handle: 100, name: "Rubbish Bin", nodeType: .folder, nodePath: "//bin")
        let rubbishBinChild = MockNode(handle: 101, name: "child1", parentHandle: rubbishBinNode.handle, nodePath: "//bin/child1")
        
        let sut = makeSUT(sdkNodes: [rubbishBinNode, rubbishBinChild])
        
        let parents = await sut.parents(of: rubbishBinChild.toNodeEntity())
        XCTAssertEqual(parents.count, 1, "Should find one parent node.")
        XCTAssertEqual(parents.first?.name, rubbishBinNode.name, "Parent node should be '\(String(describing: rubbishBinNode.name))'.")
    }
    
    func testParentsOfNode_whenTheNodeIsNotOurs_returnsRootNode() async throws {
        let parent = defaultParentNode()
        let children = children(of: parent.handle)
        let sut = makeSUT(
            sdkNodes: [parent] + children,
            accessLevel: .accessRead
        )
        let child1 = try XCTUnwrap(children.first)

        let parents = await sut.parents(of: child1.toNodeEntity())

        XCTAssertEqual(parents.count, 1, "Should find one parent node for the non-owner node.")
        XCTAssertEqual(parents.first?.name, parent.name, "Parent node should be '\(String(describing: parent.name))' for the non-owner node.")
    }
    
    func testParentsOfNode_whenChildNodeNotFound_returnsEmptyParentsArray() async throws {
        // Owned Node
        let node = MockNode(handle: 1, name: "Node 1", nodeType: .folder)
        let sut = makeSUT()
        
        let parents = await sut.parents(of: node.toNodeEntity())
        XCTAssertTrue(parents.isEmpty, "The parents array should be empty when the child node is owned but not found in the SDK.")
        
        // Not owned node
        let sut2 = makeSUT(accessLevel: .accessRead)
        
        let parents2 = await sut2.parents(of: node.toNodeEntity())
        XCTAssertTrue(parents2.isEmpty, "The parents array should still be empty when the node is not owned and not found in the SDK.")
    }
    
    func testParentsOfNode_whenNodeIsNotOursDoesNotHaveParentsAndIsAFile_returnsEmptyArray() async {
        let node = MockNode(handle: 1, name: "Node 1", nodeType: .file)
        let sut = makeSUT(
            sdkNodes: [node],
            accessLevel: .accessRead)
        
        let parents = await sut.parents(of: node.toNodeEntity())
        XCTAssertTrue(parents.isEmpty, "The parents array should be empty if the node has no accessible parents due to restricted access.")
    }
    
    func testParentsOfNode_whenNodeIsNotOursDoesNotHaveParentsAndIsAFolder_returnsOneParent() async {
        let node = MockNode(handle: 1, name: "Node 1", nodeType: .folder)
        let sut = makeSUT(
            sdkNodes: [node],
            accessLevel: .accessRead)
        
        let parents = await sut.parents(of: node.toNodeEntity())
        XCTAssertEqual(parents.count, 1, "The parents array should include the folder intself.")
    }
    
    func testParentsOfNode_whenNodeIsAFolder_includesItselfInParentList() async throws {
        let parentNode = defaultParentNode()
        let sut = makeSUT(sdkNodes: [parentNode])

        let parents = await sut.parents(of: parentNode.toNodeEntity())

        XCTAssertEqual(parents.count, 1, "Should include the folder itself in the parent list.")
        XCTAssertEqual(parents.first?.name, parentNode.name, "The list should include '\(String(describing: parentNode.name))'.")
    }
    
    func testParentsOfFileNode_whenNodeIsAFile_doesNotIncludeItselfInParentList() async throws {
        let parentNode = defaultParentNode()
        let children = children(of: parentNode.handle, type: .file)
        let sut = makeSUT(sdkNodes: [parentNode] + children)
        let child1 = try XCTUnwrap(children.first)

        let parents = await sut.parents(of: child1.toNodeEntity())

        XCTAssertEqual(parents.count, 1, "Should not include the folder itself in the parent list.")
        XCTAssertEqual(parents.first?.name, parentNode.name, "The list should include the parent name: '\(String(describing: parentNode.name))'.")
    }
    
    func testParentsOfNode_folderAndFile_returnsCorrectParentCounts() async throws {
        let parentNode = defaultParentNode()
        let childFolders = [MockNode(handle: 2, name: "child1", nodeType: .folder, parentHandle: parentNode.handle)]
        let childFiles = [MockNode(handle: 3, name: "child1", nodeType: .file, parentHandle: parentNode.handle)]
        
        let sutOwner = makeSUT(sdkNodes: [parentNode] + childFolders + childFiles, accessLevel: .accessOwner)
        let sutReadAccess = makeSUT(sdkNodes: [parentNode] + childFolders + childFiles, accessLevel: .accessRead)
        let firstChildFolder = try XCTUnwrap(childFolders.first)
        let firstChildFile = try XCTUnwrap(childFiles.first)
        
        // Folders
        let ownerAccessFolderParents = await sutOwner.parents(of: firstChildFolder.toNodeEntity())
        XCTAssertEqual(ownerAccessFolderParents.map(\.handle), [1, 2], "Should include the folder itself in the parent list.")
        
        let readAccessFolderParents = await sutReadAccess.parents(of: firstChildFolder.toNodeEntity())
        XCTAssertEqual(readAccessFolderParents.map(\.handle), [1, 2], "Should include the folder itself in the parent list.")
        
        // Files
        let ownerAccessFileParents = await sutOwner.parents(of: firstChildFile.toNodeEntity())
        XCTAssertEqual(ownerAccessFileParents.map(\.handle), [1], "Should not include the folder itself in the parent list.")
        
        let readAccessFileParents = await sutReadAccess.parents(of: firstChildFile.toNodeEntity())
        XCTAssertEqual(readAccessFileParents.map(\.handle), [1], "Should not include the folder itself in the parent list.")
    }
    
    // MARK: - Children of node
    func testChildrenOfNode_returnsChildren() throws {
        let nodes = parentNodeAndChildren()
        let sut = makeSUT(sdkNodes: nodes)
        
        let result = try XCTUnwrap(sut.children(of: defaultParentNode().toNodeEntity()))
        let nodesResult = result.toNodeEntities()

        XCTAssertEqual(nodesResult.count, 2, "Expected 2 children under the parent node, but found \(nodesResult.count).")
        XCTAssertTrue(nodesResult.map { $0.name }.contains("child1"), "Expected to find a child named 'child1', but it's missing.")
        XCTAssertTrue(nodesResult.map { $0.name }.contains("child2"), "Expected to find a child named 'child2', but it's missing.")
    }
    
    func testChildrenOfNode_returnsNil() {
        let sut = makeSUT()
        
        let result = sut.children(of: defaultParentNode().toNodeEntity())

        XCTAssertNil(result, "Expected not to find any children for the parent node, but some were found.")
    }
    
    // MARK: - Async children of node
    func testAsyncChildrenOfNode_returnsSortedChildren() async {
        let nodes = parentNodeAndChildren()
        let sut = makeSUT(sdkNodes: nodes)

        let result = await sut.asyncChildren(of: defaultParentNode().toNodeEntity(), sortOrder: .defaultAsc)
        
        let resultNodeNames = result?.toNodeEntities().map(\.name)
        
        XCTAssertEqual(resultNodeNames, ["child1", "child2"], "The children nodes should be returned sorted alphabetically by their names in ascending order.")
    }
    
    func testAsyncChildrenOfNode_returnsNil() async {
        let sut = makeSUT()
        let result = await sut.asyncChildren(of: MockNode(handle: .invalid).toNodeEntity(), sortOrder: .defaultAsc)
        
        XCTAssertNil(result, "Expected not to find any children for the parent node, but some were found.")
    }
    
    // MARK: - Children names of node
    func testChildrenNamesOfNode_returnsNames() {
        let nodes = parentNodeAndChildren()
        let sut = makeSUT(sdkNodes: nodes)
        
        let resultNames = sut.childrenNames(of: defaultParentNode().toNodeEntity())
        
        XCTAssertEqual(resultNames, ["child1", "child2"], "The childrenNames(of:) function should accurately return the names of all child nodes.")
    }
    
    func testChildrenNamesOfNode_returnsNil() {
        let sut = makeSUT()
        
        let resultNames = sut.childrenNames(of: MockNode(handle: .invalid).toNodeEntity())
        
        XCTAssertNil(resultNames, "Expected not to find any children names for the parent node, but some were found.")
    }
    
    // MARK: - Is in rubbish bin
    func testIsInRubbishBin_nodeInRubbish_returnsTrue() {
        let rubbishBinNode = MockNode(handle: 1, name: "Rubbish Bin", nodeType: .folder)
        let rubbishBinChild1 = MockNode(handle: 2, name: "Rubbish Bin Child 1", nodeType: .file, parentHandle: rubbishBinNode.handle)
        let sut = makeSUT(
            sdkNodes: [rubbishBinNode, rubbishBinChild1],
            rubbishBinNodes: [rubbishBinChild1],
            rubbishBinNode: rubbishBinNode
        )

        let isInRubbish = sut.isInRubbishBin(node: rubbishBinChild1.toNodeEntity())

        XCTAssertTrue(isInRubbish, "The node should be identified as being in the rubbish bin.")
    }

    func testIsInRubbishBin_nodeNotInRubbish_returnsFalse() {
        let sut = makeSUT()
        let isInRubbish = sut.isInRubbishBin(node: defaultNode().toNodeEntity())

        XCTAssertFalse(isInRubbish, "The node should not be identified as being in the rubbish bin.")
    }
    
    // MARK: - Create folder
    func testCreateFolder_validParameters_createsFolderSuccessfully() async throws {
        let nodes = parentNodeAndChildren()
        let folderName = "New Folder"
        let folderHandle: MEGAHandle = 200
        let sut = makeSUT(
            sdkNodes: nodes + [MockNode(handle: folderHandle, name: folderName, parentHandle: defaultParentNode().handle)],
            createdFolderHandle: folderHandle
        )

        do {
            let createdNode = try await sut.createFolder(with: folderName, in: defaultParentNode().toNodeEntity())
            XCTAssertEqual(createdNode.name, folderName, "The created folder should have the specified name.")
        } catch {
            XCTFail("Folder creation should not fail.")
        }
    }
    
    func testCreateFolder_onApiError_creationFails() async throws {
        let nodes = parentNodeAndChildren()
        let folderName = "New Folder"
        let folderHandle: MEGAHandle = 200
        let sut = makeSUT(
            error: .apiEBusinessPastDue,
            sdkNodes: nodes + [MockNode(handle: folderHandle, name: folderName, parentHandle: defaultParentNode().handle)],
            createdFolderHandle: folderHandle
        )

        do {
            _ = try await sut.createFolder(with: folderName, in: defaultParentNode().toNodeEntity())
            XCTFail("Expected an error if the creation of the folder fails.")
        } catch let error as NodeCreationErrorEntity {
            XCTAssertEqual(error, .nodeCreationFailed, "Should throw 'nodeCreationFailed' when the creation of the folder fails.")
        } catch {
            XCTFail("Received unexpected error type")
        }
    }
    
    func testCreateFolder_nodeSuccessfullyCreatedButNotReturnedByTheSDK_shouldFail() async {
        let nodes = parentNodeAndChildren()
        let folderName = "New Folder"
        let sut = makeSUT(
            sdkNodes: nodes + [MockNode(handle: 200, name: folderName, parentHandle: defaultParentNode().handle)]
        )

        do {
            _ = try await sut.createFolder(with: folderName, in: defaultParentNode().toNodeEntity())
            XCTFail("Expected an error if the creation of the folder fails.")
        } catch let error as NodeCreationErrorEntity {
            XCTAssertEqual(error, .nodeCreatedButCannotBeSearched, "Should throw 'nodeCreatedButCannotBeSearched' when the creation of the folder fails.")
        } catch {
            XCTFail("Received unexpected error type")
        }
    }

    func testCreateFolder_nodeAlreadyExists_shouldFail() async {
        let nodes = parentNodeAndChildren(childrenType: .folder)
        let folderName = "child1"
        let sut = makeSUT(sdkNodes: nodes)

        do {
            _ = try await sut.createFolder(with: folderName, in: defaultParentNode().toNodeEntity())
            XCTFail("Expected an error for a node that already exists, but succeeded.")
        } catch let error as NodeCreationErrorEntity {
            XCTAssertEqual(error, .nodeAlreadyExists, "Should throw 'nodeAlreadyExists' when a node with the same name exists.")
        } catch {
            XCTFail("Received unexpected error type")
        }
    }

    func testCreateFolder_parentNodeNotFound_shouldFail() async {
        let sut = makeSUT()

        do {
            _ = try await sut.createFolder(with: "child1", in: defaultParentNode().toNodeEntity())
            XCTFail("Expected an error for a non-existent parent node, but succeeded.")
        } catch let error as NodeCreationErrorEntity {
            XCTAssertEqual(error, .nodeNotFound, "Should throw 'nodeNotFound' when the parent node does not exist.")
        } catch {
            XCTFail("Received unexpected error type")
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
            type: nodeType.toNodeTypeEntity()
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
        let result = await harness.sut.asyncChildren(of: root.toNodeEntity(), sortOrder: .defaultAsc)
        XCTAssertEqual(result?.nodesCount ?? 0, 0)
    }
    
    func testChildrenOfParent_returnChildrenArray_whenNoChildrenFound() async {
        let root = MockNode(handle: 1, nodeType: .folder)
        let child0 = MockNode(handle: 2, nodeType: .file, parentHandle: 1)
        let child1 = MockNode(handle: 3, nodeType: .file, parentHandle: 1)
        let child2 = MockNode(handle: 4, nodeType: .folder, parentHandle: 1)
        let grandChild = MockNode(handle: 5, nodeType: .file, parentHandle: 4)
        
        let children = [child0, child1, child2]
        let harness = Harness(nodes: [root] + children + [grandChild])
        let result = await harness.sut.asyncChildren(of: root.toNodeEntity(), sortOrder: .defaultAsc)
        let resultNodes = [result?.nodeAt(0), result?.nodeAt(1), result?.nodeAt(2)]
        XCTAssertEqual(resultNodes, children.toNodeEntities())
    }
    
    // MARK: - Is inheriting sensitivity
    func testIsInheritingSensitivity_parentNodeNotFound_shouldThrowNodeNotFoundError() async {
        let harness = Harness()
        
        do {
            let node = NodeEntity(handle: 5)
            _ = try await harness.sut.isInheritingSensitivity(node: node)
            XCTFail("Should have caught error")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(error, NodeErrorEntity.nodeNotFound)
        } catch {
            XCTFail("Caught incorrect error")
        }
    }
    
    func testIsInheritingSensitivity_nodeFound_shouldReturn() async throws {
        let isNodeInheritingSensitivity = true
        let node = defaultNode()
        let harness = Harness(nodes: [node, defaultParentNode()],
                              isNodeInheritingSensitivity: isNodeInheritingSensitivity)
        
        let isSensitive = try await harness.sut.isInheritingSensitivity(node: node.toNodeEntity())
        XCTAssertEqual(isSensitive, isNodeInheritingSensitivity)
    }
    
    func testIsInheritingSensitivity_nodeFound_inheritsSettings() async throws {
        let node = defaultNode()
        let sut = makeSUT(
            sdkNodes: [node, defaultParentNode()],
            isNodeInheritingSensitivity: true
        )
        
        do {
            let isSensitive = try await sut.isInheritingSensitivity(node: defaultNode().toNodeEntity())
            
            XCTAssertTrue(isSensitive, "The node should be inheriting sensitivity settings.")
        } catch {
            XCTFail("Node sensitivity check should not fail.")
        }
    }

    func testIsInheritingSensitivity_nodeFound_doesNotInheritSettings() async throws {
        let node = defaultNode()
        let sut = makeSUT(
            sdkNodes: [node, defaultParentNode()],
            isNodeInheritingSensitivity: false
        )
        
        do {
            let isSensitive = try await sut.isInheritingSensitivity(node: node.toNodeEntity())
            XCTAssertFalse(isSensitive, "The node should not be inheriting sensitivity settings.")
        } catch {
            XCTFail("Node sensitivity check should not fail.")
        }
    }

    func testIsInheritingSensitivity_nodeNotFound_throwsError() async throws {
        let node = defaultNode()
        let sut = makeSUT(isNodeInheritingSensitivity: true)
        
        do {
            _ = try await sut.isInheritingSensitivity(node: node.toNodeEntity())
            XCTFail("Expected an error for a non-existent node, but succeeded.")
        } catch let error as NodeErrorEntity {
            XCTAssertEqual(error, .nodeNotFound, "Should throw 'nodeNotFound' when the node does not exist.")
        }
    }
    
    func testNodeUpdates_onProviderUpdates_shouldYieldValues() async {
        let updates = [NodeEntity(handle: 1),
                       NodeEntity(handle: 2)]
                       
        let updateSequence = SingleItemAsyncSequence(item: updates)
            .eraseToAnyAsyncSequence()
        let sut = makeSUT(nodeUpdatesProvider: MockNodeUpdatesProvider(nodeUpdates: updateSequence))
        
        var iterator = sut.nodeUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        
        XCTAssertEqual(result, updates)
    }
}

fileprivate extension MEGANode {
    static let rootNode = MockNode(handle: 1, nodeType: .folder)
}
