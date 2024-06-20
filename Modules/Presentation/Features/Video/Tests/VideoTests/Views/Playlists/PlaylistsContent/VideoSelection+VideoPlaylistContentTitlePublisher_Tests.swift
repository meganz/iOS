import Combine
import MEGADomain
import MEGAL10n
import Video
import XCTest

final class VideoSelection_VideoPlaylistContentTitlePublisher_Tests: XCTestCase {
    
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - videoPlaylistContentTitlePublisher
    
    func testVideoPlaylistContentTitlePublisher_whenIsNotEditing_shouldHasNoTitle() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for title called")
        var receivedTitle = ""
        sut.videoPlaylistContentTitlePublisher()
            .sink { title in
                receivedTitle = title
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.editMode = .inactive
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedTitle, "")
    }
    
    func testVideoPlaylistContentTitlePublisher_whenIsEditing_shouldHasDefaultSelectItemsTitleOnNoSelectedVideos() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for title called")
        exp.expectedFulfillmentCount = 2
        var receivedTitle = ""
        sut.videoPlaylistContentTitlePublisher()
            .sink { title in
                receivedTitle = title
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.editMode = .active
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedTitle, Strings.Localizable.selectTitle)
    }
    
    func testVideoPlaylistContentTitlePublisher_whenIsEditing_shouldHasDefaultSelectItemsTitleOnHasSelectedVideos() {
        let sut = makeSUT()
        
        let exp = expectation(description: "Wait for title called")
        exp.expectedFulfillmentCount = 3
        var receivedTitle = ""
        sut.videoPlaylistContentTitlePublisher()
            .sink { title in
                receivedTitle = title
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.editMode = .active
        sut.videos = [
            1: NodeEntity(handle: 1),
            2: NodeEntity(handle: 2)
        ]
        wait(for: [exp], timeout: 0.5)
        
        XCTAssertEqual(receivedTitle, Strings.Localizable.General.Format.itemsSelected(sut.videos.count))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> VideoSelection {
        let sut = VideoSelection()
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }

}
