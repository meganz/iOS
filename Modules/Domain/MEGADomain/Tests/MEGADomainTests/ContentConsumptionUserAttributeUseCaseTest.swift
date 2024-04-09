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
                    usePreference: true),
                       sensitives: .init(showHiddenNodes: false)),
            sensitives: .init(onboarded: false))
        
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
              },
              "sensitives": {
                "onboarded": true
              }
            }
            """
        let expectedEncodable = ContentConsumptionEntity(
            ios: .init(timeline: .init(
                    mediaType: .images,
                    location: .cameraUploads,
                    usePreference: true),
                       sensitives: .init(showHiddenNodes: false)),
            sensitives: .init(onboarded: true))
        
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)

        try await sut.save(timeline: .init(mediaType: .images, location: .cameraUploads, usePreference: true))
                
        guard let result = repo.mergeUserAttributes[.contentConsumptionPreferences] as? ContentConsumptionEntity else {
            return XCTFail("Failed to fetch object to be merged")
        }
        
        XCTAssertEqual(result, expectedEncodable)
    }
    
    func testFetchSensitiveAttribute_shouldGetValuesStoredInJsonRelatedToSensitive() async throws {
        let json = """
            {
              "ios": {
                "timeline": {
                  "mediaType": "images",
                  "location": "cloudDrive"
                },
                "sensitives": {
                  "showHiddenNodes": true
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
              },
              "sensitives": {
                "onboarded": true
              }
            }
            """

        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)

        try await sut.save(timeline: .init(mediaType: .images, location: .cameraUploads, usePreference: true))
        
        let sensitiveAttributes = await sut.fetchSensitiveAttribute()
        
        XCTAssertEqual(sensitiveAttributes, .init(onboarded: true, showHiddenNodes: true))
    }
    
    func testFetchSensitiveAttribute_whenJsonStructureIsMissingValues_shouldGetValuesWithDefaultStoredInJsonRelatedToSensitive() async throws {
        let json = """
            {
              "ios": {
                "timeline": {
                  "mediaType": "images",
                  "location": "cloudDrive"
                },
                "sensitives": { }
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
        
        let sensitiveAttributes = await sut.fetchSensitiveAttribute()
        
        XCTAssertEqual(sensitiveAttributes, .init(onboarded: false, showHiddenNodes: false))
    }
    
    func testSaveSensitiveShowHiddenNodesAttributesOnly_withExistingOtherValues_shouldStoreValuesCorrectlyWithOutAlteringOtherProperties() async throws {
        
        let json = """
            {
              "ios": {
                "timeline": {
                  "mediaType": "videos",
                  "location": "cloudDrive"
                }
              },
              "sensitives": {
                "onboarded": true
              }
            }
            """
        let expectedEncodable = ContentConsumptionEntity(
            ios: .init(
                timeline: .init(
                    mediaType: .videos,
                    location: .cloudDrive,
                    usePreference: false),
                sensitives: .init(showHiddenNodes: true)),
            sensitives: .init(onboarded: true))
        
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)

        try await sut.saveSensitiveSetting(showHiddenNodes: true)
        guard let result = repo.mergeUserAttributes[.contentConsumptionPreferences] as? ContentConsumptionEntity else {
            return XCTFail("Failed to fetch object to be merged")
        }
        
        XCTAssertEqual(result, expectedEncodable)
    }
    
    func testSaveSensitiveOnboardedAttributesOnly_withExistingOtherValues_shouldStoreValuesCorrectlyWithOutAlteringOtherProperties() async throws {
        
        let json = """
            {
              "ios": {
                "timeline": {
                  "mediaType": "videos",
                  "location": "cloudDrive"
                }
              },
              "sensitives": {
                "onboarded": false
              }
            }
            """
        let expectedEncodable = ContentConsumptionEntity(
            ios: .init(
                timeline: .init(
                    mediaType: .videos,
                    location: .cloudDrive,
                    usePreference: false),
                sensitives: .init(showHiddenNodes: false)),
            sensitives: .init(onboarded: true))
        
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = sut(repo: repo)

        try await sut.saveSensitiveSetting(onboarded: true)
        guard let result = repo.mergeUserAttributes[.contentConsumptionPreferences] as? ContentConsumptionEntity else {
            return XCTFail("Failed to fetch object to be merged")
        }
        
        XCTAssertEqual(result, expectedEncodable)
    }
    
    private func sut(repo: MockUserAttributeRepository = MockUserAttributeRepository()) -> ContentConsumptionUserAttributeUseCase <MockUserAttributeRepository> {
        ContentConsumptionUserAttributeUseCase(repo: repo)
    }
}
