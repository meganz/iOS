import Combine
@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGADomainMock
import XCTest

final class FilesSearchRepositoryTests: XCTestCase {
    
    private let rootNode = MockNode(handle: 0, name: "root")
    private var subscriptions = Set<AnyCancellable>()
    
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
    
    func testOnNodesUpdate_whenCallbackProvided_shouldCallCallback() {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let mockNodeList = MockNodeList(nodes: [mockNode])
        let mockSdk = MockSdk(nodes: [mockNode])
        let repo = FilesSearchRepository(sdk: mockSdk)
        
        let exp = expectation(description: "Calling callback should be successful")
        
        repo.startMonitoringNodesUpdate { nodes in
            XCTAssertEqual([mockNode.toNodeEntity()], nodes)
            exp.fulfill()
        }
        
        repo.onNodesUpdate(mockSdk, nodeList: mockNodeList)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testOnNodesUpdate_whenCallbackNotProvided_shouldUsePublisher() {
        let handle = HandleEntity(25)
        let mockNode = MockNode(handle: handle)
        let mockNodeList = MockNodeList(nodes: [mockNode])
        let mockSdk = MockSdk(nodes: [mockNode])
        let repo = FilesSearchRepository(sdk: mockSdk)
        
        let exp = expectation(description: "Using publisher should be successful")
        
        repo.nodeUpdatesPublisher.sink { nodes in
            XCTAssertEqual([mockNode.toNodeEntity()], nodes)
            exp.fulfill()
        }.store(in: &subscriptions)
        
        repo.startMonitoringNodesUpdate(callback: nil)
        repo.onNodesUpdate(mockSdk, nodeList: mockNodeList)
        wait(for: [exp], timeout: 1.0)
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
