import MEGADomain
import MEGADomainMock
import MEGASwift
import Testing
import XCTest

final class SensitiveNodeUseCaseTests: XCTestCase {

    func testIsInheritingSensitivity_validNode_shouldReturnCorrectSensitivityStatus() async throws {
        let expectedSensitiveStatus = true

        let sut = makeSUT(isInheritingSensitivityResult: .success(expectedSensitiveStatus),
                          hasValidProOrUnexpiredBusinessAccount: true)
        
        let isSensitive = try await sut.isInheritingSensitivity(node: NodeEntity(handle: 1))
        
        XCTAssertEqual(isSensitive, expectedSensitiveStatus)
    }
    
    func testMonitorInheritedSensitivity_nonFolderUpdates_shouldNotYieldAnything() async throws {
        let nodeUpdates = [NodeEntity(handle: 1, isFile: true, isFolder: false)]
        let nodeUpdateAsyncSequence = SingleItemAsyncSequence(item: nodeUpdates)
            .eraseToAnyAsyncSequence()

        let sut = makeSUT(nodeUpdates: nodeUpdateAsyncSequence,
                          hasValidProOrUnexpiredBusinessAccount: true)
        
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
            nodeUpdates: nodeUpdateAsyncSequence,
            hasValidProOrUnexpiredBusinessAccount: true)
        
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
            nodeUpdates: stream.eraseToAnyAsyncSequence(),
            hasValidProOrUnexpiredBusinessAccount: true)
        
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
        let sut = makeSUT(nodeUpdates: stream.eraseToAnyAsyncSequence(),
                          hasValidProOrUnexpiredBusinessAccount: true)
        
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
    
    func testFolderSensitivityChanged_onFolderSensitivityChanged_shouldYield() async {
        let (stream, continuation) = AsyncStream.makeStream(of: [NodeEntity].self)
        let sut = makeSUT(nodeUpdates: stream.eraseToAnyAsyncSequence(),
                          hasValidProOrUnexpiredBusinessAccount: true)
        
        let startedExp = expectation(description: "Task started")
        let yieldedExp = expectation(description: "Task yielded")
        let cancelledExp = expectation(description: "Async Sequence stopped")
        let task = Task {
            startedExp.fulfill()
            for await _ in sut.folderSensitivityChanged() {
                yieldedExp.fulfill()
            }
            cancelledExp.fulfill()
        }
        await fulfillment(of: [startedExp], timeout: 0.25)
        
        continuation.yield([NodeEntity(changeTypes: .sensitive, handle: 1, isFolder: false)])
        continuation.yield([NodeEntity(changeTypes: .sensitive, handle: 1, isFolder: true)])
        continuation.yield([NodeEntity(changeTypes: .new, handle: 1, isFolder: true)])
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
        nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        hasValidProOrUnexpiredBusinessAccount: Bool = false
    ) -> SensitiveNodeUseCase<MockNodeRepository, MockAccountUseCase> {
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
            nodeRepository: mockNodeRepository,
            accountUseCase: MockAccountUseCase(
                currentAccountDetails: .build(proLevel: hasValidProOrUnexpiredBusinessAccount ? .proI : .free),
                hasValidProOrUnexpiredBusinessAccount: hasValidProOrUnexpiredBusinessAccount
            ))
    }
}

@Suite("SensitiveNodeUseCaseTests")
struct SensitiveNodeUseCaseSuite {
    
    @Suite("calls isAccessible")
    struct CallIsAccessible {
        
        private static let featureAccessibleAccountTypes: [AccountTypeEntity] = [
            .lite,
            .proI,
            .proII,
            .proIII,
            .proFlexi,
            .starter,
            .basic,
            .essential,
            .business
        ]
        
        /// Provide arguments ensuring that when new cases are added, the test for invalid cases will pick it up.
        /// - Returns: List of AccountTypeEntity to args
        private static func invalidProAccountTypesArgument() -> [AccountTypeEntity?] {
            AccountTypeEntity.allCases.filter { featureAccessibleAccountTypes.notContains($0) } + [nil]
        }
                
        @Test("when user has valid account type, expect true", arguments: featureAccessibleAccountTypes)
        func whenUserHasValidProAccountTypes(accountType: AccountTypeEntity) async throws {
            let sut = makeSUT(
                accountUseCase: MockAccountUseCase(
                    currentAccountDetails: .build(proLevel: accountType),
                    hasValidProOrUnexpiredBusinessAccount: true))
            #expect(sut.isAccessible() == true)
        }
        
        @Test("when user has an invalid account type, expect false", arguments: invalidProAccountTypesArgument())
        func whenUserHasProAccountTypes(accountType: AccountTypeEntity?) async throws {
            let currentAccountDetails: AccountDetailsEntity? = if let accountType { .build(proLevel: accountType) } else { nil }
            let sut = makeSUT(
                accountUseCase: MockAccountUseCase(
                    currentAccountDetails: currentAccountDetails,
                    hasValidProOrUnexpiredBusinessAccount: false))
            #expect(sut.isAccessible() == false)
        }
    }

