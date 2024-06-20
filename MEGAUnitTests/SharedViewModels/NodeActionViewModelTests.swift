@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testIsHidden_hiddenNodeFeatureOff_shouldReturnNil() async {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let result = await sut.isHidden([node], isFromSharedItem: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainsOnlySensitiveNodes_shouldReturnTrue() async throws {
        let nodes = makeSensitiveNodes(count: 100)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false)
        
        XCTAssertTrue(try XCTUnwrap(result))
    }
    
    func testIsHidden_nodesContainsNodeNotMarkedAsSensitive_shouldReturnFalse() async throws {
        var nodes = makeSensitiveNodes(count: 100)
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false)
        
        XCTAssertFalse(try XCTUnwrap(result))
    }
    
    func testIsHidden_isFromSharedItemIsTrue_shouldReturnNil() async throws {
        for await isMarkedSensitive in [true, false].async {
            let node = NodeEntity(handle: 65, isMarkedSensitive: isMarkedSensitive)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            let result = await sut.isHidden([node], isFromSharedItem: true)
            XCTAssertNil(result)
        }
    }
    
    func testIsHidden_nodeIsSystemManaged_shouldReturnNil() async throws {
        let systemNode = NodeEntity(handle: 65)
        let nodes = [
            systemNode,
            NodeEntity(handle: 66, isMarkedSensitive: true)
        ]
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                nodesForLocation: [.cameraUpload: systemNode]),
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden(nodes, isFromSharedItem: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodeIsSystemManagedAndErrorWasThrown_shouldReturnNil() async throws {
        
        let errors: [any Error] = [
            GenericErrorEntity(),
            CancellationError()
        ]
        
        for await error in errors.async {
            let systemNode = NodeEntity(handle: 65)
            let nodes = [
                systemNode,
                NodeEntity(handle: 66, isMarkedSensitive: true)
            ]
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(
                systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                    nodesForLocation: [.cameraUpload: systemNode],
                    containsSystemGeneratedNodeError: error),
                featureFlagProvider: featureFlagProvider
            )
            let result = await sut.isHidden(nodes, isFromSharedItem: false)
            XCTAssertNil(result)
        }
    }
    
    func testIsHidden_nodesEmpty_shouldReturnNil() async throws {
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden([], isFromSharedItem: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainNodeThatInheritSensitivity_shouldReturnNil() async throws {
        let nodeNotSensitive = NodeEntity(handle: 1, isMarkedSensitive: false)
        let nodeInheritingSensitivity = NodeEntity(handle: 2, isMarkedSensitive: false)
        let nodes = [nodeNotSensitive, nodeInheritingSensitivity]
        let isInheritingSensitivityResults: [HandleEntity: Result<Bool, Error>] = [
            nodeNotSensitive.handle: .success(false),
            nodeInheritingSensitivity.handle: .success(true)
        ]
        let nodeUseCase = MockNodeDataUseCase(
            isInheritingSensitivityResults: isInheritingSensitivityResults)
        
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider
        )
        let result = await sut.isHidden(nodes, isFromSharedItem: false)
        XCTAssertNil(result)
    }

    func testHasValidProOrUnexpiredBusinessAccount_onAccountValidity_shouldReturnCorrectResult() {
        [true, false]
            .enumerated()
            .forEach { (index, isValid) in
                let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: isValid)
                
                let sut = makeSUT(accountUseCase: accountUseCase)
                
                XCTAssertEqual(sut.hasValidProOrUnexpiredBusinessAccount, isValid,
                               "failed at index: \(index) for expected: \(isValid)")
            }
    }
    
    func testIsSensitive_whenFeatureFlagDisabled_shouldReturnFalse() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertFalse(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndNodeIsSensitive_shouldReturnTrue() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndParentNodeIsSensitive_shouldReturnTrue() async {
        // given
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(nodeUseCase: nodeUseCase, featureFlagProvider: featureFlagProvider)
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        maxDetermineSensitivityTasks: Int = 10,
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks,
            featureFlagProvider: featureFlagProvider)
    }
    
    private func makeSensitiveNodes(count: Int = 5) -> [NodeEntity] {
        (0..<count).map {
            NodeEntity(handle: HandleEntity($0), isMarkedSensitive: true)
        }
    }
}
