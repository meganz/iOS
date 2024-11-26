@testable import MEGA
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import Search
import SearchMock
import SwiftUI
import XCTest

final class CloudDriveEmptyViewAssetFactoryTests: XCTestCase {

    func testDefaultAsset_forRecentBucket_shouldMatch() {
        let sut = makeSUT()
        let emptyAsset = sut.defaultAsset(for: .recentActionBucket(MEGARecentActionBucket()), config: .init())
        let expectedEmptyAsset = SearchConfig.EmptyViewAssets(
            image: Image(.searchEmptyState),
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
        XCTAssertEqual(emptyAsset, expectedEmptyAsset)
    }

    func testDefaultAsset_forEmptyParentNode_shouldMatch() {
        assert(
            nodeEntity: nil,
            displayMode: .unknown,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forCloudDriveRootNodeWithReadPermission_shouldMatch() {
        assert(
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .read),
            nodeEntity: NodeEntity(nodeType: .root),
            displayMode: .cloudDrive,
            expectedImage: Image(.cloudEmptyState),
            expectedTitle: Strings.Localizable.cloudDriveEmptyStateTitle
        )
    }

    func testDefaultAsset_forCloudDriveRootNodeWithWritePermission_shouldMatch() {
        assert(for: .readWrite)
    }

    func testDefaultAsset_forCloudDriveRootNodeWithFullAccessPermission_shouldMatch() {
        assert(for: .full)

    }

    func testDefaultAsset_forCloudDriveRootNodeWithOwnerPermission_shouldMatch() {
        assert(for: .owner)
    }

    func testDefaultAsset_forRubbishBinNode_shouldMatch() {
        assert(
            nodeUseCase: MockNodeDataUseCase(isARubbishBinRootNodeValue: true),
            nodeEntity: NodeEntity(nodeType: .rubbish),
            displayMode: .rubbishBin,
            expectedImage: Image(.rubbishEmptyState),
            expectedTitle: Strings.Localizable.cloudDriveEmptyStateTitleRubbishBin
        )
    }

    func testDefaultAsset_forCloudDriveNotRoot_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .cloudDrive,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forRubbishBinNotRoot_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .rubbishBin,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forFileType_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .file),
            displayMode: .cloudDrive,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forIncomingShare_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .sharedItem,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forBackup_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .backup,
            expectedImage: Image(.folderEmptyState),
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    // MARK: - Private methods.

    typealias SUT = CloudDriveEmptyViewAssetFactory

    private func makeSUT(
        tracker: some AnalyticsTracking = MockTracker(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
    ) -> SUT {
        .init(
            tracker: tracker,
            nodeInsertionRouter: MockNodeInsertionRouter(),
            nodeUseCase: nodeUseCase
        )
    }

    private func assert(for nodeAccessLevel: NodeAccessTypeEntity, file: StaticString = #file, line: UInt = #line) {
        assert(
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel),
            nodeEntity: NodeEntity(nodeType: .root),
            displayMode: .cloudDrive,
            expectedImage: Image(.cloudEmptyState),
            expectedTitle: Strings.Localizable.cloudDriveEmptyStateTitle,
            actions: [
                .init(
                    title: Strings.Localizable.addFiles, 
                    titleTextColor: TokenColors.Text.inverseAccent.swiftUI,
                    backgroundColor: TokenColors.Support.success.swiftUI,
                    menu: [
                        .init(title: Strings.Localizable.newTextFile, image: Image(.textfile), handler: {}),
                        .init(title: Strings.Localizable.newFolder, image: Image(.newFolder), handler: {}),
                        .init(title: Strings.Localizable.scanDocument, image: Image(.scanDocument), handler: {}),
                        .init(
                            title: Strings.Localizable.CloudDrive.Upload.importFromFiles,
                            image: Image(.import),
                            handler: {}
                        ),
                        .init(title: Strings.Localizable.capturePhotoVideo, image: Image(.capture), handler: {}),
                        .init(title: Strings.Localizable.choosePhotoVideo, image: Image(.saveToPhotos), handler: {})
                    ]
                )
            ],
            file: file,
            line: line
        )
    }

    private func assert(
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        nodeEntity: NodeEntity?,
        displayMode: DisplayMode,
        expectedImage: Image,
        expectedTitle: String,
        actions: [SearchConfig.EmptyViewAssets.Action] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let sut = makeSUT(nodeUseCase: nodeUseCase)
        let emptyAsset = sut.defaultAsset(for: .node({ nodeEntity }), config: .init(displayMode: displayMode))

        let expectedEmptyAsset = SearchConfig.EmptyViewAssets(
            image: expectedImage,
            title: expectedTitle,
            titleTextColor: TokenColors.Icon.secondary.swiftUI,
            actions: actions
        )
        XCTAssertEqual(emptyAsset, expectedEmptyAsset, file: file, line: line)
    }
}
