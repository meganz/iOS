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
         
        XCTAssertTrue(fileSearchUseCase.messages.isEmpty, "Expect to not search on creation")
    }
    
    func testInit_whenInit_doNotListenToNodesUpdate() {
        let (_, fileSearchUseCase) = makeSUT()
        
        XCTAssertTrue(fileSearchUseCase.messages.isEmpty, "Expect to not listen nodes update")
    }
    
    func testOnViewAppeared_whenCalled_listenToNodesUpdate() async {
        let (sut, fileSearchUseCase) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(fileSearchUseCase.messages.contains(.onNodesUpdate), "Expect to listen nodes update")
    }
    
    func testOnViewAppeared_whenCalled_executeSearchUseCase() async {
        let (sut, fileSearchUseCase) = makeSUT()
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(fileSearchUseCase.messages.contains(.search), "Expect to search")
    }
    
    func testOnViewAppeared_whenCalledOnFailedLoadVideos_executesSearchUseCaseInOrder() async {
        let (sut, fileSearchUseCase) = makeSUT()
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(fileSearchUseCase.messages, [ .search ])
    }
    
    func testOnViewAppeared_whenCalledOnSuccessfullyLoadVideos_executesSearchUseCaseInOrder() async {
        let (sut, fileSearchUseCase) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(fileSearchUseCase.messages, [
            .search,
            .startNodesUpdateListener,
            .onNodesUpdate
        ])
    }
    
    func testOnViewAppeared_whenError_showsErrorView() async {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .failure(FileSearchResultErrorEntity.generic)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.shouldShowError, true)
    }
    
    func testOnViewAppeared_whenNoErrors_showsEmptyItemView() async {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.videos.isEmpty, true)
    }
    
    func testOnViewAppeared_whenNoErrors_showsVideoItems() async {
        let foundVideos = [ anyNode(id: 1, mediaType: .video), anyNode(id: 2, mediaType: .video) ]
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(foundVideos)))
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        XCTAssertEqual(sut.videos, foundVideos)
    }
    
    func testOnNodesUpdate_whenHasNodeUpdatesOnNonVideoNodes_doesNotUpdateUI() async {
        let videoNodes = [
            anyNode(id: 1, mediaType: .video),
            anyNode(id: 2, mediaType: .video)
        ]
        let nonVideosUpdateNodes = [
            anyNode(id: 1, mediaType: .image), 
            anyNode(id: 2, mediaType: .image)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(videoNodes),
                onNodesUpdateResult: nonVideosUpdateNodes
            )
        )
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        fileSearchUseCase.simulateOnNodesUpdate(with: nonVideosUpdateNodes)
        
        XCTAssertEqual(sut.videos, videoNodes)
    }
    
    func testOnNodesUpdate_whenHasNodeUpdatesOnVideoNodes_updatesUI() async {
        let attributesRelatedChangeTypes: ChangeTypeEntity = [ .attributes, .fileAttributes, .favourite, .publicLink ]
        let intialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: attributesRelatedChangeTypes)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(intialVideoNodes),
                onNodesUpdateResult: updatedVideoNodes
            )
        )
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        fileSearchUseCase.simulateOnNodesUpdate(with: updatedVideoNodes)
        await sut.reloadVideosTask?.value
        
        XCTAssertEqual(sut.videos.count, 2)
        XCTAssertEqual(sut.videos.first, updatedVideoNodes.first)
        XCTAssertEqual(sut.videos.last, intialVideoNodes.last)
    }
    
    func testOnNodesUpdate_whenHasNodeUpdatesOnVideoNodesButNonValidChangeTypes_doesNotUpdateUI() async {
        let invalidChangeTypes: ChangeTypeEntity = [ .removed, .timestamp ]
        let intialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: invalidChangeTypes)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(intialVideoNodes),
                onNodesUpdateResult: updatedVideoNodes
            )
        )
        sut.searchedText = ""
        sut.sortOrderType = .defaultAsc
        
        await sut.onViewAppeared()
        
        fileSearchUseCase.simulateOnNodesUpdate(with: updatedVideoNodes)
        await sut.reloadVideosTask?.value
        
        XCTAssertEqual(sut.videos.count, 2)
        XCTAssertEqual(sut.videos, intialVideoNodes)
    }
    
    func testOnViewAppeared_whenCalled_startNodesUpdateListener() async {
        let invalidChangeTypes: ChangeTypeEntity = [ .removed, .timestamp ]
        let intialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: invalidChangeTypes)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(intialVideoNodes),
                onNodesUpdateResult: updatedVideoNodes
            )
        )
        
        await sut.onViewAppeared()
        
        XCTAssertTrue(fileSearchUseCase.messages.contains(.startNodesUpdateListener))
        XCTAssertTrue(fileSearchUseCase.messages.notContains(.stopNodesUpdateListener))
    }
    
    func testOnViewDissapeared_whenCalled_stopNodesUpdateListener() {
        let invalidChangeTypes: ChangeTypeEntity = [ .removed, .timestamp ]
        let intialVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [
            anyNode(id: 1, mediaType: .video, name: "new video name", changeTypes: invalidChangeTypes)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(intialVideoNodes),
                onNodesUpdateResult: updatedVideoNodes
            )
        )
        
        sut.onViewDissapeared()
        
        XCTAssertEqual(fileSearchUseCase.messages.last, .stopNodesUpdateListener)
        XCTAssertTrue(fileSearchUseCase.messages.notContains(.startNodesUpdateListener))
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
    
    private func anyNode(id: HandleEntity, mediaType: MediaTypeEntity, name: String = "any", changeTypes: ChangeTypeEntity = .fileAttributes) -> NodeEntity {
        NodeEntity(
            changeTypes: changeTypes,
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
