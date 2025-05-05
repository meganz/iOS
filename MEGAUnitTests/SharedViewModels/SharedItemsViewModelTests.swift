@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADesignToken
import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class SharedItemsViewModelTests: XCTestCase {
    struct DescriptionForNodeTestData {
        let nodeDescription: String?
        let searchText: String?
        let output: NSAttributedString?
        static let nodeDescriptionIsNil = DescriptionForNodeTestData(nodeDescription: nil, searchText: "desc", output: nil)
        static let searchTextIsNil = DescriptionForNodeTestData(nodeDescription: "description", searchText: nil, output: nil)
        static let searchTextNotMatched = DescriptionForNodeTestData(nodeDescription: "description", searchText: "a", output: nil)
        static let searchTextMatched = DescriptionForNodeTestData(
            nodeDescription: "description",
            searchText: "desc",
            output: "description".highlightedStringWithKeyword(
                "desc",
                primaryTextColor: TokenColors.Text.secondary,
                highlightedTextColor: TokenColors.Notifications.notificationSuccess,
                normalFont: UIFont.preferredFont(forTextStyle: .caption1),
                highlightedFont: UIFont.preferredFont(style: .caption1, weight: .bold)
            )
        )

        static let searchTextMatchedMultipleTimes = DescriptionForNodeTestData(
            nodeDescription: "description1 description2",
            searchText: "desc",
            output: "description1 description2".highlightedStringWithKeyword(
                "desc",
                primaryTextColor: TokenColors.Text.secondary,
                highlightedTextColor: TokenColors.Notifications.notificationSuccess,
                normalFont: UIFont.preferredFont(forTextStyle: .caption1),
                highlightedFont: UIFont.preferredFont(style: .caption1, weight: .bold)
            )
        )
    }

    struct TagsForNodeTestData {
        let isFeatureFlagEnabled: Bool
        let tags: [String]
        let searchText: String?
        let output: [NSAttributedString]
        static let flagDisabled = TagsForNodeTestData(isFeatureFlagEnabled: false, tags: ["tag"], searchText: "tag", output: [])
        static let emptyTags = TagsForNodeTestData(isFeatureFlagEnabled: true, tags: [], searchText: "tag", output: [])
        static let searchTextIsNil = TagsForNodeTestData(isFeatureFlagEnabled: true, tags: ["tag"], searchText: nil, output: [])
        static let searchTextNotMatched = TagsForNodeTestData(isFeatureFlagEnabled: true, tags: ["tag"], searchText: "x", output: [])
        static let singleMatch = TagsForNodeTestData(isFeatureFlagEnabled: true, tags: ["tag"], searchText: "ta", output: [attributedOutput(tag: "tag", searchText: "ta")])
        static let multipleMatches = TagsForNodeTestData(
            isFeatureFlagEnabled: true,
            tags: ["tag1", "tag2", "xxx"],
            searchText: "tag",
            output: [
                attributedOutput(tag: "tag1", searchText: "tag"),
                attributedOutput(tag: "tag2", searchText: "tag")
            ]
        )

        private static func attributedOutput(tag: String, searchText: String) -> NSAttributedString {
            ("#" + tag).forceLeftToRight().highlightedStringWithKeyword(
                searchText,
                primaryTextColor: TokenColors.Text.primary,
                highlightedTextColor: TokenColors.Notifications.notificationSuccess,
                normalFont: .preferredFont(style: .subheadline, weight: .medium)
            )
        }
    }

    @MainActor
    func testAreMediaNodes_withNodes_true() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let sut = makeSUT(mediaUseCase: mockMediaUseCase)
        
        let result = sut.areMediaNodes([MockNode(handle: 1)])
        
        XCTAssertTrue(result)
    }
    
    @MainActor
    func testAreMediaNodes_withEmptyNodes_false() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let sut = makeSUT(mediaUseCase: mockMediaUseCase)
        
        let result = sut.areMediaNodes([])
        
        XCTAssertFalse(result)
    }
    
    @MainActor
    func testMoveToRubbishBin_called() async {
        let mockMediaUseCase = MockMoveToRubbishBinViewModel()
        let sut = makeSUT(moveToRubbishBinViewModel: mockMediaUseCase)
        let node = MockNode(handle: 1)
        
        sut.moveNodeToRubbishBin(node)
        
        XCTAssertTrue(mockMediaUseCase.calledNodes.count == 1)
        XCTAssertTrue(mockMediaUseCase.calledNodes.first?.handle == node.handle)
    }
    
    @MainActor
    func testSaveNodesToPhotos_success() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let mockSaveMediaToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success)
        let sut = makeSUT(mediaUseCase: mockMediaUseCase, saveMediaToPhotosUseCase: mockSaveMediaToPhotosUseCase)
        
        await sut.saveNodesToPhotos([MockNode(handle: 1)])
    }
    
    @MainActor
    func testSaveNodesToPhotos_withEmptyNodes_failure() async {
        let sut = makeSUT()
        await sut.saveNodesToPhotos([])
    }
    
    @MainActor
    func testSaveNodesToPhotos_withDownloadError_failure() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let mockSaveMediaToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .failure(.downloadFailed))
        let sut = makeSUT(mediaUseCase: mockMediaUseCase, saveMediaToPhotosUseCase: mockSaveMediaToPhotosUseCase)
        
        await sut.saveNodesToPhotos([MockNode(handle: 1)])
    }
    
    @MainActor
    func testOpenSharedDialog_withNodes_success() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")
        
        mockShareUseCase.onCreateShareKeyCalled = {
            expectation.fulfill()
        }
        
        sut.openShareFolderDialog(forNodes: [MockNode(handle: 1)])
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }
    
    @MainActor
    func disable_testOpenSharedDialog_withNodeNotFoundError_failure() async {
        let mockShareUseCase = MockShareUseCase(createShareKeysError: ShareErrorEntity.nodeNotFound)
        let sut = makeSUT(shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")
        
        mockShareUseCase.onCreateShareKeysErrorCalled = {
            expectation.fulfill()
        }
        
        sut.openShareFolderDialog(forNodes: [MockNode(handle: 1)])
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(mockShareUseCase.createShareKeysErrorHappened)
    }

    @MainActor
    func testDescriptionForNode_ShouldReturnCorrectValues() async {
        let testData: [DescriptionForNodeTestData] = [
            .nodeDescriptionIsNil,
            .searchTextIsNil,
            .searchTextNotMatched,
            .searchTextMatched,
            .searchTextMatchedMultipleTimes
        ]

        testData.forEach { data in
            let sut = makeSUT()
            XCTAssertEqual(sut.descriptionForNode(MockNode(handle: 1, description: data.nodeDescription), with: data.searchText), data.output)
        }
    }

    @MainActor
    func testTagsForNode_ShouldReturnCorrectValues() async {
        let testData: [TagsForNodeTestData] = [
            .flagDisabled,
            .emptyTags,
            .searchTextIsNil,
            .searchTextNotMatched,
            .singleMatch,
            .multipleMatches
        ]
        testData.forEach { data in
            let featureFlagProvider = MockFeatureFlagProvider(list: [.searchByNodeTags: data.isFeatureFlagEnabled])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            let tagsStringList = MockMEGAStringList(size: data.tags.count, strings: data.tags)
            XCTAssertEqual(sut.tagsForNode(MockNode(handle: 1, tags: tagsStringList), with: data.searchText), data.output)
        }
    }
    
    @MainActor
    func testIsNodeTakenDown_nodeIsFolder_returnsFalse() async {
        let folderNode = NodeEntity(
            nodeType: .folder,
            handle: 1,
            isFolder: true,
            isTakenDown: true
        )
        let stub = MockNodeUseCase(nodes: [1: folderNode])
        let sut = makeSUT(nodeUseCase: stub)
        let result = await sut.isFileTakenDown(folderNode.handle)
        
        XCTAssertFalse(result, "folders—even if marked ‘taken down’—should return false")
    }

    @MainActor
    func testIsNodeTakenDown_fileNotTakenDown_returnsFalse() async {
        let fileNode = NodeEntity(
            nodeType: .file,
            handle: 1,
            isFile: true,
            isTakenDown: false
        )
        let stub = MockNodeUseCase(nodes: [1: fileNode])
        let sut = makeSUT(nodeUseCase: stub)
        
        let result = await sut.isFileTakenDown(fileNode.handle)
        XCTAssertFalse(result, "files not taken down should return false")
    }

    @MainActor
    func testIsNodeTakenDown_fileTakenDown_returnsTrue() async {
        let fileNode = NodeEntity(
            nodeType: .file,
            handle: 1,
            isFile: true,
            isTakenDown: true
        )
        let stub = MockNodeUseCase(nodes: [1: fileNode])
        let sut = makeSUT(nodeUseCase: stub)
        
        let result = await sut.isFileTakenDown(fileNode.handle)
        XCTAssertTrue(result, "files not taken down should return false")
    }

    @MainActor private func makeSUT(
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
        nodeUseCase: some NodeUseCaseProtocol = MockNodeUseCase(),
        moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol = MockMoveToRubbishBinViewModel(),
        featureFlagProvider: MockFeatureFlagProvider = .init(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> SharedItemsViewModel {
        let sut = SharedItemsViewModel(
            shareUseCase: shareUseCase,
            mediaUseCase: mediaUseCase,
            nodeUseCase: nodeUseCase,
            saveMediaToPhotosUseCase: saveMediaToPhotosUseCase,
            moveToRubbishBinViewModel: moveToRubbishBinViewModel,
            featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

}
