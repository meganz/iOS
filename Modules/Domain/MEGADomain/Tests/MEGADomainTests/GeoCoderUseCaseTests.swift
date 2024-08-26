import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class GeoCoderUseCaseTests: XCTestCase {
    
    func testPlaceMark_whenNodeContainNilCoordinates_shouldThrowError() async {
        let sut = sut()
        let node = NodeEntity(handle: 1, latitude: nil, longitude: nil)
        await XCTAsyncAssertThrowsError(try await sut.placeMark(for: node)) { error in
            XCTAssertEqual(error as? GeoCoderErrorEntity, GeoCoderErrorEntity.noCoordinatesProvided)
        }
    }
    
    func testPlaceMark_whenNodeLocationHasNoInformation_shouldThrowError() async {
        let sut = sut(
            geoCoderRepository: MockGeoCoderRepository(placeMark: .failure(GeoCoderErrorEntity.noPlaceMarkFound)))
        let node = NodeEntity(handle: 1, latitude: 1.0, longitude: 128.0)
        await XCTAsyncAssertThrowsError(try await sut.placeMark(for: node)) { error in
            XCTAssertEqual(error as? GeoCoderErrorEntity, GeoCoderErrorEntity.noPlaceMarkFound)
        }
    }
    
    func testPlaceMark_whenNodeLocationHasInformation_shouldReturnPlaceMark() async throws {
        
        let expectedResult = PlaceMarkEntity(
            areasOfInterest: ["MEGA HQ"],
            subLocality: "Auckland Central",
            locality: "Auckland",
            country: "New Zealand")
        
        let sut = sut(
            geoCoderRepository: MockGeoCoderRepository(placeMark: .success(expectedResult)))
        let node = NodeEntity(handle: 1, latitude: 1.0, longitude: 128.0)
        let result = try await sut.placeMark(for: node)
        
        XCTAssertEqual(result, expectedResult)
    }
}

extension GeoCoderUseCaseTests {
    private func sut(geoCoderRepository: MockGeoCoderRepository = MockGeoCoderRepository()) -> GeoCoderUseCase<MockGeoCoderRepository> {
        GeoCoderUseCase(
            geoCoderRepository: geoCoderRepository)
    }
}
