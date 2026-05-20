@testable import MEGA
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGAL10n
import Search
import SearchMock
import SwiftUI
import XCTest

@MainActor
final class CloudDriveEmptyViewAssetFactoryTests: XCTestCase {

    func testDefaultAsset_forRecentBucket_shouldMatch() {
        let sut = makeSUT()
        let emptyAsset = sut.defaultAsset(for: .mockRecentActionBucketEmpty, config: .init())
        let expectedEmptyAsset = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )
        XCTAssertEqual(emptyAsset, expectedEmptyAsset)
    }

    func testDefaultAsset_forEmptyParentNode_shouldMatch() {
        assert(
            nodeEntity: nil,
            displayMode: .unknown,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forCloudDriveRootNode_shouldMatch() {
        assert(
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            nodeEntity: NodeEntity(nodeType: .root),
            displayMode: .cloudDrive,
            expectedImage: MEGAAssets.Image.glassCloud,
            expectedTitle: Strings.Localizable.cloudDriveEmptyStateTitle
        )
    }

    func testDefaultAsset_forRubbishBinNode_shouldMatch() {
        assert(
            nodeUseCase: MockNodeDataUseCase(isARubbishBinRootNodeValue: true),
            nodeEntity: NodeEntity(nodeType: .rubbish),
            displayMode: .rubbishBin,
            expectedImage: MEGAAssets.Image.glassTrash,
            expectedTitle: Strings.Localizable.cloudDriveEmptyStateTitleRubbishBin
        )
    }

    func testDefaultAsset_forCloudDriveNotRoot_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .cloudDrive,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forRubbishBinNotRoot_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .rubbishBin,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forFileType_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .file),
            displayMode: .cloudDrive,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forIncomingShare_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .sharedItem,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    func testDefaultAsset_forBackup_shouldMatch() {
        assert(
            nodeEntity: NodeEntity(nodeType: .folder),
            displayMode: .backup,
            expectedImage: MEGAAssets.Image.glassFolder,
            expectedTitle: Strings.Localizable.emptyFolder
        )
    }

    // MARK: - Private methods.

    typealias SUT = CloudDriveEmptyViewAssetFactory

    private func makeSUT(
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase()
    ) -> SUT {
        .init(nodeUseCase: nodeUseCase)
    }

    private func assert(
        nodeUseCase: some NodeUseCaseProtocol = MockNodeDataUseCase(),
        nodeEntity: NodeEntity?,
        displayMode: DisplayMode,
        expectedImage: Image,
        expectedTitle: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let sut = makeSUT(nodeUseCase: nodeUseCase)
        let emptyAsset = sut.defaultAsset(for: .node({ nodeEntity }), config: .init(displayMode: displayMode))

        let expectedEmptyAsset = SearchConfig.EmptyViewAssets(
            image: expectedImage,
            title: expectedTitle,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )
        XCTAssertEqual(emptyAsset, expectedEmptyAsset, file: file, line: line)
    }
}
