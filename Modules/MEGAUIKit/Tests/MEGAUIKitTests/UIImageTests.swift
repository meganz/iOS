import XCTest

final class UIImageTests: XCTestCase {
    
    func testCompareImageWhere_BothAreNil() {
        XCTAssertTrue(UIImage.compareImages(nil, nil))
    }
    
    func testCompareImageWhere_EitherIsNil() {
        let image: UIImage? = UIImage()
        XCTAssertFalse(UIImage.compareImages(nil, image))
        XCTAssertFalse(UIImage.compareImages(image, nil))
    }
    
    func testCompareImageWhere_BothareDifferent() {
        let image1: UIImage? = UIImage()
        let image2: UIImage? = UIImage(systemName: "person")
        XCTAssertFalse(UIImage.compareImages(image1, image2))
    }
    
    func testCompareImageWhere_PngImageDataEqual() {
        let image1: UIImage? = UIImage(systemName: "person")
        let image2: UIImage? = UIImage(systemName: "person")
        XCTAssertTrue(UIImage.compareImages(image1, image2))
    }
}
