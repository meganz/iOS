@testable import MEGA

import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import XCTest

final class SharedItemsViewModelTests: XCTestCase {
    
    func testAreMediaNodes_withNodes_true() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let sut = await makeSUT(mediaUseCase: mockMediaUseCase)
        
        let result = await sut.areMediaNodes([MockNode(handle: 1)])
        
        XCTAssertTrue(result)
    }
    
    func testAreMediaNodes_withEmptyNodes_false() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let sut = await makeSUT(mediaUseCase: mockMediaUseCase)
        
        let result = await sut.areMediaNodes([])
        
        XCTAssertFalse(result)
    }
    
    func testMoveToRubbishBin_called() async {
        let mockMediaUseCase = MockMoveToRubbishBinViewModel()
        let sut = await makeSUT(moveToRubbishBinViewModel: mockMediaUseCase)
        let node = MockNode(handle: 1)
        
        await sut.moveNodeToRubbishBin(node)
        
        XCTAssertTrue(mockMediaUseCase.calledNodes.count == 1)
        XCTAssertTrue(mockMediaUseCase.calledNodes.first?.handle == node.handle)
    }
    
    func testSaveNodesToPhotos_success() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let mockSaveMediaToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .success)
        let sut = await makeSUT(mediaUseCase: mockMediaUseCase, saveMediaToPhotosUseCase: mockSaveMediaToPhotosUseCase)
        
        await sut.saveNodesToPhotos([MockNode(handle: 1)])
    }
    
    func testSaveNodesToPhotos_withEmptyNodes_failure() async {
        let sut = await makeSUT()
        
        await sut.saveNodesToPhotos([])
    }
    
    func testSaveNodesToPhotos_withDownloadError_failure() async {
        let mockMediaUseCase = MockMediaUseCase(isPlayableMediaFile: true)
        let mockSaveMediaToPhotosUseCase = MockSaveMediaToPhotosUseCase(saveToPhotosResult: .failure(.downloadFailed))
        let sut = await makeSUT(mediaUseCase: mockMediaUseCase, saveMediaToPhotosUseCase: mockSaveMediaToPhotosUseCase)
        
        await sut.saveNodesToPhotos([MockNode(handle: 1)])
    }
    
    func testOpenSharedDialog_withNodes_success() async {
        let mockShareUseCase = MockShareUseCase()
        let sut = await makeSUT(shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")
        
        Task {
            await sut.openShareFolderDialog(forNodes: [MockNode(handle: 1)])
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
      
        XCTAssertTrue(mockShareUseCase.createShareKeyFunctionHasBeenCalled)
    }
    
    func testOpenSharedDialog_withNodeNotFoundError_failure() async {
        let mockShareUseCase = MockShareUseCase(createShareKeysError: ShareErrorEntity.nodeNotFound)
        let sut = await makeSUT(shareUseCase: mockShareUseCase)
        let expectation = expectation(description: "Task has started")
        
        Task {
            await sut.openShareFolderDialog(forNodes: [MockNode(handle: 1)])
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
      
        XCTAssertTrue(mockShareUseCase.createShareKeysErrorHappened)
    }
    
    @MainActor
    private func makeSUT(
        shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
        mediaUseCase: some MediaUseCaseProtocol = MockMediaUseCase(),
        saveMediaToPhotosUseCase: some SaveMediaToPhotosUseCaseProtocol = MockSaveMediaToPhotosUseCase(),
        moveToRubbishBinViewModel: some MoveToRubbishBinViewModelProtocol = MockMoveToRubbishBinViewModel(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> SharedItemsViewModel {
        let sut = SharedItemsViewModel(shareUseCase: shareUseCase,
                                       mediaUseCase: mediaUseCase,
                                       saveMediaToPhotosUseCase: saveMediaToPhotosUseCase,
                                       moveToRubbishBinViewModel: moveToRubbishBinViewModel)
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
