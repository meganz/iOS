@testable import MEGA

import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepoMock
import XCTest

final class SharedItemsViewModelTests: XCTestCase {
    
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
    func testIsSearchUsingNodeDescriptionEnabled_shouldReturnCorrectValues() async {
        let input = [false, true]
        input.forEach { enabled in
            let featureFlagProvider = MockFeatureFlagProvider(list: [.searchUsingNodeDescription: enabled])
            let sut = makeSUT(featureFlagProvider: featureFlagProvider)
            XCTAssertEqual(sut.isSearchUsingNodeDescriptionEnabled, enabled)
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
