import MEGADomain
import MEGADomainMock
import XCTest

final class ShareUseCaseTests: XCTestCase {

    func testCreateShareKey_shouldReturnSameNodeEntity() async throws {
        let sharedFolderNode1 = NodeEntity(name: "FolderNode1", handle: 1)
        let sharedFolderNode2 = NodeEntity(name: "FolderNode2", handle: 2)
        let sharedFolderNode3 = NodeEntity(name: "FolderNode3", handle: 3)
        let mockNodeEntities = [sharedFolderNode1, sharedFolderNode2, sharedFolderNode3]
        let mockRepo = MockShareRepository.newRepo
        let sut = ShareUseCase(repo: mockRepo, filesSearchRepository: MockFilesSearchRepository())
        
        let nodeEntityResultHandles = try await sut.createShareKeys(forNodes: mockNodeEntities)
        XCTAssertTrue(Set(nodeEntityResultHandles) == Set(mockNodeEntities.map(\.handle)))
    }
    
    func testDoesContainSensitiveDescendants_whenNoNodesPassed_shouldReturnFalse() async throws {
        
        let sut = ShareUseCase(
            repo: MockShareRepository.newRepo,
            filesSearchRepository: MockFilesSearchRepository())
        
        let result = try await sut.doesContainSensitiveDescendants(in: [])
        XCTAssertFalse(result)
    }
    
    func testDoesContainSensitiveDescendants_whenNodeContainsOneSensitveNode_shouldReturnFalse() async throws {
        
        let parentNode = NodeEntity(handle: 10)
        let nodes: [NodeEntity] = [
            NodeEntity(handle: 1, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 2, parentHandle: parentNode.handle, isMarkedSensitive: true),
            NodeEntity(handle: 3, parentHandle: parentNode.handle, isMarkedSensitive: false)
        ]
        
        let sut = ShareUseCase(
            repo: MockShareRepository.newRepo,
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [
                10: nodes
            ]))
        
        let result = try await sut.doesContainSensitiveDescendants(in: [parentNode])
        XCTAssertTrue(result)
    }
    
    func testDoesContainSensitiveDescendants_whenNodeDoesContainsSensitveDescendantNode_shouldReturnTrue() async throws {
        
        let parentNode = NodeEntity(handle: 10)
        let nodes: [NodeEntity] = [
            NodeEntity(handle: 1, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 2, parentHandle: parentNode.handle, isMarkedSensitive: false),
            NodeEntity(handle: 3, parentHandle: parentNode.handle, isMarkedSensitive: false)
        ]
        
        let sut = ShareUseCase(
            repo: MockShareRepository.newRepo,
            filesSearchRepository: MockFilesSearchRepository(nodesForHandle: [
                10: nodes
            ]))
        
        let result = try await sut.doesContainSensitiveDescendants(in: [parentNode])
        XCTAssertFalse(result)
    }
}
