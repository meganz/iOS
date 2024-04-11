@testable import MEGA
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

    // MARK: - Private methods

    private typealias SUT = SearchResultMapper

    private func makeSUT(
        sdk: MEGASdk = MEGASdk.sharedSdk,
        nodeIconUsecase: some NodeIconUsecaseProtocol = MockNodeIconUsecase(stubbedIconData: Data()),
        nodeDetailUseCase: some NodeDetailUseCaseProtocol = MockNodeDetailUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase()
    ) -> SUT {
        .init(
            sdk: sdk,
            nodeIconUsecase: nodeIconUsecase,
            nodeDetailUseCase: nodeDetailUseCase,
            nodeUseCase: nodeUseCase,
            mediaUseCase: mediaUseCase, 
            nodeActions: .makeActions(sdk: sdk, navigationController: .init())
        )
    }

    private func assertSwipeActions(
        displayMode: ViewDisplayMode = .cloudDrive,
        accessLevel: NodeAccessTypeEntity = .owner,
        nodeEntity: NodeEntity = NodeEntity(),
        isNodeInRubbishBin: @escaping (HandleEntity) -> Bool = { _ in false },
        expectedSwipeActionsCount: Int,
        expectedSwipeActionImages: [Image] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(
            nodeUseCase: MockNodeDataUseCase(
                nodeAccessLevelVariable: accessLevel,
                isNodeInRubbishBin: isNodeInRubbishBin
            )
        )
        let searchResult = sut.map(node: nodeEntity)
        let swipeActions = searchResult.swipeActions(displayMode)
        XCTAssertEqual(swipeActions.count, expectedSwipeActionsCount, file: file, line: line)
        XCTAssertEqual(swipeActions.map { $0.image }, expectedSwipeActionImages, file: file, line: line)
    }
}
