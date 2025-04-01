@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeActionViewModelTests: XCTestCase {

    func testIsHidden_hiddenNodeFeatureOffIrrespectiveOfNodesSharedOrBackup_shouldReturnNil() async {
        let node = NodeEntity(handle: 65, isMarkedSensitive: true)
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
        let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let result = await sut.isHidden([node], isFromSharedItem: Bool.random(), containsBackupNode: Bool.random())
        XCTAssertNil(result)
    }
    
    func testIsHidden_invalidAccount_shouldReturnFalse() async throws {
        let nodes = makeSensitiveNodes(count: 100)
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        
        XCTAssertFalse(try XCTUnwrap(result))
    }
    
    func testIsHidden_nodesContainsOnlySensitiveNodes_shouldReturnTrue() async throws {
        let nodes = makeSensitiveNodes(count: 100)
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        
        XCTAssertTrue(try XCTUnwrap(result))
    }
    
    func testIsHidden_nodesContainsNodeNotMarkedAsSensitive_shouldReturnFalse() async throws {
        var nodes = makeSensitiveNodes(count: 100)
        nodes.append(NodeEntity(handle: HandleEntity(nodes.count + 1), isMarkedSensitive: false))
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        
        XCTAssertFalse(try XCTUnwrap(result))
    }
    
    func testIsHidden_isFromSharedItemIsTrue_shouldReturnNil() async throws {
        for await isMarkedSensitive in [true, false].async {
            let node = NodeEntity(handle: 65, isMarkedSensitive: isMarkedSensitive)
            let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
            let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
            let result = await sut.isHidden([node], isFromSharedItem: true, containsBackupNode: false)
            XCTAssertNil(result)
        }
    }
    
    func testIsHidden_nodesEmpty_shouldReturnNil() async throws {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
        )
        let result = await sut.isHidden([], isFromSharedItem: false, containsBackupNode: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainNodeThatInheritSensitivity_shouldReturnNil() async throws {
        let nodeNotSensitive = NodeEntity(handle: 1, isMarkedSensitive: false)
        let nodeInheritingSensitivity = NodeEntity(handle: 2, isMarkedSensitive: false)
        let nodes = [nodeNotSensitive, nodeInheritingSensitivity]
        let isInheritingSensitivityResults: [HandleEntity: Result<Bool, any Error>] = [
            nodeNotSensitive.handle: .success(false),
            nodeInheritingSensitivity.handle: .success(true)
        ]
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResults: isInheritingSensitivityResults)
        
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase
        )
        let result = await sut.isHidden(nodes, isFromSharedItem: false, containsBackupNode: false)
        XCTAssertNil(result)
    }
    
    func testIsHidden_nodesContainBackupNode_shouldReturnNil() async {
        let node = NodeEntity(handle: 1)
        let sut = makeSUT()
        
        let isHidden = await sut.isHidden([node], isFromSharedItem: false, containsBackupNode: true)
        
        XCTAssertNil(isHidden)
    }

    func testHasValidProOrUnexpiredBusinessAccount_onAccountValidity_shouldReturnCorrectResult() {
        [true, false]
            .enumerated()
            .forEach { (index, isAccessible) in
                let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: isAccessible)
                
                let sut = makeSUT(sensitiveNodeUseCase: sensitiveNodeUseCase)
                
                XCTAssertEqual(sut.hasValidProOrUnexpiredBusinessAccount, isAccessible,
                               "failed at index: \(index) for expected: \(isAccessible)")
            }
    }
    
    func testIsSensitive_whenFeatureFlagDisabled_shouldReturnFalse() async {
        // given
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
        let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertFalse(isSenstive)
    }
    
    func testIsSensitive_featureFlagOff_shouldReturnFalse() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false])
        let sut = makeSUT(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        let isSenstive = await sut.isSensitive(node: node)
        
        XCTAssertFalse(isSenstive)
    }
    
    func testIsSensitive_invalidAccount_shouldReturnFalse() async {
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        let isSenstive = await sut.isSensitive(node: node)
        
        XCTAssertFalse(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndNodeIsSensitive_shouldReturnTrue() async {
        // given
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let node = NodeEntity(handle: 1, isMarkedSensitive: true)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    func testIsSensitive_whenFeatureFlagEnabledAndParentNodeIsSensitive_shouldReturnTrue() async {
        // given
        let remoteFeatureFlagUseCase = MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let node = NodeEntity(handle: 1, isMarkedSensitive: false)
        
        // when
        let isSenstive = await sut.isSensitive(node: node)
        
        // then
        XCTAssertTrue(isSenstive)
    }
    
    private func makeSUT(
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(nodesForLocation: [:]),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        maxDetermineSensitivityTasks: Int = 10,
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase()
    ) -> NodeActionViewModel {
        NodeActionViewModel(
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            maxDetermineSensitivityTasks: maxDetermineSensitivityTasks,
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
    }
    
    private func makeSensitiveNodes(count: Int = 5) -> [NodeEntity] {
        (0..<count).map {
            NodeEntity(handle: HandleEntity($0), isMarkedSensitive: true)
        }
    }
}
