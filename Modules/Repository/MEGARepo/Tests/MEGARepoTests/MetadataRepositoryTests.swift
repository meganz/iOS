import MEGADomain
import MEGARepo
import XCTest

final class MetadataRepositoryTests: XCTestCase {
    func testCoordinateForImage_withoutGPSInfo_shouldBeNil() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample_image_without_gps", withExtension: "png"))
        let sut = MetadataRepository()
        let result = sut.coordinateForImage(at: url)
        XCTAssertNil(result)
    }

    func testCoordinateForImage_withGPSInfo_shouldReturnCoordinates() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample_image_with_gps", withExtension: "heic"))
        let sut = MetadataRepository()
        let result = sut.coordinateForImage(at: url)
        XCTAssertEqual(result, Coordinate(latitude: 13.070763833333332, longitude: 74.994475))
    }

    func testCoordinateForVideo_withoutGPSInfo_shouldBeNil() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample_video_without_gps", withExtension: "mov"))
        let sut = MetadataRepository()
        let result = await sut.coordinateForVideo(at: url)
        XCTAssertNil(result)
    }

    func testCoordinateForVideo_withGPSInfo_shouldReturnCoordinates() async throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "sample_video_with_gps", withExtension: "MOV"))
        let sut = MetadataRepository()
        let result = await sut.coordinateForVideo(at: url)
        XCTAssertEqual(result, Coordinate(latitude: 13.0716, longitude: 74.9953))
    }
}
