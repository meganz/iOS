import MEGADomain
import MEGADomainMock
import XCTest

final class ShareUseCaseTests: XCTestCase {

    func testCreateShareKey_shouldReturnSameNodeEntity() async throws {
        let sharedFolderNode1 = NodeEntity(name: "FolderNode1", handle: 1)
        let sharedFolderNode2 = NodeEntity(name: "FolderNode2", handle: 2)
        let sharedFolderNode3 = NodeEntity(name: "FolderNode3", handle: 3)
        let mockNodeEntities = [sharedFolderNode1, sharedFolderNode2, sharedFolderNode3]
        let shareRepository = MockShareRepository.newRepo
        let sut = makeSUT(shareRepository: shareRepository)
        
        let nodeEntityResultHandles = try await sut.createShareKeys(forNodes: mockNodeEntities)
        XCTAssertTrue(Set(nodeEntityResultHandles) == Set(mockNodeEntities.map(\.handle)))
    }
    
    func testContainsSensitiveContent_whenNoNodesPassed_shouldReturnFalse() async throws {
        let sut = makeSUT()
        
        let result = try await sut.containsSensitiveContent(in: [])
        XCTAssertFalse(result)
    }
    
    func testContainsSensitiveContent_whenNodeContainsOneSensitveNode_shouldReturnFalse() async throws {
        let parentNode = NodeEntity(handle: 10)
        let nodes: [NodeEntity] = [
            NodeEntity(handle: 1, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 2, parentHandle: parentNode.handle, isMarkedSensitive: true),
            NodeEntity(handle: 3, parentHandle: parentNode.handle, isMarkedSensitive: false)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [
                10: nodes
            ]),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResult: .success(false)))
        
        let result = try await sut.containsSensitiveContent(in: [parentNode])
        XCTAssertTrue(result)
    }
    
    func testContainsSensitiveContent_whenNodeDoesContainsSensitveDescendantNode_shouldReturnTrue() async throws {
        let parentNode = NodeEntity(handle: 10)
        let nodes: [NodeEntity] = [
            NodeEntity(handle: 1, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 2, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 3, parentHandle: parentNode.handle, isMarkedSensitive: false)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [
                10: nodes
            ]),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResult: .success(false))
        )
        
        let result = try await sut.containsSensitiveContent(in: [parentNode])
        XCTAssertFalse(result)
    }
    
    func testContainsSensitiveContent_whenNodeIsSensitive_shouldReturnTrue() async throws {
        let parentNode = NodeEntity(handle: 10, isMarkedSensitive: true)
        let nodes: [NodeEntity] = [
            NodeEntity(handle: 2, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 3, parentHandle: parentNode.handle, isMarkedSensitive: false)
        ]
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [
                10: nodes
            ]))
        
        let result = try await sut.containsSensitiveContent(in: [parentNode])
        XCTAssertTrue(result)
    }
    
    func testContainsSensitiveContent_whenNodeIsNotSensitiveAndIsFile_shouldReturnFalse() async throws {
        let parentNode = NodeEntity(handle: 10, isFile: true, isMarkedSensitive: false)
        
        let sut = makeSUT(
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [:]),
            nodeRepository: MockNodeRepository(
                isInheritingSensitivityResult: .success(false))
        )
        
        let result = try await sut.containsSensitiveContent(in: [parentNode])
        XCTAssertFalse(result)
    }
    
    func testContainsSensitiveContent_nodeIsInheritingSensitivity_shouldReturnTrue() async throws {
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        let nodeRepository = MockNodeRepository(isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(nodeRepository: nodeRepository)
        
        let result = try await sut.containsSensitiveContent(in: [node])
        
        XCTAssertTrue(result)
    }
    
    private func makeSUT(
        shareRepository: MockShareRepository = MockShareRepository(),
        filesSearchRepository: MockFilesSearchRepository = MockFilesSearchRepository(),
        nodeRepository: MockNodeRepository = MockNodeRepository()
    ) -> ShareUseCase<MockShareRepository, MockFilesSearchRepository, MockNodeRepository> {
        ShareUseCase(
            shareRepository: shareRepository,
            filesSearchRepository: filesSearchRepository,
            nodeRepository: nodeRepository)
    }
}
