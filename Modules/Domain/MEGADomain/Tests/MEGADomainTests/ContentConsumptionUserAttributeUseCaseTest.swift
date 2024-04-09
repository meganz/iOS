import MEGADomain
import MEGADomainMock
import XCTest

final class ContentConsumptionUserAttributeUseCaseTest: XCTestCase {
    
    func testFetchTimelineAttribute_shouldGetValuesStoredInJsonRelatedToTimeline() async throws {
        let json = """
                {
                  "ios": {
                    "timeline": {
                      "mediaType": "images",
                      "location": "cloudDrive"
                    }
                  },
                  "android": {
                    "timeline": {
                      "mediaType": "images",
                      "location": "cameraUploads"
                    }
                  },
                  "web": {
                    "timeline": {
                      "mediaType": "images",
                      "location": "cameraUploads"
                    }
                  }
                }
            """
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)
        
        let timelineAttributes = await sut.fetchTimelineAttribute()
        
        XCTAssertEqual(timelineAttributes, .init(mediaType: .images, location: .cloudDrive, usePreference: false))
    }
    
    func testSaveTimelineAttributesOnly_shouldStoreValuesCorrectly() async throws {
        
        let expectedEncodable = ContentConsumptionEntity(
            ios: .init(timeline: .init(
                    mediaType: .images,
                    location: .cameraUploads,
                    usePreference: true)))
        
        let repo = MockUserAttributeRepository()
        let sut = sut(repo: repo)

        try await sut.save(timeline: .init(mediaType: .images, location: .cameraUploads, usePreference: true))
                
        guard let result = repo.mergeUserAttributes[.contentConsumptionPreferences] as? ContentConsumptionEntity else {
            return XCTFail("Failed to fetch object to be merged")
        }
        
        XCTAssertEqual(result, expectedEncodable)
    }
    
    func testSaveTimelineAttributesOnly_withExistingOtherValues_shouldStoreValuesCorrectlyWithOutAlteringOtherProperties() async throws {
        
        let json = """
            {
              "ios": {
                "timeline": {
                  "mediaType": "videos",
                  "location": "cloudDrive"
                }
              }
            }
            """
        let expectedEncodable = ContentConsumptionEntity(
            ios: .init(timeline: .init(
                    mediaType: .images,
                    location: .cameraUploads,
                    usePreference: true))
            )
        
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)

        try await sut.save(timeline: .init(mediaType: .images, location: .cameraUploads, usePreference: true))
                
        guard let result = repo.mergeUserAttributes[.contentConsumptionPreferences] as? ContentConsumptionEntity else {
            return XCTFail("Failed to fetch object to be merged")
        }
        
        XCTAssertEqual(result, expectedEncodable)
    }
    
    private func sut(repo: MockUserAttributeRepository = MockUserAttributeRepository()) -> ContentConsumptionUserAttributeUseCase <MockUserAttributeRepository> {
        ContentConsumptionUserAttributeUseCase(repo: repo)
    }
}
