@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class CloudDriveViewControllerNavItemsFactoryTests: XCTestCase {

    func testMakeNavItems_whenNodeSourceIsRecentBucketAction_shouldReturnEmpty() async {
        let sut = makeSUT(nodeSource: .recentActionBucket(.init()))
        await assert(sut: sut)
    }

    func testMakeNavItems_whenNodeIsNil_shouldReturnEmpty() async {
        let sut = makeSUT()
        await assert(sut: sut)
    }

    func testMakeNavItems_whenIsViewFromFolderIsTrue_shouldReturnOnlyMoreButton() async {
        await assert(config: .init(isFromViewInFolder: true), rightNavBarImage: UIImage.moreNavigationBar)
    }

    func testMakeNavItems_whenDisplayModeRubbishBin_shouldReturnEmptyRightBurButtons() async {
        await assert(config: .init(displayMode: .rubbishBin), rightNavBarImage: nil)
    }

    func testMakeNavItems_whenDisplayModeBackup_shouldReturnOnlyMoreButton() async {
        await assert(config: .init(displayMode: .backup), rightNavBarImage: UIImage.moreNavigationBar)
    }

    func testMakeNavItems_whenInCloudDrive_shouldReturnAddAndMoreButtons() async {
        let sut = makeSUT(
            nodeSource: .node { NodeEntity() }, config: .init(displayMode: .cloudDrive, isFromViewInFolder: false)
        )
        await assert(
            sut: sut,
            expectedNavItems: .init(
                leftBarButtonItem: nil,
                rightNavBarItems: [
                    .init(image: UIImage.navigationbarAdd),
                    .init(image: UIImage.moreNavigationBar)
                ]
            )
        )
    }

    // MARK: - Private methods

    private typealias SUT = CloudDriveViewControllerNavItemsFactory

    private func makeSUT(
        nodeSource: NodeSource = .node { nil },
        config: NodeBrowserConfig = .default,
        currentViewMode: ViewModePreferenceEntity = .list,
        contextMenuManager: ContextMenuManager = .init(
            createContextMenuUseCase: MockCreateContextMenuUseCase()
        ),
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory = .init(
            backupsUseCase: MockBackupsUseCase(),
            nodeUseCase: MockNodeDataUseCase()
        ),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        isSelectionHidden: Bool = false
    ) -> SUT {
        SUT(
            nodeSource: nodeSource,
            config: config,
            currentViewMode: currentViewMode,
            contextMenuManager: contextMenuManager,
            contextMenuConfigFactory: contextMenuConfigFactory,
            nodeUseCase: nodeUseCase,
            isSelectionHidden: isSelectionHidden
        )
    }

    private func assert(
        config: NodeBrowserConfig,
        rightNavBarImage: UIImage?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let sut = makeSUT(nodeSource: .node { NodeEntity() }, config: config)

        let rightNavBarItems: [UIBarButtonItem]
        if let rightNavBarImage {
            rightNavBarItems = await [.init(image: rightNavBarImage)]
        } else {
            rightNavBarItems = []
        }

        await assert(
            sut: sut,
            expectedNavItems: .init(
                leftBarButtonItem: nil,
                rightNavBarItems: rightNavBarItems
            )
        )
    }

    private func assert(
        sut: SUT,
        expectedNavItems: SUT.NavItems = .empty,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let navItems = await sut.makeNavItems()
        XCTAssertEqual(navItems.leftBarButtonItem, expectedNavItems.leftBarButtonItem, file: file, line: line)
        for index in (0..<expectedNavItems.rightNavBarItems.count) {
            let expectedImage = await expectedNavItems.rightNavBarItems[index].image
            let actualImage = await navItems.rightNavBarItems[index].image
            XCTAssertEqual(expectedImage, actualImage, file: file, line: line)
        }
    }
}
