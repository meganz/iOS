@testable import MEGA

// swiftlint:disable sorted_imports
import MEGADomain
import MEGADesignToken
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import MEGASwift
import XCTest

final class SharedItemsViewModelTests: XCTestCase {
    struct DescriptionForNodeTestData {
        let isFeatureFlagEnabled: Bool
        let nodeDescription: String?
        let searchText: String?
        let output: NSAttributedString?
        static let flagDisabled = DescriptionForNodeTestData(isFeatureFlagEnabled: false, nodeDescription: "description", searchText: "desc", output: nil)
        static let nodeDescriptionIsNil = DescriptionForNodeTestData(isFeatureFlagEnabled: true, nodeDescription: nil, searchText: "desc", output: nil)
        static let searchTextIsNil = DescriptionForNodeTestData(isFeatureFlagEnabled: true, nodeDescription: "description", searchText: nil, output: nil)
        static let searchTextNotMatched = DescriptionForNodeTestData(isFeatureFlagEnabled: true, nodeDescription: "description", searchText: "a", output: nil)
        static let searchTextMatched = DescriptionForNodeTestData(
            isFeatureFlagEnabled: true,
            nodeDescription: "description",
            searchText: "desc",
            output: "description".highlightedStringWithKeyword(
                "desc", primaryTextColor: TokenColors.Text.secondary, highlightedTextColor: TokenColors.Notifications.notificationSuccess
            )
        )

        static let searchTextMatchedMultipleTimes = DescriptionForNodeTestData(
            isFeatureFlagEnabled: true,
            nodeDescription: "description1 description2",
            searchText: "desc",
            output: "description1 description2".highlightedStringWithKeyword(
                "desc", primaryTextColor: TokenColors.Text.secondary, highlightedTextColor: TokenColors.Notifications.notificationSuccess
            )
        )
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
    func testOpenSharedDialog_withNodeNotFoundError_failure() async {
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
            .flagDisabled,
            .nodeDescriptionIsNil,
            .searchTextIsNil,
            .searchTextNotMatched,
            .searchTextMatched,
            .searchTextMatchedMultipleTimes
        ]

        testData.forEach { data in
            let featureFlagProvider = MockFeatureFlagProvider(list: [.searchUsingNodeDescription: data.isFeatureFlagEnabled])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            XCTAssertEqual(sut.descriptionForNode(MockNode(handle: 1, description: data.nodeDescription), with: data.searchText), data.output)
        }
    }

    @MainActor private func makeSUT(
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
        moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol = MockMoveToRubbishBinViewModel(),
        featureFlagProvider: MockFeatureFlagProvider = .init(list: [:]),
        file: StaticString = #file,
        line: UInt = #line
    ) -> SharedItemsViewModel {
        let sut = SharedItemsViewModel(shareUseCase: shareUseCase,
                                       mediaUseCase: mediaUseCase,
                                       saveMediaToPhotosUseCase: saveMediaToPhotosUseCase,
                                       moveToRubbishBinViewModel: moveToRubbishBinViewModel,
                                       featureFlagProvider: featureFlagProvider
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}

// swiftlint:enable sorted_imports
