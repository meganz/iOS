@testable import MEGA
import MEGADataMock
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class UserAttributeUseCaseAdditionsTests: XCTestCase {

    func testTimelineFilter_whenWithoutBase64Encode_shouldReturnNil() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json))]])
        let sut = UserAttributeUseCase(repo: repo)
        
        let timelineFilter = try await sut.timelineFilter()
        
        XCTAssertNil(timelineFilter)
    }
    
    func testTimelineFilter_whenCorruptedJSONDataLikeiOSIsMispelled_shouldThrowError() async throws {
        let json = """
            {"iOS":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json?.base64Encoded))]])
        let sut = UserAttributeUseCase(repo: repo)
        
        await XCTAssertThrowsError(try await sut.timelineFilter())
    }
    
    func testTimelineFilter_whenAValidJsonDataWithCorrectiOSKey_shouldGiveTheRightObject() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(XCTUnwrap(json?.base64Encoded))]])
        let sut = UserAttributeUseCase(repo: repo)
        
        let timelineFilter = try await sut.timelineFilter()
        
        XCTAssertEqual(try XCTUnwrap(timelineFilter?.filterType), .images)
        XCTAssertEqual(try XCTUnwrap(timelineFilter?.filterLocation), .cameraUploads)
        XCTAssertEqual(try XCTUnwrap(timelineFilter?.usePreference), false)
    }

}
