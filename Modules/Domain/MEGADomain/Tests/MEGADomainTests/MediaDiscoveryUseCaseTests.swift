import Combine
import MEGADomain
import MEGADomainMock
import XCTest

final class MediaDiscoveryUseCaseTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testLoadNodes_forParentNode_returnsCorrectNodes() async {
        let photoNodes = [NodeEntity(name: "0.jpg", handle: 1)]
        let videoNodes = [NodeEntity(name: "1.mp4", handle: 2)]
        let expectedNodes = photoNodes + videoNodes
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: photoNodes, videoNodes: videoNodes)
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        do {
            let nodes = try await useCase.nodes(forParent: NodeEntity(name: "parent", handle: 0))
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
    }
    
    func testLoadNodes_forParentNode_returnsNodesRecursively() async {
        let nodePhotoParent = NodeEntity(nodeType: .folder, name: "Inner Photo", handle: 100, isFolder: true)
        let nodeVideoParent = NodeEntity(nodeType: .folder, name: "Inner Video", handle: 200, isFolder: true)
        let photoNode1 = NodeEntity(name: "1.jpg", handle: 1)
        let photoNode2 = NodeEntity(name: "2.jpg", handle: 2, parentHandle: 100)
        let videoNode1 = NodeEntity(name: "5.mp4", handle: 5)
        let videoNode2 = NodeEntity(name: "6.mp4", handle: 6, parentHandle: 200)
        let photoNodes = [photoNode1, nodePhotoParent, photoNode2]
        let videoNodes = [videoNode1, nodeVideoParent, videoNode2]
        let expectedNodes = [photoNode1, photoNode2, videoNode1, videoNode2]
        let fileSearchRepo = MockFilesSearchRepository(photoNodes: photoNodes, videoNodes: videoNodes)
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        
        do {
            let nodes = try await useCase.nodes(forParent: NodeEntity(name: "parent", handle: 0))
            XCTAssertEqual(Set(nodes), Set(expectedNodes))
        } catch {
            XCTFail("Unexpected failure")
        }
    }
    
    func testNodeUpdates_subscription_returnPublishedNodeUpdatesAndHandleDelegateCalls() {
        let nodesUpdatePublisher =  PassthroughSubject<[NodeEntity], Never>()
        let fileSearchRepo = MockFilesSearchRepository(nodesUpdatePublisher: nodesUpdatePublisher.eraseToAnyPublisher())
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: fileSearchRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)

        let expectaction = expectation(description: "Wait for publisher to complete")

        var results = [[NodeEntity]]()
        useCase.nodeUpdatesPublisher.sink(receiveCompletion: { _ in expectaction.fulfill() },
                                 receiveValue: {
            results.append($0)
        }).store(in: &subscriptions)

        useCase.nodeUpdatesPublisher.sink { _ in

        }.store(in: &subscriptions)

        XCTAssertTrue(fileSearchRepo.startMonitoringNodesUpdateCalled == 1)

        let expectedNodes = [NodeEntity(handle: 0), NodeEntity(handle: 1)]
        nodesUpdatePublisher.send(expectedNodes)
        nodesUpdatePublisher.send(completion: .finished)

        waitForExpectations(timeout: 2)
        XCTAssertEqual(results, [expectedNodes])
        XCTAssertTrue(fileSearchRepo.stopMonitoringNodesUpdateCalled == 1)
    }
    
    // MARK: Should reload
    
    func testShouldReload_onShouldProcessNodesUpdateReturnFalse_shouldReturnFalse() {
        let nodeUpdateRepository = MockNodeUpdateRepository(shouldProcessOnNodesUpdate: false)
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: nodeUpdateRepository)
        XCTAssertFalse(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(handle: 3)]))
    }

    func testShouldReload_onUpdateNodeMovedToTrash_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: [NodeEntity(changeTypes: .parent, nodeType: .rubbish, handle: 2)]))
    }

    func testShouldReload_onNoUpdates_shouldReturnFalse() {
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertFalse(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [NodeEntity(handle: 2)], updatedNodes: []))
    }

    func testShouldReload_onUpdatesWithNewNode_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .new, handle: 2)]))
    }

    func testShouldReload_onUpdatesWithModifiedAttributes_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .attributes, handle: 2)]))
    }

    func testShouldReload_onUpdatesWithModifiedParent_shouldReturnTrue() {
        let useCase = MediaDiscoveryUseCase(filesSearchRepository: MockFilesSearchRepository.newRepo, nodeUpdateRepository: MockNodeUpdateRepository.newRepo)
        XCTAssertTrue(useCase.shouldReload(parentNode: NodeEntity(handle: 1), loadedNodes: [], updatedNodes: [NodeEntity(changeTypes: .attributes, handle: 2)]))
    }
}
