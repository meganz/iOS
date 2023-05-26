import XCTest
import MEGADomain
import MEGADomainMock
import MEGADataMock
import MEGAData

final class MediaDiscoveryRepositoryTests: XCTestCase {
    
    func testLoadingNodes_onMediaDiscovery_shouldReturnTrue() async throws {
        let childrenNodes = sampleNodes()
        let sdk = MockSdk(nodes: childrenNodes)
        let repo = MediaDiscoveryRepository(sdk:sdk)
        let parentNode = NodeEntity(handle: 0)
        let nodes = try await repo.loadNodes(forParent: parentNode)
        
        XCTAssertEqual(nodes.count, childrenNodes.count)
    }
    
    func testAddingDelegate_onMediaDiscovery_shouldReturnTrue() async throws {
        let sdk = MockSdk()
        let repo = MediaDiscoveryRepository(sdk:sdk)
        
        repo.startMonitoringNodesUpdate()
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
    }
    
    func testAddingDelegate_onMediaDiscovery_shouldReturnFalse() async throws {
        let sdk = MockSdk()
        sdk.hasGlobalDelegate = true
        let repo = MediaDiscoveryRepository(sdk:sdk)
        
        repo.stopMonitoringNodesUpdate()
        
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    // MARK: Private
    
    private func sampleNodes() -> [MockNode] {
        let node0 = MockNode(handle: 0, name: "Test0", parentHandle: 0)
        let node1 = MockNode(handle: 1, name: "Test1", parentHandle: 0)
        let node2 = MockNode(handle: 2, name: "Test2", parentHandle: 0)
        let node3 = MockNode(handle: 3, name: "Test3", parentHandle: 0)
        
        return [node0, node1, node2, node3]
    }
}
