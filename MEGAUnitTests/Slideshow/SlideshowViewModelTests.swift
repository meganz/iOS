import XCTest
@testable import MEGA
import MEGADomainMock
import MEGADomain

class SlideshowViewModelTests: XCTestCase {
    private var nodeEntities: [NodeEntity] {
        [
            NodeEntity(name: "1.png", handle: 1),
            NodeEntity(name: "2.png", handle: 2),
            NodeEntity(name: "3.png", handle: 3),
            NodeEntity(name: "4.png", handle: 4),
            NodeEntity(name: "5.png", handle: 5)
        ]
    }
    
    private func slideshowViewModel() -> SlideShowViewModel {
        SlideShowViewModel(
            thumbnailUseCase: MockThumbnailUseCase(
                loadPreviewResult: .success(URL(string: "https://MEGA.NZ")!)
            ),
            dataProvider: PhotoBrowserDataProvider(
                currentPhoto: nodeEntities.first!,
                allPhotos: nodeEntities,
                sdk: MockSdk()
            )
        )
    }
    
    func testSlideshowPlay_UpdatePlaybackStatus_toPlaying() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .playing)
    }
    
    func testSlideshowPause_UpdatePlaybackStatus_toPause() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.playOrPause)
        sut.dispatch(.playOrPause)
        XCTAssert(sut.playbackStatus == .pause)
    }
    
    func testSlideshowExit_UpdatePlaybackStatus_toComplete() throws {
        let sut = slideshowViewModel()
        sut.dispatch(.finishPlaying)
        XCTAssert(sut.playbackStatus == .complete)
    }
}
