import XCTest
import MEGADomain

final class MediaUseCaseTests: XCTestCase {
    let sut = MediaUseCase()
    
    func testIsImage() {
        for fileExtension in ImageFileExtensionEntity().imagesSupportedExtensions {
            let name = "image.\(fileExtension)"
            XCTAssertTrue(sut.isImage(name))
            let url = URL(fileURLWithPath: name)
            XCTAssertTrue(sut.isImage(for: url))
        }
    }
    
    func testIsNotImage() {
        let name = "notImage.doc"
        XCTAssertFalse(sut.isImage(name))
        let url = URL(fileURLWithPath: name)
        XCTAssertFalse(sut.isImage(for: url))
    }
    
    func testIsVideo() {
        for fileExtension in VideoFileExtensionEntity().videoSupportedExtensions {
            let name = "video.\(fileExtension)"
            XCTAssertTrue(sut.isVideo(name))
            let url = URL(fileURLWithPath: name)
            XCTAssertTrue(sut.isVideo(for: url))
        }
    }
    
    func testIsNotVideo() {
        let name = "notVideo.pdf"
        XCTAssertFalse(sut.isVideo(name))
        let url = URL(fileURLWithPath: name)
        XCTAssertFalse(sut.isVideo(for: url))
    }
}
