@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Search
import SwiftUI
import XCTest

final class SearchResultMapperTests: XCTestCase {

    func testSwipeActions_withNodeAccessLevelRead_shouldReturnSwipeActionsAsEmpty() {
        assertSwipeActions(accessLevel: .read, expectedSwipeActionsCount: 0)
    }

    func testSwipeActions_withViewModeHomeScreen_shouldReturnSwipeActionsAsEmpty() {
        assertSwipeActions(displayMode: .home, accessLevel: .owner, expectedSwipeActionsCount: 0)
    }

    func testSwipeActions_withRestoreOption_whenTheNodeIsInRubbishBin() {
        assertSwipeActions(
            nodeEntity: NodeEntity(handle: 100, restoreParentHandle: 101),
            isNodeInRubbishBin: { nodeHandle in
                return nodeHandle == 100 ?  true : false
            },
            expectedSwipeActionsCount: 1,
            expectedSwipeActionImages: [Image(.restore)]
        )
    }

    func testSwipeActions_withNodeInCloudDrive_shouldReturnMultipleActions() {
        assertSwipeActions(
            expectedSwipeActionsCount: 3,
            expectedSwipeActionImages: [Image(.rubbishBin), Image(.link), Image(.offline)]
        )
    }

    func testSwipeActions_withNodeInBackup_shouldReturnMultipleActions() {
        assertSwipeActions(
            displayMode: .backup,
            expectedSwipeActionsCount: 2,
            expectedSwipeActionImages: [Image(.link), Image(.offline)]
        )
    }

    func testSwipeActions_whenNodeIsChildNodeOfParentNodeInRubbishBin_shouldReturnSwipeActionsAsEmpty() {
        assertSwipeActions(
            isNodeInRubbishBin: { _ in true },
            isNodeRestorable: false,
            expectedSwipeActionsCount: 0
        )
    }

    func testProperties_whenFolderIsDownloaded_propertiesShouldContainDownload() {
        let nodeUseCase = MockNodeDataUseCase(downloaded: true)
        let sut = makeSUT(nodeUseCase: nodeUseCase)
        let node = NodeEntity(isFolder: true)
        let result = sut.map(node: node)
        XCTAssertTrue(result.properties.contains(.downloaded))
    }
    
    func test_isSensitive_whenHiddenNodesFeatureIsOff_shouldReturnFalse() {
        // given
        let sut = makeSUT(hiddenNodesFeatureEnabled: false)
        
        // when
        let node = NodeEntity(isMarkedSensitive: true)
        let result = sut.map(node: node)
        
        // then
        XCTAssertFalse(result.isSensitive)
    }
    
    func test_isSensitive_whenInvalidAccount_shouldReturnFalse() {
        // given
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: false),
            hiddenNodesFeatureEnabled: true)
        
        // when
        let node = NodeEntity(isMarkedSensitive: true)
        let result = sut.map(node: node)
        
        // then
        XCTAssertFalse(result.isSensitive)
    }
    
    func test_isSensitive_whenHiddenNodesFeatureIsOnAndNodeIsSensitive_shouldReturnTrue() {
        // given
        let sut = makeSUT(
            sensitiveNodeUseCase: MockSensitiveNodeUseCase(isAccessible: true),
            hiddenNodesFeatureEnabled: true)
        
        // when
        let node = NodeEntity(isMarkedSensitive: true)
        let result = sut.map(node: node)
        
        // then
        XCTAssertTrue(result.isSensitive)
    }
    
    func test_isSensitive_whenHiddenNodesFeatureIsOnAndNodeParentIsSensitive_shouldReturnTrue() {
        // given
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(true))
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            hiddenNodesFeatureEnabled: true
        )
        
        // when
        let node = NodeEntity(isMarkedSensitive: false)
        let result = sut.map(node: node)
        
        // then
        XCTAssertTrue(result.isSensitive)
    }
    
    func test_isSensitive_whenHiddenNodesFeatureIsOnAndNodeParentIsNotSensitive_shouldReturnFalse() {
        // given
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .success(false))
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            hiddenNodesFeatureEnabled: true)
        
        // when
        let node = NodeEntity(isMarkedSensitive: false)
        let result = sut.map(node: node)
        
        // then
        XCTAssertFalse(result.isSensitive)
    }
    
    func test_isSensitive_whenIsInheritingSensitivityThrowError_shouldReturnFalse() {
        // given
        let sensitiveNodeUseCase = MockSensitiveNodeUseCase(
            isAccessible: true,
            isInheritingSensitivityResult: .failure(GenericErrorEntity()))
        let sut = makeSUT(
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            hiddenNodesFeatureEnabled: true)
        
        // when
        let node = NodeEntity(isMarkedSensitive: false)
        let result = sut.map(node: node)
        
        // then
        XCTAssertFalse(result.isSensitive)
    }

    // MARK: - Private methods

    private typealias SUT = SearchResultMapper

    private func makeSUT(
        sdk: MEGASdk = MockSdk(),
        nodeIconUsecase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
        nodeDetailUseCase: some NodeDetailUseCaseProtocol = MockNodeDetailUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol = MockSensitiveNodeUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        nodeActions: NodeActions = .makeActions(sdk: MockSdk(), navigationController: .init()),
        hiddenNodesFeatureEnabled: Bool = true
    ) -> SUT {
        .init(
            sdk: sdk,
            nodeIconUsecase: nodeIconUsecase,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            sensitiveNodeUseCase: sensitiveNodeUseCase,
            mediaUseCase: mediaUseCase,
            nodeActions: nodeActions,
            hiddenNodesFeatureEnabled: hiddenNodesFeatureEnabled
        )
    }

    private func assertSwipeActions(
        displayMode: ViewDisplayMode = .cloudDrive,
        accessLevel: NodeAccessTypeEntity = .owner,
        nodeEntity: NodeEntity = NodeEntity(),
        isNodeInRubbishBin: @escaping (HandleEntity) -> Bool = { _ in false },
        isNodeRestorable: Bool = true,
        expectedSwipeActionsCount: Int,
        expectedSwipeActionImages: [Image] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(
            nodeUseCase: MockNodeDataUseCase(
                nodeAccessLevelVariable: accessLevel,
                isNodeInRubbishBin: isNodeInRubbishBin,
                isNodeRestorable: isNodeRestorable
            )
        )
        let searchResult = sut.map(node: nodeEntity)
        let swipeActions = searchResult.swipeActions(displayMode)
        XCTAssertEqual(swipeActions.count, expectedSwipeActionsCount, file: file, line: line)
        XCTAssertEqual(swipeActions.map { $0.image }, expectedSwipeActionImages, file: file, line: line)
    }
}
