import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest
@testable import Video

final class VideoListViewModelTests: XCTestCase {
    
    func testInit_whenInit_doesNotExecuteSearchOnUseCase() {
        let (_, fileSearchUseCase) = makeSUT()
        
        XCTAssertEqual(fileSearchUseCase.searchCallCount, 0, "Expect to not search on creation")
        XCTAssertEqual(fileSearchUseCase.onNodesUpdateCallCount, 0, "Expect to not listen nodes update")
    }
    
    func testViewAppeared_whenCalled_executeSearchUseCase() {
        let (sut, fileSearchUseCase) = makeSUT()
        
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        
        XCTAssertEqual(fileSearchUseCase.searchCallCount, 1, "Expect to search")
    }
    
    func testViewAppeared_whenError_showsErrorView() {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .failure(FileSearchResultErrorEntity.generic)))
        var receivedCommands = [VideoListViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        
        XCTAssertEqual(receivedCommands, [ .showErrorView ])
    }
    
    func testViewAppeared_whenNoErrors_showsEmptyItemView() {
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(nil)))
        var receivedCommands = [VideoListViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        
        XCTAssertEqual(receivedCommands, [ .showEmptyItemView ])
    }
    
    func testViewAppeared_whenNoErrors_showsVideoItems() {
        let foundVideos = [ anyNode(id: 1, mediaType: .video), anyNode(id: 2, mediaType: .video) ]
        let (sut, _) = makeSUT(fileSearchUseCase: MockFilesSearchUseCase(searchResult: .success(foundVideos)))
        var receivedCommands = [VideoListViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        
        XCTAssertEqual(receivedCommands, [ .showItems(nodes: foundVideos) ])
    }
    
    func testViewAppeared_whenCalled_ListenNodesUpdate() {
        let (sut, fileSearchUseCase) = makeSUT()
        
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        
        XCTAssertEqual(fileSearchUseCase.onNodesUpdateCallCount, 1)
    }
    
    func testOnNodesUpdate_whenHasNodeUpdatesOnNonVideoNodes_doesNotUpdateUI() {
        let nonVideoNodes = [ 
            anyNode(id: 1, mediaType: .image),
            anyNode(id: 2, mediaType: .image)
        ]
        let nonVideosUpdateNodes = [ 
            anyNode(id: 1, mediaType: .image), anyNode(id: 2, mediaType: .image)
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(nonVideoNodes),
                onNodesUpdateResult: nonVideosUpdateNodes
            )
        )
        var receivedCommands = [VideoListViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        receivedCommands.removeAll()
        
        fileSearchUseCase.simulateOnNodesUpdate(with: nonVideosUpdateNodes)
        
        XCTAssertEqual(receivedCommands, [])
    }
    
    func testOnNodesUpdate_whenHasNodeUpdatesOnVideoNodes_updatesUI() {
        let intialVideoNodes = [ 
            anyNode(id: 1, mediaType: .video, name: "old video name"),
            anyNode(id: 2, mediaType: .image, name: "old image name")
        ]
        let updatedVideoNodes = [ 
            anyNode(id: 1, mediaType: .video, name: "new video name")
        ]
        let (sut, fileSearchUseCase) = makeSUT(
            fileSearchUseCase: MockFilesSearchUseCase(
                searchResult: .success(intialVideoNodes),
                onNodesUpdateResult: updatedVideoNodes
            )
        )
        var receivedCommands = [VideoListViewModel.Command]()
        sut.invokeCommand = { command in
            receivedCommands.append(command)
        }
        sut.dispatch(.onViewAppeared(searchedText: nil, sortOrderType: .defaultAsc))
        receivedCommands.removeAll()
        
        fileSearchUseCase.simulateOnNodesUpdate(with: updatedVideoNodes)
        
        XCTAssertEqual(receivedCommands, [ .updateItems(nodes: updatedVideoNodes) ])
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
        let sut = VideoListViewModel(fileSearchUseCase: fileSearchUseCase)
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
