@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import XCTest

final class NodeSensitivityCheckerTests: XCTestCase {

    func testEvaluateNodeSensitivity_whenFeatureIsDisabled_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: false]),
            nodeSource: .testNode,
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenInvokedFromSharedItem_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            nodeSource: .testNode,
            displayMode: .cloudDrive,
            isFromSharedItem: true
        )
    }

    func testEvaluateNodeSensitivity_whenDisplayModeOtherThanCloudDrive_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            nodeSource: .testNode,
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenParentNodeIsNil_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { nil },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenNodeIsRoot_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { NodeEntity(parentHandle: .invalid) },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenNodeIsAFile_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { NodeEntity(isFile: true, isFolder: false) },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenInvokedByFreeUser_shouldReturnNil() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: false)
        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { NodeEntity(isFolder: true) },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }

    func testEvaluateNodeSensitivity_forSystemGeneratedNode_shouldReturnNil() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let node = NodeEntity(isFolder: true)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [.cameraUpload: node])
        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    func testEvaluateNodeSensitivity_whenInheritingSensitivityResult_shouldReturnNil() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let node = NodeEntity(isFolder: true)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .failure(GenericErrorEntity()))
        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    func testEvaluateNodeSensitivity_whenSystemGeneratedNodeThrowingError_shouldReturnNil() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let node = NodeEntity(isFolder: true)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(
            containsSystemGeneratedNodeError: NSError(domain: "", code: 0)
        )
        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    func testEvaluateNodeSensitivity_ForSensitiveNode_shouldReturnNodeAsSensitive() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let node = NodeEntity(isFolder: true, isMarkedSensitive: false)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .success(false))

        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }

    func testEvaluateNodeSensitivity_ForInSensitiveNode_shouldReturnNodeAsInSensitive() async {
        let accountUseCase = MockAccountUseCase(hasValidProOrUnexpiredBusinessAccount: true)
        let node = NodeEntity(isFolder: true, isMarkedSensitive: false)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
        let nodeUseCase = MockNodeDataUseCase(isInheritingSensitivityResult: .success(false))

        let sut = makeSUT(
            featureFlagProvider: MockFeatureFlagProvider(list: [.hiddenNodes: true]),
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }

    // MARK: - Helpers

    private func makeSUT(
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [:]),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
    ) -> NodeSensitivityChecker {
        .init(
            featureFlagProvider: featureFlagProvider,
            accountUseCase: accountUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            nodeUseCase: nodeUseCase
        )
    }

    private func assertEvaluateNodeSensitivityResultForNil(
        featureFlagProvider: some FeatureFlagProviderProtocol,
        nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(featureFlagProvider: featureFlagProvider)
        let result = await sut.evaluateNodeSensitivity(
            for: nodeSource,
            displayMode: displayMode,
            isFromSharedItem: isFromSharedItem
        )
        XCTAssertNil(result, file: file, line: line)
    }
}
