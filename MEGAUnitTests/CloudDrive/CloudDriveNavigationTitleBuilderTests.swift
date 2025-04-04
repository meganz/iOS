@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

class CloudDriveNavigationTitleBuilderTests: XCTestCase {
    class Harness {
        static func makeSUT(
            parentNode: NodeEntity? = nil,
            isEditModeActive: Bool = false,
            displayMode: DisplayMode,
            selectedNodesArrayCount: Int = 0,
            nodes: NodeListEntity? = nil,
            isBackupsRootNode: Bool = false
        ) -> String {
            CloudDriveNavigationTitleBuilder.build(
                parentNode: parentNode,
                isEditModeActive: isEditModeActive,
                displayMode: displayMode,
                selectedNodesArrayCount: selectedNodesArrayCount,
                nodes: nodes,
                backupsUseCase: MockBackupsUseCase(
                    isBackupsRootNode: isBackupsRootNode
                )
            )
        }
    }

    func testCloudDriveNavigationTitle_whenInCloudDriveRoot_shouldBeCloudDrive() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .root),
            displayMode: .cloudDrive
        )

        XCTAssertEqual(sut, "Cloud drive")
    }

    func testCloudDriveNavigationTitle_whenInCloudDrive_openedFolderNode_shouldBeNodeTitle() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder, name: "Folder node"),
            displayMode: .cloudDrive
        )

        XCTAssertEqual(sut, "Folder node")
    }

    func testCloudDriveNavigationTitle_whenInRubbishBinRoot_shouldBeCloudDrive() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .rubbish),
            displayMode: .rubbishBin
        )

        XCTAssertEqual(sut, "Rubbish bin")
    }

    func testCloudDriveNavigationTitle_whenInRubbishBin_openedFolderNode_shouldBeNodeTitle() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder, name: "Folder node"),
            displayMode: .rubbishBin
        )

        XCTAssertEqual(sut, "Folder node")
    }

    func testCloudDriveNavigationTitle_whenInRecents_withSingleNode_shouldIncludeNodeCount() {
        let nodesArray = [NodeEntity()]

        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder),
            displayMode: .recents,
            nodes: NodeListEntity(
                nodesCount: nodesArray.count,
                nodeAt: { nodesArray[$0] }
            )
        )

        XCTAssertEqual(sut, "1 item")
    }

    func testCloudDriveNavigationTitle_whenInRecents_withMultipleNodes_shouldIncludeNodeCount() {
        let nodesArray = [NodeEntity(), NodeEntity()]

        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder),
            displayMode: .recents,
            nodes: NodeListEntity(
                nodesCount: nodesArray.count,
                nodeAt: { nodesArray[$0] }
            )
        )

        XCTAssertEqual(sut, "2 items")
    }

    func testCloudDriveNavigationTitle_whenInBackups_isBackupNode_shouldHaveCorrectTitle() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder, name: "Folder node"),
            displayMode: .backup,
            isBackupsRootNode: true
        )

        XCTAssertEqual(sut, "Backups")
    }

    func testCloudDriveNavigationTitle_whenInBackups_notBackupNode_shouldHaveCorrectTitle() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder, name: "Folder node"),
            displayMode: .backup,
            isBackupsRootNode: false
        )

        XCTAssertEqual(sut, "Folder node")
    }

    func testCloudDriveNavigationTitle_whenInEditMode_withNoneSelected_shouldHaveCorrectTitle() {
        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder),
            isEditModeActive: true,
            displayMode: .cloudDrive
        )

        XCTAssertEqual(sut, "Select items")
    }

    func testCloudDriveNavigationTitle_whenInEditMode_withOneSelected_shouldHaveCorrectTitle() {
        let nodesArray = [NodeEntity()]

        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder),
            isEditModeActive: true,
            displayMode: .cloudDrive,
            selectedNodesArrayCount: 1,
            nodes: NodeListEntity(
                nodesCount: nodesArray.count,
                nodeAt: { nodesArray[$0] }
            )
        )

        XCTAssertEqual(sut, "1 item selected")
    }

    func testCloudDriveNavigationTitle_whenInEditMode_withMultipleSelected_shouldHaveCorrectTitle() {
        let nodesArray = [NodeEntity(), NodeEntity()]

        let sut = Harness.makeSUT(
            parentNode: NodeEntity(nodeType: .folder),
            isEditModeActive: true,
            displayMode: .cloudDrive,
            selectedNodesArrayCount: 2,
            nodes: NodeListEntity(
                nodesCount: nodesArray.count,
                nodeAt: { nodesArray[$0] }
            )
        )

        XCTAssertEqual(sut, "2 items selected")
    }
}
