import Combine
import MEGADomain
import MEGADomainMock
import MEGATest
@testable import Video
import XCTest

@MainActor
final class VideoListViewModelTests: XCTestCase {
    
    private var cancellables = Set<AnyCancellable>()
    
    func testInit_whenInit_doesNotExecuteSearchOnUseCase() {
        let (_, fileSearchUseCase) = makeSUT()
        
        XCTAssertEqual(fileSearchUseCase.searchCallCount, 0, "Expect to not search on creation")
        XCTAssertEqual(fileSearchUseCase.onNodesUpdateCallCount, 0, "Expect to not listen nodes update")
    }
    
    func testLoadVideos_whenCalled_executeSearchUseCase() async {
        let (sut, fileSearchUseCase) = makeSUT()
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.loadVideos()
        
        XCTAssertEqual(fileSearchUseCase.searchCallCount, 1, "Expect to search")
    }
    
    func testLoadVideos_whenError_showsErrorView() async {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .failure(FileSearchResultErrorEntity.generic)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.loadVideos()
        
        XCTAssertEqual(sut.uiState, .error)
    }
    
    func testLoadVideos_whenNoErrors_showsEmptyItemView() async {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.loadVideos()
        
        XCTAssertEqual(sut.uiState, .empty)
    }
    
    func testLoadVideos_whenNoErrors_showsVideoItems() async {
        let foundVideos = [ anyNode(id: 1, mediaType: .video), anyNode(id: 2, mediaType: .video) ]
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(foundVideos)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.loadVideos()
        
        XCTAssertEqual(sut.uiState, .loaded)
        XCTAssertEqual(sut.videos, foundVideos)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        fileSearchUseCase: some MockFilesSearchUseCase = MockFilesSearchUseCase(
            searchResult: .failure(.generic),
            onNodesUpdateResult: nil
        ),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: VideoListViewModel,
        fileSearchUseCase: MockFilesSearchUseCase
    ) {
        let sut = VideoListViewModel(fileSearchUseCase: fileSearchUseCase, thumbnailUseCase: MockThumbnailUseCase())
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return (sut, fileSearchUseCase)
    }
    
    private func anyNode(id: HandleEntity, mediaType: MediaTypeEntity, name: String = "any") -> NodeEntity {
        NodeEntity(
            changeTypes: .fileAttributes,
            nodeType: .file,
            name: name,
            handle: id,
            isFile: true,
            hasThumbnail: true,
            hasPreview: true,
            label: .unknown,
            publicHandle: id,
            size: 2,
            duration: 2,
            mediaType: mediaType
        )
    }
}
