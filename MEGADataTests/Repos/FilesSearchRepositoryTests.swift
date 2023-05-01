import XCTest
import MEGADomain
import MEGADomainMock
@testable import MEGA
import MEGADataMock

final class FilesSearchRepositoryTests: XCTestCase {
    
    private let rootNode = MockNode(handle: 0, name: "root")
    
    func testStartMonitoring_onAlbumScreen_shouldSetCallBack() {
        let sdk = MockSdk()
        let repo = FilesSearchRepository(sdk: sdk)
        
        repo.startMonitoringNodesUpdate(callback: { _ in })
        
        XCTAssertTrue(sdk.hasGlobalDelegate)
    }
    
    func testStopMonitoring_onAlbumScreen_shouldSetCallBackToNil() {
        let sdk = MockSdk()
        let repo = FilesSearchRepository(sdk: sdk)
        
        repo.stopMonitoringNodesUpdate()
        
        XCTAssertFalse(sdk.hasGlobalDelegate)
    }
    
    func testFetchNodeForHandle_onRetrieval_shouldMapToNodeEnity() async {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let repo = FilesSearchRepository(sdk: MockSdk(nodes: [mockNode]))
        let result = await repo.node(by: handle)
        XCTAssertEqual(result, mockNode.toNodeEntity())
    }
    
    // MARK: Private
    
    private func photoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.raw"),
         MockNode(handle: 2, name: "2.nef"),
         MockNode(handle: 3, name: "3.cr2"),
         MockNode(handle: 4, name: "4.dng"),
         MockNode(handle: 5, name: "5.gif")]
    }
    
    private func videoNodes() -> [MockNode] {
        [MockNode(handle: 1, name: "1.mp4"),
         MockNode(handle: 2, name: "2.mov")]
    }
}
