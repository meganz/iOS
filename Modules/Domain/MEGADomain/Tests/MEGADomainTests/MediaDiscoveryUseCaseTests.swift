import XCTest
import Combine
import MEGADomain
import MEGADomainMock

final class MediaDiscoveryUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadNodes_forParentNode_returnsCorrectNodes() async {
        let expectedNodes = [NodeEntity(name: "0.jpg", handle: 1)]
        let mediaDiscRepo = MockMediaDiscoveryRepository(nodes: expectedNodes)
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: mediaDiscRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        do {
            let nodes = try await useCase.nodes(forParent: NodeEntity(name: "parent", handle: 0))
            XCTAssertEqual(nodes, expectedNodes)
        } catch {
            XCTFail("Unexpected failure")
        }
    }
    
    func testNodeUpdates_subscription_returnPublishedNodeUpdatesAndHandleDelegateCalls() {
        let nodesUpdatePublisher =  PassthroughSubject<[NodeEntity], Never>()
        let mediaDiscRepo = MockMediaDiscoveryRepository(nodesUpdatePublisher: nodesUpdatePublisher.eraseToAnyPublisher())
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: mediaDiscRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        
        let expectaction = expectation(description: "Wait for publisher to complete")
        
        var results = [[NodeEntity]]()
        useCase.nodeUpdatesPublisher.sink(receiveCompletion: { _ in expectaction.fulfill() },
                                 receiveValue:  {
            results.append($0)
        }).store(in: &subscriptions)
        
        
        useCase.nodeUpdatesPublisher.sink { _ in
            
        }.store(in: &subscriptions)
        
        XCTAssertTrue(mediaDiscRepo.startMonitoringNodesUpdateCalled == 1)
        
        let expectedNodes = [NodeEntity(handle: 0), NodeEntity(handle: 1)]
        nodesUpdatePublisher.send(expectedNodes)
        nodesUpdatePublisher.send(completion: .finished)
        
        waitForExpectations(timeout: 2)
        XCTAssertEqual(results, [expectedNodes])
        XCTAssertTrue(mediaDiscRepo.stopMonitoringNodesUpdateCalled == 1)
    }
    
    // MARK: Should reload
    
    func testShouldReload_onShouldProcessNodesUpdateReturnFalse_shouldReturnFalse() {
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(handle: 3)]))
    }
    
    func testShouldReload_onUpdateNodeMovedToTrash_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(changeTypes: .parent, nodeType: .rubbish, handle: 2)]))
    }
    
    func testShouldReload_onNoUpdates_shouldReturnFalse() {
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertFalse(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: []))
    }
    
    func testShouldReload_onUpdatesWithNewNode_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .new, handle: 2)]))
    }
    
    func testShouldReload_onUpdatesWithModifiedAttributes_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .attributes, handle: 2)]))
    }
    
    func testShouldReload_onUpdatesWithModifiedParent_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(mediaDiscoveryRepository: MockMediaDiscoveryRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .attributes, handle: 2)]))
    }
}