    @Suite("Invalid pro or expired business account")
    struct InvalidAccount {
        private let node = NodeEntity(handle: 43)
        
        @Test("Inherit sensitivity should always return false for invalid account",
              arguments: [true, false])
        func isInheritingSensitivity(isInheritingSensitivity: Bool) async throws {
            let sut = InvalidAccount.makeSUT(
                isInheritingSensitivityResult: .success(isInheritingSensitivity))
            
            #expect(try await sut.isInheritingSensitivity(node: node) == false)
        }
        
        @Test("Inherit sensitivity (sync) should always return false for invalid account",
              arguments: [true, false])
        func inheritingSensitivity(isInheritingSensitivity: Bool) throws {
            let sut = InvalidAccount.makeSUT(
                isInheritingSensitivityResult: .success(isInheritingSensitivity))
            
            #expect(try sut.isInheritingSensitivity(node: node) == false)
        }
        
        @Test("Monitor sensitivity should always return nil for invalid")
        func monitorInheritedSensitivity() async throws {
            var iterator = InvalidAccount.makeSUT()
                .monitorInheritedSensitivity(for: node)
                .makeAsyncIterator()
                
            #expect(try await iterator.next() == nil)
        }
        
        @Test("Sensitivity changes should always return nil for invalid account")
        func sensitivityChanges() async throws {
            var iterator = InvalidAccount.makeSUT()
                .sensitivityChanges(for: node)
                .makeAsyncIterator()
                
            #expect(await iterator.next() == nil)
        }
        
        @Test("inherited and direct sensitivity changes should always return nil for invalid account")
        func mergeInheritedAndDirectSensitivityChanges() async throws {
            var iterator = InvalidAccount.makeSUT()
                .mergeInheritedAndDirectSensitivityChanges(for: node)
                .makeAsyncIterator()
                
            #expect(try await iterator.next() == nil)
        }
        
        private static func makeSUT(
            isInheritingSensitivityResult: Result<Bool, Error> = .failure(GenericErrorEntity()),
            nodeUpdates: AnyAsyncSequence<[NodeEntity]> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
        ) -> SensitiveNodeUseCase<MockNodeRepository, MockAccountUseCase> {
            SensitiveNodeUseCaseSuite.makeSUT(
                nodeRepository: MockNodeRepository(
                    isInheritingSensitivityResult: isInheritingSensitivityResult,
                    nodeUpdates: nodeUpdates),
                accountUseCase: MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: false)
            )
        }
    }
    
    @Suite("Inherited sensitivity cache")
    struct InheritedSensitivityCache {
        let accountUseCase = MockAccountUseCase(
            currentAccountDetails: .build(proLevel: .proI),
            hasValidProOrUnexpiredBusinessAccount: true
        )
        
        @Test func emptyCacheWhenInheritedSensitivityMonitoringHasNotStarted() async throws {
            let sut = makeSUT(accountUseCase: accountUseCase)
            #expect(sut.cachedInheritedSensitivity(for: 1) == nil)
        }
        
        @Test func cacheAvailableWhenInheritedSensitivityMonitoringHasStarted() async throws {
            let nodeEntity = NodeEntity(handle: 1)
            
            let nodeRepository = MockNodeRepository(
                isInheritingSensitivityResults: [nodeEntity: .success(true)]
            )
            let sut = makeSUT(nodeRepository: nodeRepository, accountUseCase: accountUseCase)
            
            _ = try await sut.isInheritingSensitivity(node: nodeEntity)
            
            #expect(sut.cachedInheritedSensitivity(for: 1) == true)
        }
        
        @Test func emptyCacheUponLogout() async throws {
            let nodeEntity = NodeEntity(handle: 1)
            
            let nodeRepository = MockNodeRepository(
                isInheritingSensitivityResults: [nodeEntity: .success(true)]
            )
            let sut = makeSUT(nodeRepository: nodeRepository, accountUseCase: accountUseCase)
            
            _ = try await sut.isInheritingSensitivity(node: nodeEntity)
            
            #expect(sut.cachedInheritedSensitivity(for: 1) == true)
            
            NotificationCenter.default.post(name: .accountDidLogout, object: nil)
            
            #expect(sut.cachedInheritedSensitivity(for: 1) == nil)
        }
    }
    
    private static func makeSUT(
        nodeRepository: MockNodeRepository = MockNodeRepository(),
        accountUseCase: MockAccountUseCase = MockAccountUseCase()
    ) -> SensitiveNodeUseCase<MockNodeRepository, MockAccountUseCase> {
        SensitiveNodeUseCase(
            nodeRepository: nodeRepository,
            accountUseCase: accountUseCase)
    }
}
