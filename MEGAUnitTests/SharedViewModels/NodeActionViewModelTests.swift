@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testContainsOnlySensitiveNodes_hiddenNodeFeatureOff_shouldReturnNil() async {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: false])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let result = await sut.containsOnlySensitiveNodes([node], isFromSharedItem: false)
        XCTAssertNil(result)
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnTrue() async throws {
        let nodes = makeSensitiveNodes()
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = await sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false)
        
        XCTAssertTrue(try XCTUnwrap(containsOnlySensitiveNodes))
    }
    
    func testContainsOnlySensitiveNodes_nodesContainsOnlySensitiveNodes_shouldReturnFalse() async throws {
        var nodes = makeSensitiveNodes()
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        
        let containsOnlySensitiveNodes = await sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false)
        
        XCTAssertFalse(try XCTUnwrap(containsOnlySensitiveNodes))
    }
    
    func testContainsOnlySensitiveNodes_isFromSharedItemIsTrue_shouldReturnNil() async throws {
        for await isMarkedSensitive in [true, false].async {
            let node = NodeEntity(handle: 65, isMarkedSensitive: isMarkedSensitive)
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            let result = await sut.containsOnlySensitiveNodes([node], isFromSharedItem: true)
            XCTAssertNil(result)
        }
    }
    
    func testContainsOnlySensitiveNodes_nodeIsSystemManaged_shouldReturnExpectedResult() async throws {
        
        let situationResult: [(Bool, Bool?)] = [
            (true, true),
            (false, nil)
        ]
        
        for await (isMarkedSensitive, expectedResult) in situationResult.async {
            let systemNode = NodeEntity(handle: 65)
            let nodes = [
                systemNode,
                NodeEntity(handle: 66, isMarkedSensitive: isMarkedSensitive)
            ]
            let featureFlagProvider = MockFeatureFlagProvider(list: [.hiddenNodes: true])
            let sut = makeSUT(
                systemGeneratedNodeUseCase: MockSystemGeneratedNodeUseCase(
                    nodesForLocation: [.cameraUpload: systemNode]),
                featureFlagProvider: featureFlagProvider
            )
            let result = await sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false)
            XCTAssertEqual(result, expectedResult)
        }
    }
    
    func testContainsOnlySensitiveNodes_nodeIsSystemManagedAndErrorWasThrown_shouldReturnNil() async throws {
        
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
            let result = await sut.containsOnlySensitiveNodes(nodes, isFromSharedItem: false)
            XCTAssertNil(result)
        }
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
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:])
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase,
            featureFlagProvider: featureFlagProvider)
    }
    
    private func makeSensitiveNodes() -> [NodeEntity] {
        (0..<5).map {
            NodeEntity(handle: $0, isMarkedSensitive: true)
        }
    }
}
