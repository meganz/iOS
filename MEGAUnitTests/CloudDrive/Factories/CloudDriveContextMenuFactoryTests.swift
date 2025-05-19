@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class CloudDriveContextMenuFactoryTests: XCTestCase {

    func testMakeNodeBrowserContextMenuViewFactory_whenSensitivityIsntDetermined_shouldCompleteImmediately() async {
        await assertMakeNodeBrowserContextMenuViewFactory(isSensitive: nil)
    }

    func testMakeNodeBrowserContextMenuViewFactory_whenSensitive_shouldReturnHiddenAndComplete() async {
        await assertMakeNodeBrowserContextMenuViewFactory(isSensitive: true)
    }

    func testMakeNodeBrowserContextMenuViewFactory_whenNotSensitive_shouldReturnNotHiddenAndComplete() async {
       await assertMakeNodeBrowserContextMenuViewFactory(isSensitive: false)
    }

    private func assertMakeNodeBrowserContextMenuViewFactory(isSensitive: Bool? = nil) async {
        let sut = makeSUT(isSensitive: isSensitive)
        let stream = sut.makeNodeBrowserContextMenuViewFactory(
            nodeSource: .node { NodeEntity() },
            viewMode: .list,
            isSelectionHidden: false,
            sortOrder: .none
        )

        var results: [CloudDriveViewControllerNavItemsFactory] = []
        for await contextMenu in stream {
            results.append(contextMenu.makeNavItemsFactory())
        }

        XCTAssertEqual(results.count, isSensitive == nil ? 1 : 2)
        XCTAssertEqual(results.first?.isHidden, nil)
        if let isSensitive {
            XCTAssertEqual(results.last?.isHidden, isSensitive)
        }
    }

    // MARK: - Helps

    private func makeSUT(isSensitive: Bool? = nil) -> CloudDriveContextMenuFactory {
        CloudDriveContextMenuFactory(
            config: NodeBrowserConfig(),
            contextMenuManager: ContextMenuManager(createContextMenuUseCase: MockCreateContextMenuUseCase()),
            contextMenuConfigFactory: CloudDriveContextMenuConfigFactory(
                backupsUseCase: MockBackupsUseCase(),
                nodeUseCase: MockNodeDataUseCase()
            ),
            nodeSensitivityChecker: MockNodeSensitivityChecker(isSensitive: isSensitive),
            nodeUseCase: MockNodeDataUseCase()
        )
    }
}
