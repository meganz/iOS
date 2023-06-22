@testable import MEGA
import MEGADomain
import XCTest

final class PhotosFilterTypeTest: XCTestCase {

    func testToContentConsumptionMediaType_shouldMatchRightValues() {
        XCTAssertEqual(ContentConsumptionMediaType.images, PhotosFilterType.images.toContentConsumptionMediaType())
        XCTAssertEqual(ContentConsumptionMediaType.videos, PhotosFilterType.videos.toContentConsumptionMediaType())
        XCTAssertEqual(ContentConsumptionMediaType.allMedia, PhotosFilterType.allMedia.toContentConsumptionMediaType())
    }
    
    func testToFilterType_shouldMatchRightValues() {
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .images), PhotosFilterType.images)
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .videos), PhotosFilterType.videos)
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .allMedia), PhotosFilterType.allMedia)
    }

}
