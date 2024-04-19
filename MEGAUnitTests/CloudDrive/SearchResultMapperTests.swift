@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
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

    func testSwipeActionRestore_whenInvoked_shouldNotInvokePopView() {
        let exp = expectation(description: "Wait for pop view to be called")
        let nodeActions = NodeActions(
            nodeDownloader: { _ in },
            editTextFile: { _ in },
            shareOrManageLink: { _ in },
            showNodeInfo: { _ in },
            assignLabel: { _ in },
            toggleNodeFavourite: { _ in },
            sendToChat: { _ in },
            saveToPhotos: { _ in },
            exportFiles: { _, _  in },
            browserAction: { _, _ in },
            userProfileOpener: { _ in },
            removeLink: { _ in },
            removeSharing: { _ in },
            rename: { _, _ in },
            shareFolders: { _ in },
            leaveSharing: { _ in },
            manageShare: { _ in },
            showNodeVersions: { _ in },
            disputeTakedown: { _ in },
            moveToRubbishBin: { _ in },
            restoreFromRubbishBin: { _, shouldPopView in
                if !shouldPopView {
                    exp.fulfill()
                }
            },
            removeFromRubbishBin: { _ in }
        )
        let sut = makeSUT(
            nodeUseCase: MockNodeDataUseCase(
                nodeAccessLevelVariable: .owner,
                isNodeInRubbishBin: { nodeHandle in
                    return nodeHandle == 100 ? true : false
                },
                isNodeRestorable: true
            ),
            nodeActions: nodeActions
        )
        let searchResult = sut.map(node: NodeEntity(handle: 100, restoreParentHandle: 101))
        let swipeActions = searchResult.swipeActions(.cloudDrive)
        swipeActions.first?.action()
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Private methods

    private typealias SUT = SearchResultMapper

    private func makeSUT(
        sdk: MEGASdk = MockSdk(),
        nodeIconUsecase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
        nodeDetailUseCase: some NodeDetailUseCaseProtocol = MockNodeDetailUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        nodeActions: NodeActions = .makeActions(sdk: MockSdk(), navigationController: .init())
    ) -> SUT {
        .init(
            sdk: sdk,
            nodeIconUsecase: nodeIconUsecase,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            mediaUseCase: mediaUseCase, 
            nodeActions: nodeActions
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
