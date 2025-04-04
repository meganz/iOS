@testable import MEGA
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class ContentConsumptionUserAttributeUseCaseAdditionsTests: XCTestCase {

    func testTimelineFilter_whenWithoutBase64Encode_shouldReturnDefaultValues() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json))]])
        let sut = ContentConsumptionUserAttributeUseCase(repo: repo)
        
        let timelineFilter = await sut.fetchTimelineFilter()
        
        XCTAssertEqual(timelineFilter, .init(filterType: .allMedia, filterLocation: .allLocations, usePreference: false))
    }
    
    func testTimelineFilter_whenCorruptedJSONDataLikeiOSIsMispelled_shouldReturnDefaultValues() async throws {
        let json = """
            {"iOS":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json?.base64Encoded))]])
        let sut = ContentConsumptionUserAttributeUseCase(repo: repo)
        let timelineFilter = await sut.fetchTimelineFilter()

        XCTAssertEqual(timelineFilter, .init(filterType: .allMedia, filterLocation: .allLocations, usePreference: false))
    }
    
    func testTimelineFilter_whenAValidJsonDataWithCorrectiOSKey_shouldGiveTheRightObject() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json?.base64Encoded))]])
        let sut = ContentConsumptionUserAttributeUseCase(repo: repo)
        
        let timelineFilter = await sut.fetchTimelineFilter()
        
        XCTAssertEqual(try XCTUnwrap(timelineFilter.filterType), .images)
        XCTAssertEqual(try XCTUnwrap(timelineFilter.filterLocation), .cameraUploads)
        XCTAssertEqual(try XCTUnwrap(timelineFilter.usePreference), false)
    }
}
