import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class NewCloudDriveNodeSourceUpdatesListenerTests: XCTestCase {
    
    class Harness {
        let mockNodeUpdateListener: MockSDKNodesUpdateListenerRepository = MockSDKNodesUpdateListenerRepository.newRepo
        let sut: NewCloudDriveNodeSourceUpdatesListener
        var cancellables = Set<AnyCancellable>()
        
        init(nodeEntity: NodeEntity) {
            sut = NewCloudDriveNodeSourceUpdatesListener(
                originalNodeSource: .node { nodeEntity },
                nodeUpdatesListener: mockNodeUpdateListener
            )
        }

        func startListening() {
            sut.startListening()
        }
        
        func stopListening() {
            sut.stopListening()
        }
        
        func invokeNodesUpdate(_ updatedNodes: [NodeEntity]) {
            mockNodeUpdateListener.onNodesUpdateHandler?(updatedNodes)
        }
    }
    
    let testNodeEntity = NodeEntity(name: "0", handle: 0)
    
    func test_nodesUpdatedBeforeListening_shouldNotEmitNodeSource() {
        // Given
        let harness = Harness(nodeEntity: testNodeEntity)
        
        var result: NodeSource?
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            result = nodeSource
        }.store(in: &harness.cancellables)
        
        // when
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        XCTAssertNil(result)
    }
    
    func test_nodesUpdatedAfterListeningButNewUpdatesDontMatchCurrentNode_shouldNotEmitNodeSource() {
        // Given
        let harness = Harness(nodeEntity: testNodeEntity)
        
        var result: NodeSource?
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            result = nodeSource
        }.store(in: &harness.cancellables)
        
        // when
        let updatedNodes = [NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        XCTAssertNil(result)
    }
    
    func test_nodesUpdatedAfterListening_shouldEmitNodeSource() {
        // Given
        let harness = Harness(nodeEntity: testNodeEntity)
        
        var result: NodeSource?
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            result = nodeSource
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        XCTAssertEqual(result?.parentNode?.name, "0-new")
    }
    
    func test_nodesUpdatedAfterListeningAndThenStopping_shouldNotEmitNodeSource() {
        // Given
        let harness = Harness(nodeEntity: testNodeEntity)
        
        var result: NodeSource?
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            result = nodeSource
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        harness.stopListening()
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        XCTAssertNil(result)
    }
    
    func test_nodesUpdatedAfterListeningAndThenStoppingAndStartAgain_shouldNotEmitNodeSource() {
        // Given
        let harness = Harness(nodeEntity: testNodeEntity)
        
        var result: NodeSource?
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            result = nodeSource
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        harness.stopListening()
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        harness.startListening()
        
        // then
        XCTAssertEqual(result?.parentNode?.name, "0-new")
    }
}
