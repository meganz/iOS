@testable import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class RecentlyOpenedNodesRepositoryTests: XCTestCase {
    
    // MARK: - init
    
    func testInit_whenCalled_doesNotRequestStore() {
        let (_, store) = makeSUT()
        
        XCTAssertTrue(store.invocations.isEmpty)
    }
    
    // MARK: - loadNodes
    
    func testLoadNodes_whenCalled_invokeStore() async throws {
        let (sut, store) = makeSUT()
        
        _ = try? await sut.loadNodes()
        
        XCTAssertEqual(store.invocations, [ .fetchRecentlyOpenedNodes ])
    }
    
    // MARK: - clearNodes
    
    func testClearNodes_whenCalled_invokeStore() async throws {
        let (sut, store) = makeSUT()
        
        _ = try await sut.clearNodes()
        
        XCTAssertEqual(store.invocations, [ .clearRecentlyOpenedNodes ])
    }
    
    // MARK: - SaveNode
    
    func testSaveNode_whenCalled_saveNode() async {
        let (sut, store) = makeSUT()
        let node = anyNode(handle: 1, fingerprint: "any-fingerprint")
        let nodeToSave = RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: Date.now,
            mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
        )
        
        try? sut.saveNode(recentlyOpenedNode: nodeToSave)
        
        XCTAssertEqual(store.invocations, [ .insertOrUpdateRecentlyOpenedNode ])
    }
    
    func testSaveNode_whenCalledButNodeHasNoFingerprint_doesNotSaveNode() async {
        let (sut, store) = makeSUT()
        let node = anyNode(handle: 1, fingerprint: nil)
        let nodeToSave = RecentlyOpenedNodeEntity(
            node: node,
            lastOpenedDate: Date.now,
            mediaDestination: MediaDestinationEntity(fingerprint: node.fingerprint ?? "", destination: 1, timescale: 1)
        )
        
        do {
            try sut.saveNode(recentlyOpenedNode: nodeToSave)
            XCTFail("Expect to fail, bot not throwing error instead.")
        } catch {
            XCTAssertEqual(store.invocations, [])
            XCTAssertEqual(error as? RecentlyOpenedNodesErrorEntity, .couldNotSaveNodeFailToGetDataToSave)
        }
    }
    
    // MARK: - clearNode
    
    func testClearNode_whenCalled_invokeStore() async throws {
        let fingerprint = "any-fingerprint"
        let (sut, store) = makeSUT()
        
        _ = try await sut.clearNode(for: fingerprint)
        
        XCTAssertEqual(store.invocations, [ .clearRecentlyOpenedNode(fingerprint: fingerprint) ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: RecentlyOpenedNodesRepository,
        store: MockMEGAStore
    ) {
        let store = MockMEGAStore()
        let sut = RecentlyOpenedNodesRepository(store: store, sdk: MockSdk())
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyNode(handle: HandleEntity, fingerprint: String? = nil) -> NodeEntity {
        NodeEntity(name: "node-\(handle).anyFileExtension", fingerprint: fingerprint, handle: handle)
    }
}
