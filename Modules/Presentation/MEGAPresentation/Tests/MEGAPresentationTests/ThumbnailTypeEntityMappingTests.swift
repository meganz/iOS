import MEGADomain
import MEGAPresentation
import XCTest

final class ThumbnailTypeEntityMappingTests: XCTestCase {
    func testMapToImageType() {
        let sut: [ThumbnailTypeEntity] = [.thumbnail, .preview, .original]
        for type in sut {
            switch type {
            case .thumbnail:
                XCTAssertEqual(type.toImageType(), .thumbnail)
            case .preview:
                XCTAssertEqual(type.toImageType(), .preview)
            case .original:
                XCTAssertEqual(type.toImageType(), .original)
            }
        }
    }
}
