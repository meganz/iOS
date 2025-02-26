import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import XCTest

final class NodeUseCaseTests: XCTestCase {

    func testNodeAccessLevel_validHandle_returnsReadWriteAccess() {
        let sut = makeSUT(
            accessLevel: .readWrite
        )
        let accessLevel = sut.nodeAccessLevel(nodeHandle: HandleEntity())
        XCTAssertEqual(accessLevel, .readWrite)
    }

    func testNodeAccessLevelAsync_validHandle_returnsReadWriteAccess() async {
        let sut = makeSUT(
            accessLevel: .readWrite
        )
        let accessLevel = await sut.nodeAccessLevelAsync(nodeHandle: HandleEntity())
        XCTAssertEqual(accessLevel, .readWrite)
    }

    func testLabelString_validLabel_returnsExpectedString() {
        let sut = makeSUT(
            label: "Red"
        )
        let labelString = sut.labelString(label: .red)
        XCTAssertEqual(labelString, "Red")
    }

    func testGetFilesAndFolders_validHandle_returnsCorrectCounts() {
        let sut = makeSUT(
            filesAndFoldersCount: (10, 5)
        )
        
        let counts = sut.getFilesAndFolders(nodeHandle: HandleEntity())
        XCTAssertEqual(counts.childFileCount, 10)
        XCTAssertEqual(counts.childFolderCount, 5)
    }

    func testSizeForNode_validNode_returnsCorrectSize() {
        let expectedSize: UInt64 = 100
        let sut = makeSUT(
            size: expectedSize
        )
        
        let size = sut.sizeFor(node: NodeEntity(handle: HandleEntity()))
        XCTAssertEqual(size, expectedSize)
    }

    func testFolderInfo_validNode_returnsFolderInfo() async {
        let expectedFolderInfo =  FolderInfoEntity(
            versions: 2,
            files: 1,
            folders: 2,
            currentSize: 10,
            versionsSize: 10
        )
        let sut = makeSUT(
            folderInfo: expectedFolderInfo
        )
        
        do {
            let folderInfo = try await sut.folderInfo(node: NodeEntity(handle: HandleEntity()))
            XCTAssertEqual(folderInfo, expectedFolderInfo)
        } catch {
            XCTFail("Expected folder info, but received an error: \(error)")
        }
    }

    func testHasVersions_validHandle_returnsTrue() {
        let sut = makeSUT(
            nodeHasVersions: true
        )
        let hasVersions = sut.hasVersions(nodeHandle: HandleEntity())
        XCTAssertTrue(hasVersions)
    }

    func testIsDownloaded_validHandle_returnsTrue() {
        let sut = makeSUT(
            isDownloaded: true
        )
        let isDownloaded = sut.isDownloaded(nodeHandle: HandleEntity())
        XCTAssertTrue(isDownloaded)
    }

    func testIsInRubbishBin_validHandle_returnsFalse() {
        let node = NodeEntity(
            handle: HandleEntity(1)
        )
        let sut = makeSUT(
            nodeInRubbishBin: node
        )
        let isInRubbishBin = sut.isInRubbishBin(nodeHandle: node.handle)
        XCTAssertTrue(isInRubbishBin)
    }
        
    func testNodeForHandle_validHandle_returnsNode() {
        let expectedNode = NodeEntity(handle: HandleEntity(1))
        let sut = makeSUT(
            node: expectedNode
        )
        let node = sut.nodeForHandle(expectedNode.handle)
        XCTAssertEqual(node, expectedNode)
    }
    
    func testParentForHandle_validHandle_returnsParentNode() {
        let expectedNode = NodeEntity(handle: HandleEntity(1))
        let sut = makeSUT(
            parentNode: expectedNode
        )
        let parentNode = sut.parentForHandle(expectedNode.handle)
        XCTAssertEqual(parentNode, expectedNode)
    }
    
    func testParentsForHandle_validHandle_returnsParents() async {
        let expectedNodes = [
            NodeEntity(
                handle: HandleEntity(1)
            ),
            NodeEntity(
                handle: HandleEntity(2)
            )
        ]
        let sut = makeSUT(
            node:
                NodeEntity(
                    handle: HandleEntity(3)
                ),
            parents: expectedNodes
        )
        let parents = await sut.parentsForHandle(HandleEntity(3))
        XCTAssertEqual(parents, expectedNodes)
    }
    
    func testChildrenNamesOf_validNode_returnsChildrenNames() {
        let expectedNames = ["Child1", "Child2"]
        
        let sut = makeSUT(
            children: [
                NodeEntity(name: "Child1", handle: HandleEntity(2)),
                NodeEntity(name: "Child2", handle: HandleEntity(3))
            ]
        )
        
        let childrenNames = sut.childrenNamesOf(node: NodeEntity(handle: HandleEntity(1)))
        XCTAssertEqual(childrenNames, expectedNames)
    }
    
    func testIsRubbishBinRoot_validNode_returnsTrue() {
        let expectedNode = NodeEntity(handle: HandleEntity(1))
        let sut = makeSUT(
            nodeInRubbishBin: expectedNode
        )
        XCTAssertTrue(sut.isRubbishBinRoot(node: expectedNode))
    }
    
