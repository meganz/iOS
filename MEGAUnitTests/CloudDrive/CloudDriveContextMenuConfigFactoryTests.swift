@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class CloudDriveContextMenuConfigFactoryTests: XCTestCase {

    func testContextMenuConfiguration_givenASortOrder_shouldMatchSortOrderInTheConfigEntity() throws {
        let sortOrders: [SortOrderEntity] = [
            .none,
            .defaultAsc,
            .defaultDesc,
            .sizeAsc,
            .sizeDesc,
            .creationAsc,
            .creationDesc,
            .modificationAsc,
            .modificationDesc,
            .linkCreationAsc,
            .linkCreationDesc,
            .labelAsc,
            .labelDesc,
            .favouriteAsc,
            .favouriteDesc
        ]

        for sortOrder in sortOrders {
            try assertContextMenuConfiguration(with: sortOrder)
        }
    }

    func testContextMenuConfiguration_withHiddenOptions_shouldMatchResults() {
        assertContextMenuConfiguration(withHideOption: nil)
        assertContextMenuConfiguration(withHideOption: true)
        assertContextMenuConfiguration(withHideOption: false)
    }

    // MARK: - Private methods.

    private typealias SUT = CloudDriveContextMenuConfigFactory

    private func makeSUT(
        backupsUseCase: some BackupsUseCaseProtocol = MockBackupsUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
    ) -> SUT {
        SUT(backupsUseCase: backupsUseCase, nodeUseCase: nodeUseCase)
    }

    private func assertContextMenuConfiguration(
        with sortOrder: SortOrderEntity,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let sut = makeSUT()
        let result = sut.contextMenuConfiguration(
            parentNode: NodeEntity(),
            nodeAccessType: .readWrite,
            currentViewMode: .list,
            isSelectionHidden: false,
            showMediaDiscovery: false,
            sortOrder: sortOrder,
            displayMode: .backup,
            isFromViewInFolder: false, 
            isHidden: nil
        )

        let resultSortOrder = try XCTUnwrap(result?.sortType, file: file, line: line)
        XCTAssertEqual(
            resultSortOrder,
            sortOrder,
            "expected sort order is \(sortOrder) but returned \(resultSortOrder)",
            file: file,
            line: line
        )
    }

    private func assertContextMenuConfiguration(
        withHideOption hidden: Bool?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT()
        let result = sut.contextMenuConfiguration(
            parentNode: NodeEntity(),
            nodeAccessType: .readWrite,
            currentViewMode: .list,
            isSelectionHidden: false,
            showMediaDiscovery: false,
            sortOrder: .none,
            displayMode: .cloudDrive,
            isFromViewInFolder: false,
            isHidden: hidden
        )

        XCTAssertEqual(result?.isHidden, hidden, file: file, line: line)
    }

}
