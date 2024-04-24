import XCTest

final class NSAttributedStringTests: XCTestCase {
    func testAttributedStringFromImage() {
        let image = UIImage()
        let fontCapHeight: CGFloat = 20.0
        
        let attributedString = NSAttributedString.attributedString(fromImage: image, fontCapHeight: fontCapHeight)
        
        let attachment = attributedString.attribute(NSAttributedString.Key.attachment, at: 0, effectiveRange: nil) as? NSTextAttachment
        XCTAssertNotNil(attachment)
        XCTAssertEqual(attachment?.bounds, CGRect(x: 0.0, y: (fontCapHeight - image.size.height) / 2.0, width: image.size.width, height: image.size.height))
        XCTAssertEqual(attachment?.image, image)
    }
}