    func testIsRestorable_nodeInRubbishBinAndRestorePossible_returnsTrue() {
        let node = NodeEntity(
            handle: HandleEntity(1),
            restoreParentHandle: HandleEntity(2)
        )
        let restoreNode = NodeEntity(
            handle: HandleEntity(2)
        )
        let sut = makeSUT(
            nodeInRubbishBin: node,
            node: restoreNode
        )
        XCTAssertTrue(sut.isRestorable(node: node))
    }
    
    func testNodeUpdates_onNodeUpdate_shouldYieldValues() async {
        let nodeUpdates = [NodeEntity(changeTypes: .new, handle: 4)]
        let nodeUpdateAsyncSequence = SingleItemAsyncSequence(item: nodeUpdates)
            .eraseToAnyAsyncSequence()

        let sut = makeSUT(nodeUpdates: nodeUpdateAsyncSequence)
        
        var iterator = sut.nodeUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        
        XCTAssertEqual(result, nodeUpdates)
    }
    
    func testFolderLinkInfo_whenRequestSucceed_shouldReturnFolderLinkInfoEntity() async throws {
        let expectedResult = FolderLinkInfoEntity(
            folderInfo: nil,
            nodeHandle: HandleEntity(1),
            parentHandle: HandleEntity(2),
            name: "Sample")
        let sut = makeSUT(folderLinkInfoRequestResult: .success(expectedResult))
        
        let folderLinkInfo = try await sut.folderLinkInfo(sampleFolderLink)
        XCTAssertEqual(folderLinkInfo, expectedResult)
    }
    
    func testFolderLinkInfo_whenRequestFailed_shouldThrowError() async {
        let sut = makeSUT(folderLinkInfoRequestResult: .failure(.notFound))
        
        await XCTAsyncAssertThrowsError(try await sut.folderLinkInfo(sampleFolderLink)) { errorThrown in
            XCTAssertEqual(errorThrown as? FolderInfoErrorEntity, .notFound)
        }
    }
    
    func testNodeForFileLink_whenHasNode_shouldReturnCorrectNode() async throws {
        let expectedNode = NodeEntity(handle: HandleEntity(1))
        let sut = makeSUT(fileLinkNode: expectedNode)
        
        let nodeForLink = try await sut.nodeForFileLink(sampleFileLink)
        
        XCTAssertEqual(nodeForLink, expectedNode)
    }
    
    func testNodeForFileLink_whenHasNoNode_shouldThrowError() async throws {
        let sut = makeSUT(fileLinkNode: nil)
        
        await XCTAsyncAssertThrowsError(try await sut.nodeForFileLink(sampleFileLink)) { errorThrown in
            XCTAssertEqual(errorThrown as? NodeErrorEntity, .nodeNotFound)
        }
    }

    // MARK: - Helpers
    private func makeSUT(
        accessLevel: NodeAccessTypeEntity = .unknown,
        label: String = "",
        filesAndFoldersCount: (Int, Int) = (0, 0),
        size: UInt64 = 0,
        folderInfo: FolderInfoEntity? = nil,
        nodeHasVersions: Bool = false,
        isDownloaded: Bool = false,
        nodeInRubbishBin: NodeEntity? = nil,
        node: NodeEntity? = nil,
        parentNode: NodeEntity? = nil,
        parents: [NodeEntity] = [],
        children: [NodeEntity] = [],
        isInheritingSensitivityResult: Result<Bool, Error> = .failure(GenericErrorEntity()),
        isInheritingSensitivityResults: [NodeEntity: Result<Bool, Error>] = [:],
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        folderLinkInfoRequestResult: Result<FolderLinkInfoEntity?, FolderInfoErrorEntity> = .failure(.notFound),
        fileLinkNode: NodeEntity? = nil
    ) -> NodeUseCase<MockNodeDataRepository, MockNodeValidationRepository, MockNodeRepository> {
        let mockNodeDataRepository = MockNodeDataRepository(
            nodeAccessLevel: accessLevel,
            labelString: label,
            filesAndFoldersCount: filesAndFoldersCount,
            folderInfo: folderInfo,
            folderLinkInfoRequestResult: folderLinkInfoRequestResult,
            size: size,
            node: node,
            parentNode: parentNode
        )
        let mockNodeValidationRepository = MockNodeValidationRepository(
            hasVersions: nodeHasVersions,
            isDownloaded: isDownloaded,
            nodeInRubbishBin: nodeInRubbishBin
        )
        let mockNodeRepository = MockNodeRepository(
            node: node, 
            rubbishBinNode: nodeInRubbishBin,
            fileLinkNode: fileLinkNode,
            childrenNodes: children,
            parentNodes: parents,
            isInheritingSensitivityResult: isInheritingSensitivityResult,
            isInheritingSensitivityResults: isInheritingSensitivityResults,
            nodeUpdates: nodeUpdates
        )
        return NodeUseCase(
            nodeDataRepository: mockNodeDataRepository,
            nodeValidationRepository: mockNodeValidationRepository,
            nodeRepository: mockNodeRepository)
    }
    
    private let sampleFolderLink = "https://mega.nz/folder/1dICRLJS#snJiad_4WfCKEK7bgPri3A"
    private let sampleFileLink = FileLinkEntity(linkURL: URL(string: "https://mega.nz/file/1dICRLJS#snJiad_4WfCKEK7bgPri3A")!) 
}
