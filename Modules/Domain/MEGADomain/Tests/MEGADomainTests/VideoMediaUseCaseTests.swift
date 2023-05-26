import XCTest
import MEGADomain
import MEGADomainMock

final class VideoMediaUseCaseTests: XCTestCase {
    let sut = VideoMediaUseCase(videoMediaRepository: MockVideoMediaRepository(supportedFormats: [-1, 1], supportedCodecs: [-1, 15]))
    
    func testIsPlayable_whenFilteringVideos_shouldReturnTrue() {
        let videoNode = NodeEntity(name: "video.mov", codecId: 15)
        XCTAssertTrue(sut.isPlayable(videoNode))
        
        let videoNode2 = NodeEntity(name: "video.mp4", shortFormat: 1)
        XCTAssertTrue(sut.isPlayable(videoNode2))
        
        let videoNode3 = NodeEntity(name: "video.mp4", codecId: -1)
        XCTAssertTrue(sut.isPlayable(videoNode3))
        
        let videoNode4 = NodeEntity(name: "video.mp4", shortFormat: -1)
        XCTAssertTrue(sut.isPlayable(videoNode4))
    }
    
    func testIsPlayable_whenFilteringOtherFileTypes_shouldReturnFalse() {
        let node = NodeEntity(name: "notVideo.pdf")
        XCTAssertFalse(sut.isPlayable(node))
    }
}
