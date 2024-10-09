import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class RecentlyOpenedNodesUseCaseTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenInit_doesNotPerformAnyRequest() {
        let (_, recentlyOpenedNodesRepository) = makeSUT()
        
        XCTAssertTrue(recentlyOpenedNodesRepository.messages.isEmpty)
    }
    
    // MARK: - loadNodes
    
    func testLoadNodes_whenCalled_requestLoadNodes() async {
        let (sut, recentlyOpenedNodesRepository) = makeSUT()
        
        _ = try? await sut.loadNodes()
        
        XCTAssertEqual(recentlyOpenedNodesRepository.messages, [ .loadNodes ])
    }
    
    func testLoadNodes_whenCalledWithError_deliversError() async {
        let error = NSError(domain: "any error", code: 1)
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(loadNodesResult: .failure(error))
        )
        
        await XCTAsyncAssertThrowsError(try await sut.loadNodes()) { thrownError in
            XCTAssertEqual(thrownError as NSError, error)
        }
    }
    
    func testLoadNodes_whenCalledSuccessfully_deliversEmptyItems() async throws {
        let emptyItems: [RecentlyOpenedNodeEntity] = []
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(loadNodesResult: .success(emptyItems))
        )
        
        let receivedItems = try await sut.loadNodes()
        
        XCTAssertEqual(emptyItems, receivedItems)
    }
    
    func testLoadNodes_whenCalledSuccessfully_deliversSingleItems() async throws {
        let node = nodeEntity(handle: 1)
        let singleItems: [RecentlyOpenedNodeEntity] = [
            RecentlyOpenedNodeEntity(
                node: nodeEntity(handle: 1),
                lastOpenedDate: nil,
                mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
            )
        ]
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(loadNodesResult: .success(singleItems))
        )
        
        let receivedItems = try await sut.loadNodes()
        
        XCTAssertEqual(singleItems, receivedItems)
    }
    
    func testLoadNodes_whenCalledSuccessfully_deliversMoreThanOneItems() async throws {
        let node1 = nodeEntity(handle: 1)
        let node2 = nodeEntity(handle: 2)
        let items: [RecentlyOpenedNodeEntity] = [
            RecentlyOpenedNodeEntity(
                node: nodeEntity(handle: 1),
                lastOpenedDate: nil,
                mediaDestination: MediaDestinationEntity(fingerprint: node1.fingerprint ?? "", destination: 1, timescale: 1)
            ),
            RecentlyOpenedNodeEntity(
                node: nodeEntity(handle: 2),
                lastOpenedDate: nil,
                mediaDestination: MediaDestinationEntity(fingerprint: node2.fingerprint ?? "", destination: 1, timescale: 1)
            )
        ]
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(loadNodesResult: .success(items))
        )
        
        let receivedItems = try await sut.loadNodes()
        
        XCTAssertEqual(items, receivedItems)
    }
    
    // MARK: - clearNodes
    
    func testClearNodes_whenCalled_requestClearNodes() async {
        let (sut, recentlyOpenedNodesRepository) = makeSUT()
        
        _ = try? await sut.clearNodes()
        
        XCTAssertEqual(recentlyOpenedNodesRepository.messages, [ .clearNodes ])
    }
    
    func testClearNodes_whenCalledWithError_deliversError() async {
        let error = NSError(domain: "any error", code: 1)
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(clearNodesResult: .failure(error))
        )
        
        await XCTAsyncAssertThrowsError(try await sut.clearNodes()) { thrownError in
            XCTAssertEqual(thrownError as NSError, error)
        }
    }
    
    func testClearNodes_whenCalledSuccessfully_doesNotThrowError() async throws {
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(clearNodesResult: .success(()))
        )
        
        try await sut.clearNodes()
    }
    
    // MARK: - saveNode
    
    func testSaveNode_whenCalled_performSaveNode() {
        let (sut, recentlyOpenedNodesRepository) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository()
        )
        let node = nodeEntity(handle: 1)
        let recentlyOpenedNodeEntity = RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: Date.now,
            mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
        )
        
        try? sut.saveNode(recentlyOpenedNode: recentlyOpenedNodeEntity)
        
        XCTAssertEqual(recentlyOpenedNodesRepository.messages, [ .saveNode(recentlyOpenedNodeEntity) ])
    }
    
    func testSaveNode_whenCalledWithError_canThrowError() {
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(saveNodeResult: .failure(GenericErrorEntity()))
        )
        let node = nodeEntity(handle: 1)
        let recentlyOpenedNodeEntity = RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: Date.now,
            mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
        )
        
        var receivedError: Error?
        do {
            try sut.saveNode(recentlyOpenedNode: recentlyOpenedNodeEntity)
            XCTFail("expect to throw error, but not throwing error instead.")
        } catch {
            receivedError = error
        }
        
        XCTAssertNotNil(receivedError)
    }
    
    func testSaveNode_whenCalledSuccessfully_doesNotThrowError() throws {
        let (sut, _) = makeSUT(
            recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository(saveNodeResult: .success(()))
        )
        let node = nodeEntity(handle: 1)
        let recentlyOpenedNodeEntity = RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: Date.now,
            mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
        )
        
        try sut.saveNode(recentlyOpenedNode: recentlyOpenedNodeEntity)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository = MockRecentlyOpenedNodesRepository()
    ) -> (
        sut: RecentlyOpenedNodesUseCase,
        recentlyOpenedNodesRepository: MockRecentlyOpenedNodesRepository
    ) {
        let sut = RecentlyOpenedNodesUseCase(recentlyOpenedNodesRepository: recentlyOpenedNodesRepository)
        return (sut, recentlyOpenedNodesRepository)
    }
    
    private func nodeEntity(handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "any-node-\(handle).anyFileExtension", handle: handle)
    }
    
}
