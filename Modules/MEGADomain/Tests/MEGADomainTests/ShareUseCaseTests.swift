import XCTest
import MEGADomain
import MEGADomainMock

final class ShareUseCaseTests: XCTestCase {

    func testCreateShareKey_shouldReturnSameNodeEntity() async throws {
        let sharedFolderNode1 = NodeEntity(name: "FolderNode1", handle: 1)
        let sharedFolderNode2 = NodeEntity(name: "FolderNode2", handle: 2)
        let sharedFolderNode3 = NodeEntity(name: "FolderNode3", handle: 3)
        let mockNodeEntities = [sharedFolderNode1, sharedFolderNode2, sharedFolderNode3]
        let mockRepo = MockShareRepository.newRepo
        let sut = ShareUseCase(repo: mockRepo)
        
        let nodeEntityResultHandles = try await sut.createShareKeys(forNodes: mockNodeEntities)
        XCTAssertTrue(Set(nodeEntityResultHandles) == Set(mockRepo.sharedNodeHandles))
    }
}
