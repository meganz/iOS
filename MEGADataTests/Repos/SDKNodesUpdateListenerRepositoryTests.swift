@testable import MEGA
import MEGADataMock
import XCTest

final class SDKNodesUpdateListenerRepositoryTests: XCTestCase {
    
    func testMEGAGlobalDelegateonNodesUpdate_shouldPassNodeEntitiesToUpdateHandler() {
        let mockSdk = MockSdk()
        let repo = SDKNodesUpdateListenerRepository(sdk: mockSdk)
        let nodes =  [MockNode(handle: 1),
                      MockNode(handle: 2)]
        let exp = expectation(description: "SDK onNodesUpdate pass to onNodesUpdateHandler")
        repo.onNodesUpdateHandler = {
            XCTAssertEqual($0, nodes.toNodeEntities())
            exp.fulfill()
        }
        repo.onNodesUpdate(mockSdk, nodeList: MockNodeList(nodes: nodes))
        wait(for: [exp], timeout: 0.5)
    }
}
