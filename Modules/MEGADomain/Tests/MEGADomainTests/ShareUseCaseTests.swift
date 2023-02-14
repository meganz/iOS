import XCTest
import MEGADomain
import MEGADomainMock

final class ShareUseCaseTests: XCTestCase {

    func testCreateShareKey_shouldReturnSameNodeEntity() async throws {
        let sharedFolderNodeEntity = NodeEntity(name: "FolderNode", handle: 1)
        let sut = ShareUseCase(repo: MockShareRepository(sharedNodeHandle: 1))
        
        let nodeEntityResultHandle = try await sut.createShareKey(forNode: sharedFolderNodeEntity)
        XCTAssertTrue(nodeEntityResultHandle == sharedFolderNodeEntity.handle)
    }
    
}
