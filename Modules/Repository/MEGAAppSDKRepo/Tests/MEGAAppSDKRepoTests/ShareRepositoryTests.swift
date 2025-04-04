import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

final class ShareRepositoryTests: XCTestCase {
    
    func testAllPublicLinks_shouldMapToNodeEntity() async {
        let mockNodeList = MockNodeList(nodes: mockNodes())
        let mockSdk = MockSdk(nodeList: mockNodeList)
        let repo = ShareRepository(sdk: mockSdk)
        let result = repo.allPublicLinks(sortBy: .defaultAsc)
        XCTAssertEqual(result, mockNodeList.toNodeEntities())
    }
    
    func testAllOutShares_shouldMapToShareEntity() async {
        let mockShareList = MockShareList(shares: mockShares())
        let mockSdk = MockSdk(shareList: mockShareList)
        let repo = ShareRepository(sdk: mockSdk)
        let result = repo.allOutShares(sortBy: .defaultAsc)
        XCTAssertEqual(result, mockShareList.toShareEntities())
    }
    
    func testCreateShareKey_shouldReturnSameNodeHandle() async throws {
        let mockNode = MockNode(handle: 1)
        let sharedFolderNodeEntity = mockNode.toNodeEntity()
        let repo = ShareRepository(sdk: MockSdk(nodes: [mockNode]))
        let nodeEntityHandle = try await repo.createShareKey(forNode: sharedFolderNodeEntity)
        XCTAssertTrue(nodeEntityHandle == sharedFolderNodeEntity.handle)
    }
    
    // MARK: Private
    private func mockNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1"),
         MockNode(handle: 2, name: "2")]
    }
    
    private func mockShares() -> [MockShare] {
        [MockShare(nodeHandle: 1),
         MockShare(nodeHandle: 2)]
    }
}
