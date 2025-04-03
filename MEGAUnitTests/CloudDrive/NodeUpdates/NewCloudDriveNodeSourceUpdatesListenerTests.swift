import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class NewCloudDriveNodeSourceUpdatesListenerTests: XCTestCase {
    
    class Harness {
        private let stream: AsyncStream<[NodeEntity]>
        private let continuation: AsyncStream<[NodeEntity]>.Continuation
        
        let sut: NewCloudDriveNodeSourceUpdatesListener
        var cancellables = Set<AnyCancellable>()
        
        init() {
            (stream, continuation) = AsyncStream<[NodeEntity]>.makeStream()
            let nodeUpdatesProvider = MockNodeUpdatesProvider(nodeUpdates: stream.eraseToAnyAsyncSequence())
            
            let testNodeEntity = NodeEntity(name: "0", handle: 0)
            
            sut = NewCloudDriveNodeSourceUpdatesListener(
                originalNodeSource: .node { testNodeEntity },
                nodeUpdatesProvider: nodeUpdatesProvider
            )
        }

        func startListening() {
            sut.startListening()
        }
        
        func stopListening() {
            sut.stopListening()
        }
        
        func invokeNodesUpdate(_ updatedNodes: [NodeEntity]) {
            continuation.yield(updatedNodes)
        }
    }
    
    func test_nodesUpdatedBeforeListening_shouldNotEmitNodeSource() async {
        // Given
        let harness = Harness()
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        
        harness.sut.nodeSourcePublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &harness.cancellables)
        
        // when
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func test_nodesUpdatedAfterListeningButNewUpdatesDontMatchCurrentNode_shouldNotEmitNodeSource() async {
        // Given
        let harness = Harness()
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        
        harness.sut.nodeSourcePublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        let updatedNodes = [NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func test_nodesUpdatedAfterListening_shouldEmitNodeSource() async {
        // Given
        let harness = Harness()
        let expectation = expectation(description: #function)
        
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            XCTAssertEqual(nodeSource.parentNode?.name, "0-new")
            expectation.fulfill()
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func test_nodesUpdatedAfterListeningAndThenStopping_shouldNotEmitNodeSource() async {
        // Given
        let harness = Harness()
        let expectation = expectation(description: #function)
        expectation.isInverted = true
        
        harness.sut.nodeSourcePublisher.sink { _ in
            expectation.fulfill()
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        harness.stopListening()
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        // then
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func test_nodesUpdatedAfterListeningAndThenStoppingAndStartAgain_shouldEmitNodeSource() async {
        // Given
        let harness = Harness()
        let expectation = expectation(description: #function)
        
        harness.sut.nodeSourcePublisher.sink { nodeSource in
            XCTAssertEqual(nodeSource.parentNode?.name, "0-new")
            expectation.fulfill()
        }.store(in: &harness.cancellables)
        
        // when
        harness.startListening()
        harness.stopListening()
        
        let updatedNodes = [NodeEntity(name: "0-new", handle: 0), NodeEntity(name: "1", handle: 1), NodeEntity(name: "2", handle: 2)]
        harness.invokeNodesUpdate(updatedNodes)
        
        harness.startListening()
        
        // then
        await fulfillment(of: [expectation], timeout: 1)
    }
}
