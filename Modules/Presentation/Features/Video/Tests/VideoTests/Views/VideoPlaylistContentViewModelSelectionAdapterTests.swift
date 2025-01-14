import MEGADomain
import MEGADomainMock
import MEGATest
@testable import Video
import XCTest

final class VideoPlaylistContentViewModelSelectionAdapterTests: XCTestCase {
    @MainActor
    func testDidChangeAllSelectedValue_AllSelectedTrue_selectsAllVideos() {
        let videos = videos()
        let videoSelection = VideoSelection()
        let sut = makeSUT(videoSelection: videoSelection)
        
        simulateSelectAllVideos(on: sut, videoSelection: videoSelection, videos: videos)
    }
    
    @MainActor
    func testDidChangeAllSelectedValue_AllSelectedFalse_deselectsAllVideos() {
        let videos = videos()
        let videoSelection = VideoSelection()
        videoSelection.allSelected = true
        videoSelection.videos = [
            videos[0].id: videos[0],
            videos[1].id: videos[1]
        ]
        let sut = makeSUT(videoSelection: videoSelection)
        
        simualateDeselectAllVideos(on: sut, videoSelection: videoSelection, videos: videos)
        
    }
    
    @MainActor
    func testDidChangeAllSelectedValue_selectAndDeselect_runsCorrectSelection() {
        let videos = videos()
        let videoSelection = VideoSelection()
        let sut = makeSUT(videoSelection: videoSelection)
        
        simulateSelectAllVideos(on: sut, videoSelection: videoSelection, videos: videos)
        
        simualateDeselectAllVideos(on: sut, videoSelection: videoSelection, videos: videos)
        
        simulateSelectAllVideos(on: sut, videoSelection: videoSelection, videos: videos)
    }
    
    // MARK: - Helpers
    @MainActor
    private func makeSUT(
        videoSelection: VideoSelection,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VideoPlaylistContentViewModelSelectionAdapter {
        let sut = VideoPlaylistContentViewModelSelectionAdapter(selection: videoSelection)
        trackForMemoryLeaks(on: videoSelection, file: file, line: line)
        return sut
    }
    
    @MainActor
    private func simulateSelectAllVideos(
        on sut: VideoPlaylistContentViewModelSelectionAdapter,
        videoSelection: VideoSelection,
        videos: [NodeEntity],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.didChangeAllSelectedValue(allSelected: true, videos: videos)
        
        XCTAssertTrue(videoSelection.allSelected, file: file, line: line)
        XCTAssertEqual(videoSelection.videos.count, videos.count, file: file, line: line)
    }
    
    @MainActor
    private func simualateDeselectAllVideos(
        on sut: VideoPlaylistContentViewModelSelectionAdapter,
        videoSelection: VideoSelection,
        videos: [NodeEntity],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        sut.didChangeAllSelectedValue(allSelected: false, videos: videos)
        
        XCTAssertFalse(videoSelection.allSelected)
        XCTAssertTrue(videoSelection.videos.isEmpty)
    }
    
    @MainActor
    private func videos() -> [NodeEntity] {
        [
            video(handle: 1),
            video(handle: 2)
        ]
    }
    
    @MainActor
    private func video(handle: HandleEntity) -> NodeEntity {
        NodeEntity(name: "video-\(handle).mp4", handle: handle, mediaType: .video)
    }
}
