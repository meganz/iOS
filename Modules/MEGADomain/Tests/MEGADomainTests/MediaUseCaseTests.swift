import XCTest
import MEGADomain

final class MediaUseCaseTests: XCTestCase {
    let sut = MediaUseCase()
    
    func testIsImage() {
        for fileExtension in ImageFileExtensionEntity().imagesSupportedExtensions {
            let url = URL(fileURLWithPath: "image.\(fileExtension)")
            XCTAssertTrue(sut.isImage(for: url))
        }
    }
    
    func testIsNotImage() {
        let url = URL(fileURLWithPath: "notImage.doc")
        XCTAssertFalse(sut.isImage(for: url))
    }
    
    func testIsVideo() {
        for fileExtension in VideoFileExtensionEntity().videoSupportedExtensions {
            let url = URL(fileURLWithPath: "video.\(fileExtension)")
            XCTAssertTrue(sut.isVideo(for: url))
        }
    }
    
    func testIsNotVideo() {
        let url = URL(fileURLWithPath: "notVideo.pdf")
        XCTAssertFalse(sut.isVideo(for: url))
    }
}
