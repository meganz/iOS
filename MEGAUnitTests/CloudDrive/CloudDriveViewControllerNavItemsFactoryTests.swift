@testable import MEGA
import MEGADomain
import MEGADomainMock
import SwiftUI
import XCTest

@MainActor
final class CloudDriveViewControllerNavItemsFactoryTests: XCTestCase {

    func testContextMenu_whenNodeSourceIsRecentBucketAction_shouldReturnNil() {
        let sut = makeSUT(nodeSource: .mockRecentActionBucketEmpty)
        assertContextMenu(sut: sut)
    }

    func testContextMenu_whenNodeIsNil_shouldReturnNil() {
        let sut = makeSUT()
        assertContextMenu(sut: sut)
    }

    func testContextMenu_whenAccessTypeIsNil_shouldReturnNil() {
        let sut = makeSUT()
        assertContextMenu(sut: sut, accessType: nil)
    }

    func testContextMenu_whenTheCaseIsValid_shouldNotBeNil() {
        let sut = makeSUT(
            nodeSource: .node { .init() },
            nodeUseCase: MockNodeDataUseCase(nodes: [.init()])
        )
        let contextMenu = sut.contextMenu { EmptyView() }
        XCTAssertNotNil(contextMenu)
    }

    func testAddMenu_whenIsViewFromFolderIsTrue_shouldReturnNil() {
        let sut = makeSUT(
            config: .init(isFromViewInFolder: true))
        assertAddMenu(sut: sut)
    }

    func testAddMenu_whenDisplayModeRubbishBin_shouldReturnNil() {
        let sut = makeSUT(config: .init(displayMode: .rubbishBin))
        assertAddMenu(sut: sut)
    }

    func testAddMenu_whenDisplayModeBackup_shouldReturnNil() {
        let sut = makeSUT(config: .init(displayMode: .backup))
        assertAddMenu(sut: sut)
    }

    func testAddMenu_whenAccessTypeIsUnknown_shouldReturnNil() {
        let sut = makeSUT(
            config: .init(displayMode: .cloudDrive, isFromViewInFolder: false),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .unknown)
        )
        assertAddMenu(sut: sut)
    }

    func testAddMenu_whenAccessTypeIsRead_shouldReturnNil() {
        let sut = makeSUT(
            config: .init(displayMode: .cloudDrive, isFromViewInFolder: false),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .read)
        )
        assertAddMenu(sut: sut)
    }

    func testAddMenu_whenTheCaseIsValid_shouldNotBeNil() {
        let sut = makeSUT(
            nodeSource: .node { .init() },
            config: .init(displayMode: .cloudDrive, isFromViewInFolder: false),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .readWrite, nodes: [.init()])
        )
        let addMenu = sut.addMenu { EmptyView() }
        XCTAssertNotNil(addMenu)
    }

    // MARK: - Private methods

    private typealias SUT = CloudDriveViewControllerNavItemsFactory

    private func makeSUT(
        nodeSource: NodeSource = .node { nil },
        config: NodeBrowserConfig? = nil,
        currentViewMode: ViewModePreferenceEntity = .list,
        contextMenuManager: ContextMenuManager = .init(
            createContextMenuUseCase: MockCreateContextMenuUseCase()
        ),
        contextMenuConfigFactory: CloudDriveContextMenuConfigFactory = .init(
            backupsUseCase: MockBackupsUseCase(),
            nodeUseCase: MockNodeDataUseCase()
        ),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        isSelectionHidden: Bool = false,
        sortOrderEntity: SortOrderEntity = .defaultAsc,
        isHidden: Bool? = nil
    ) -> SUT {
        SUT(
            nodeSource: nodeSource,
            config: config ?? config ?? NodeBrowserConfig.default,
            currentViewMode: currentViewMode,
            contextMenuManager: contextMenuManager,
            contextMenuConfigFactory: contextMenuConfigFactory,
            nodeUseCase: nodeUseCase,
            isSelectionHidden: isSelectionHidden, 
            sortOrder: sortOrderEntity, 
            isHidden: isHidden
        )
    }

    private func assertContextMenu(
        sut: SUT, accessType: NodeAccessTypeEntity? = .unknown, file: StaticString = #filePath, line: UInt = #line
    ) {
        let contextMenu = sut.contextMenu { EmptyView() }
        XCTAssertNil(contextMenu)
    }

    private func assertAddMenu(
        sut: SUT, file: StaticString = #filePath, line: UInt = #line
    ) {
        let addMenu = sut.addMenu { EmptyView() }
        XCTAssertNil(addMenu)
    }
}
