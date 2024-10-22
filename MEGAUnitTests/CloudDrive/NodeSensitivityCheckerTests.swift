@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class NodeSensitivityCheckerTests: XCTestCase {

    func testEvaluateNodeSensitivity_whenFeatureIsDisabled_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: false]),
            nodeSource: .testNode,
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenInvokedFromSharedItem_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            nodeSource: .testNode,
            displayMode: .cloudDrive,
            isFromSharedItem: true
        )
    }

    func testEvaluateNodeSensitivity_whenDisplayModeOtherThanCloudDrive_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            nodeSource: .testNode,
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenParentNodeIsNil_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { nil },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenNodeIsRoot_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { NodeEntity(parentHandle: .invalid) },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenNodeIsAFile_shouldReturnNil() async {
        await assertEvaluateNodeSensitivityResultForNil(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            nodeSource: NodeSource.node { NodeEntity(isFile: true, isFolder: false) },
            displayMode: .sharedItem,
            isFromSharedItem: false
        )
    }

    func testEvaluateNodeSensitivity_whenInvokedByFreeUser_shouldReturnNil() async {
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: false)
        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { NodeEntity(isFolder: true) },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }

    func testEvaluateNodeSensitivity_forSystemGeneratedNode_shouldReturnNil() async {
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true)
        let node = NodeEntity(isFolder: true)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [.cameraUpload: node])
        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    func testEvaluateNodeSensitivity_whenInheritingSensitivityTrueOrFailed_shouldReturnNil() async {
        let inheritSensitiveResults: [Result<Bool, any Error>] = [.success(true), .failure(GenericErrorEntity())]
        for inheritSensitiveResult in inheritSensitiveResults {
            let node = NodeEntity(isFolder: true)
            let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
            let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
                isAccessible: true,
                isInheritingSensitivityResult: inheritSensitiveResult)
            let sut = makeSUT(
                remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
                systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
                sensitiveNodeUseCase: sensitiveNodeUseCase
            )
            let result = await sut.evaluateNodeSensitivity(
                for: NodeSource.node { node },
                displayMode: .cloudDrive,
                isFromSharedItem: false
            )
            XCTAssertNil(result, "Failed for inherited result \(inheritSensitiveResult)")
        }
    }

    func testEvaluateNodeSensitivity_whenSystemGeneratedNodeThrowingError_shouldReturnNil() async {
        let node = NodeEntity(isFolder: true)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(
            containsSystemGeneratedNodeError: NSError(domain: "", code: 0)
        )
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true)
        
        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    func testEvaluateNodeSensitivity_ForSensitiveNode_shouldReturnNodeAsSensitive() async {
        let node = NodeEntity(isFolder: true, isMarkedSensitive: false)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(false))

        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }

    func testEvaluateNodeSensitivity_ForInSensitiveNode_shouldReturnNodeAsInSensitive() async {
        let node = NodeEntity(isFolder: true, isMarkedSensitive: false)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(nodesForLocation: [:])
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(false))

        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { node },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertEqual(result, false)
    }
    
    func testEvaluateNodeSensitivity_whenSystemGeneratedNodeInvalidAccount_shouldReturnNil() async {
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(isAccessible: false)
        let systemNode = NodeEntity(isFolder: true, isMarkedSensitive: false)
        let systemGeneratedNodeUseCase = MockSystemGeneratedNodeUseCase(
            nodesForLocation: [.cameraUpload: systemNode])

        let sut = makeSUT(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: true]),
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
        let result = await sut.evaluateNodeSensitivity(
            for: NodeSource.node { systemNode },
            displayMode: .cloudDrive,
            isFromSharedItem: false
        )
        XCTAssertNil(result)
    }

    // MARK: - Helpers

    private func makeSUT(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol = MockRemoteFeatureFlagUseCase(),
        systemGeneratedNodeUseCase: some SystemGeneratedNodeUseCaseProtocol = MockSystemGeneratedNodeUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase()
    ) -> NodeSensitivityChecker {
        .init(
            remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
            systemGeneratedNodeUseCase: systemGeneratedNodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase
        )
    }

    private func assertEvaluateNodeSensitivityResultForNil(
        remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol,
        nodeSource: NodeSource,
        displayMode: DisplayMode,
        isFromSharedItem: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(remoteFeatureFlagUseCase: remoteFeatureFlagUseCase)
        let result = await sut.evaluateNodeSensitivity(
            for: nodeSource,
            displayMode: displayMode,
            isFromSharedItem: isFromSharedItem
        )
        XCTAssertNil(result, file: file, line: line)
    }
}
