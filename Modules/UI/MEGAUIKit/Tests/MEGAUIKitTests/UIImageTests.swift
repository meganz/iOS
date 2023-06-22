import MEGASwift
@testable import MEGAUIKit
import XCTest

final class UIImageTests: XCTestCase {
    
    func testCompareImageWhere_EitherIsNil() {
        let image1: UIImage? = UIImage()
        let image2: UIImage? = nil
        XCTAssertFalse(image1 ~~ image2)
        XCTAssertFalse(image2 ~~ image1)
    }
    
    func testCompareImageWhere_BothareDifferent() {
        let image1: UIImage? = UIImage()
        let image2: UIImage? = UIImage(systemName: "person")
        XCTAssertFalse(image1 ~~ image2)
    }

    func testCompareImageWhere_PngImageDataEqual() {
        let image1: UIImage? = UIImage(systemName: "person")
        let image2: UIImage? = UIImage(systemName: "person")
        XCTAssertTrue(image1 ~~ image2)
    }
}
