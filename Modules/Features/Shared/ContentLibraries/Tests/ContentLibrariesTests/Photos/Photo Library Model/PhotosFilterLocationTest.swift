@testable import ContentLibraries
import MEGADomain
import XCTest

final class PhotosFilterLocationTest: XCTestCase {

    func testToContentConsumptionMediaLocation_shouldMatchRightValues() {
        XCTAssertEqual(TimelineUserAttributeEntity.MediaLocation.cloudDrive, PhotosFilterLocation.cloudDrive.toContentConsumptionMediaLocation())
        XCTAssertEqual(TimelineUserAttributeEntity.MediaLocation.cameraUploads, PhotosFilterLocation.cameraUploads.toContentConsumptionMediaLocation())
        XCTAssertEqual(TimelineUserAttributeEntity.MediaLocation.allLocations, PhotosFilterLocation.allLocations.toContentConsumptionMediaLocation())
    }
    
    func testToFilterLocation_shouldMatchRightValues() {
        XCTAssertEqual(PhotosFilterLocation.cloudDrive, PhotosFilterLocation.toFilterLocation(from: .cloudDrive))
        XCTAssertEqual(PhotosFilterLocation.cameraUploads, PhotosFilterLocation.toFilterLocation(from: .cameraUploads))
        XCTAssertEqual(PhotosFilterLocation.allLocations, PhotosFilterLocation.toFilterLocation(from: .allLocations))
    }
}
