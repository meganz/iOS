import XCTest
import MEGADomain
@testable import MEGA

final class PhotosFilterLocationTest: XCTestCase {

    func testToContentConsumptionMediaLocation_shouldMatchRightValues() {
        XCTAssertEqual(ContentConsumptionMediaLocation.cloudDrive, PhotosFilterLocation.cloudDrive.toContentConsumptionMediaLocation())
        XCTAssertEqual(ContentConsumptionMediaLocation.cameraUploads, PhotosFilterLocation.cameraUploads.toContentConsumptionMediaLocation())
        XCTAssertEqual(ContentConsumptionMediaLocation.allLocations, PhotosFilterLocation.allLocations.toContentConsumptionMediaLocation())
    }
    
    func testToFilterLocation_shouldMatchRightValues() {
        XCTAssertEqual(PhotosFilterLocation.cloudDrive, PhotosFilterLocation.toFilterLocation(from: .cloudDrive))
        XCTAssertEqual(PhotosFilterLocation.cameraUploads, PhotosFilterLocation.toFilterLocation(from: .cameraUploads))
        XCTAssertEqual(PhotosFilterLocation.allLocations, PhotosFilterLocation.toFilterLocation(from: .allLocations))
    }

}
