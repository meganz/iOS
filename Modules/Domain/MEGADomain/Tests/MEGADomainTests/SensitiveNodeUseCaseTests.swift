import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class SensitiveNodeUseCaseTests: XCTestCase {

    func testIsInheritingSensitivity_validNode_shouldReturnCorrectSensitivityStatus() async throws {
        let expectedSensitiveStatus = true

        let sut = makeSUT(isInheritingSensitivityResult: .success(expectedSensitiveStatus))
        
        let isSensitive = try await sut.isInheritingSensitivity(node: NodeEntity(handle: 1))
        
        XCTAssertEqual(isSensitive, expectedSensitiveStatus)
    }
    
    func testMonitorInheritedSensitivity_nonFolderUpdates_shouldNotYieldAnything() async throws {
        let nodeUpdates = [NodeEntity(handle: 1, isFile: true, isFolder: false)]
        let nodeUpdateAsyncSequence = SingleItemAsyncSequence(item: nodeUpdates)
            .eraseToAnyAsyncSequence()

        let sut = makeSUT(nodeUpdates: nodeUpdateAsyncSequence)
        
        var iterator = sut.monitorInheritedSensitivity(for: NodeEntity(handle: 4))
            .makeAsyncIterator()
        
        let result = try await iterator.next()
        
        XCTAssertNil(result)
    }
    
    func testMonitorInheritedSensitivity_folderUpdateSensitive_shouldReturnTheInheritSensitivityOfTheNode() async throws {
        let isInheritingSensitivity = true
        let nodeUpdates = [NodeEntity(changeTypes: .sensitive, handle: 4, isFolder: true)]
        let nodeUpdateAsyncSequence = SingleItemAsyncSequence(item: nodeUpdates)
            .eraseToAnyAsyncSequence()

        let sut = makeSUT(
            isInheritingSensitivityResult: .success(isInheritingSensitivity),
            nodeUpdates: nodeUpdateAsyncSequence)
        
        var iterator = sut.monitorInheritedSensitivity(for: NodeEntity(handle: 4))
            .makeAsyncIterator()
        
        let result = try await iterator.next()
        
        XCTAssertEqual(result, isInheritingSensitivity)
    }
    
    func testMonitorInheritedSensitivity_multipleSensitivityUpdates_shouldNotYieldDuplicates() async throws {
        let nodeToMonitor = NodeEntity(handle: 4)
        var isInheritingSensitivityResults: [NodeEntity: Result<Bool, Error>] = [nodeToMonitor: .success(true)]
        let nodeUpdates = [NodeEntity(changeTypes: .sensitive, handle: 4, isFolder: true)]
        let (stream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)

        let sut = makeSUT(
            isInheritingSensitivityResults: isInheritingSensitivityResults,
            nodeUpdates: stream.eraseToAnyAsyncSequence())
        
        let startedExp = expectation(description: "Task started")
        let yieldedExp = expectation(description: "Task yielded")
        let stopedExp = expectation(description: "Async Sequence stopped")
        let task = Task {
            startedExp.fulfill()
            var expectedResults = [true, false]
            for try await isSensitive in sut.monitorInheritedSensitivity(for: NodeEntity(handle: 4)) {
                XCTAssertEqual(isSensitive, expectedResults.removeFirst())
                yieldedExp.fulfill()
            }
            stopedExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 0.25)
        
        continuation.yield(nodeUpdates)
        continuation.yield(nodeUpdates)
        isInheritingSensitivityResults[nodeToMonitor] = .success(false)
        continuation.yield(nodeUpdates)
        continuation.finish()
        
        await fulfillment(of: [yieldedExp, stopedExp], timeout: 1.0)
        task.cancel()
    }
    
    func testSensitivityChanges_nodeUpdatesWithSensitivityChanges_shouldYieldValues() async throws {
        let nodeToMonitorHandle = HandleEntity(65)
        let (stream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)
        let sut = makeSUT(nodeUpdates: stream.eraseToAnyAsyncSequence())
        
        let startedExp = expectation(description: "Task started")
        let yieldedExp = expectation(description: "Task yielded")
        yieldedExp.expectedFulfillmentCount = 2
        let cancelledExp = expectation(description: "Async Sequence stopped")
        let task = Task {
            startedExp.fulfill()
            var expectedResults = [true, false]
            for try await isSensitive in sut.sensitivityChanges(for: NodeEntity(handle: nodeToMonitorHandle)) {
                XCTAssertEqual(isSensitive, expectedResults.removeFirst())
                yieldedExp.fulfill()
            }
            cancelledExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 0.25)
        
        continuation.yield([NodeEntity(changeTypes: .sensitive, handle: nodeToMonitorHandle, isMarkedSensitive: true)])
        continuation.yield([NodeEntity(changeTypes: .sensitive, handle: 654, isMarkedSensitive: true)])
        continuation.yield([NodeEntity(changeTypes: .new, handle: 32)])
        continuation.yield([NodeEntity(changeTypes: .sensitive, handle: nodeToMonitorHandle, isMarkedSensitive: false)])
        continuation.finish()
        
        await fulfillment(of: [yieldedExp, cancelledExp], timeout: 1.0)
        task.cancel()
    }
    
    private func makeSUT(
        nodeInRubbishBin: NodeEntity? = nil,
        node: NodeEntity? = nil,
        parentNode: NodeEntity? = nil,
        parents: [NodeEntity] = [],
        children: [NodeEntity] = [],
        isInheritingSensitivityResult: Result<Bool, Error> = .failure(GenericErrorEntity()),
        isInheritingSensitivityResults: [NodeEntity: Result<Bool, Error>] = [:],
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) -> SensitiveNodeUseCase<MockNodeRepository> {
        let mockNodeRepository = MockNodeRepository(
            node: node,
            rubbishBinNode: nodeInRubbishBin,
            childrenNodes: children,
            parentNodes: parents,
            isInheritingSensitivityResult: isInheritingSensitivityResult,
            isInheritingSensitivityResults: isInheritingSensitivityResults,
            nodeUpdates: nodeUpdates
        )
        return SensitiveNodeUseCase(
            nodeRepository: mockNodeRepository)
    }
}
