@testable import ContentLibraries
import MEGADomain
import XCTest

final class PhotosFilterTypeTest: XCTestCase {

    func testToContentConsumptionMediaType_shouldMatchRightValues() {
        XCTAssertEqual(TimelineUserAttributeEntity.MediaType.images, PhotosFilterType.images.toContentConsumptionMediaType())
        XCTAssertEqual(TimelineUserAttributeEntity.MediaType.videos, PhotosFilterType.videos.toContentConsumptionMediaType())
        XCTAssertEqual(TimelineUserAttributeEntity.MediaType.allMedia, PhotosFilterType.allMedia.toContentConsumptionMediaType())
    }
    
    func testToFilterType_shouldMatchRightValues() {
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .images), PhotosFilterType.images)
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .videos), PhotosFilterType.videos)
        XCTAssertEqual(PhotosFilterType.toFilterType(from: .allMedia), PhotosFilterType.allMedia)
    }
}
