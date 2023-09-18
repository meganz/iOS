import MEGADomain
import MEGADomainMock
import XCTest

final class UserAttributeUseCaseTest: XCTestCase {
    func testUserAttribute_UpdateUserName() async throws {
        let repo = MockUserAttributeRepository()
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.updateUserAttribute(.firstName, value: "First Name")
        try await sut.updateUserAttribute(.lastName, value: "Last Name")
        
        XCTAssertEqual(repo.userAttributes[.firstName], "First Name")
        XCTAssertEqual(repo.userAttributes[.lastName], "Last Name")
    }
    
    func testUpdateUserAttribute_shouldUpdateAppPreferenceFirstTime() async throws {
        let key = "iosTimelineLocation", value = "All location"
        let sut = UserAttributeUseCase(repo: MockUserAttributeRepository())
        
        try await sut.updateUserAttribute(.contentConsumptionPreferences, key: key, value: value)
        
        let appsPreferences = try await sut.userAttribute(for: .contentConsumptionPreferences)
        XCTAssertEqual(try XCTUnwrap(appsPreferences?[key]), value)
    }
    
    func testUpdateUserAttribute_shouldUpdateAppPreferenceTwoTimes() async throws {
        let key1 = "iosTimelineLocation", value1 = "All location"
        let key2 = "iosTimelineMediaType", value2 = "All media"
        let sut = UserAttributeUseCase(repo: MockUserAttributeRepository())
        
        try await sut.updateUserAttribute(.contentConsumptionPreferences, key: key1, value: value1)
        try await sut.updateUserAttribute(.contentConsumptionPreferences, key: key2, value: value2)
        
        let appsPreferences = try await sut.userAttribute(for: .contentConsumptionPreferences)
        XCTAssertEqual(try XCTUnwrap(appsPreferences?[key1]), value1)
        XCTAssertEqual(try XCTUnwrap(appsPreferences?[key2]), value2)
    }
    
    func testUserAttribute_shouldRetrieveCorrectValue() async throws {
        let key1 = "iosTimelineLocation", value1 = "cloudDrive"
       let sut = UserAttributeUseCase(repo: MockUserAttributeRepository())
        
        try await sut.updateUserAttribute(.contentConsumptionPreferences, key: key1, value: value1)
        
        let appsPreferences = try await sut.userAttribute(for: .contentConsumptionPreferences)
        XCTAssertEqual(try XCTUnwrap(appsPreferences?[key1]), value1)
    }
    
    func testRetrieveContentConsumptionAttribute_shouldBeNotNilAndLocationShouldBeCloudDrive() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cloudDrive"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        let contentConsumption = try await sut.retrieveContentConsumptionAttribute()
        
        XCTAssertNotNil(contentConsumption)
        XCTAssertEqual(contentConsumption?.ios.timeline.location, .cloudDrive)
    }
    
    func testSaveTimelineFilter_onFirstTime_shouldSaveCorrectly() async throws {
        let json = ""
        let targetJson = """
            {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":true}}}
        """
        
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveTimelineFilter(key: ContentConsumptionKeysEntity.key, timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: true))

        let decoder = JSONDecoder()
        let savedJSON = try XCTUnwrap(repo.userAttributesContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key])
        let savedAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(savedJSON.utf8))
        let targetAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(targetJson.utf8))
        XCTAssertEqual(savedAttribute, targetAttribute)
    }
    
    func testSaveTimelineFilter_onFirstTime_shouldUsePreferenceBeEmpty() async throws {
        let json = ""
        let targetJson = """
            {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive"}}}
        """
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveTimelineFilter(key: ContentConsumptionKeysEntity.key, timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: nil))
        
        let decoder = JSONDecoder()
        let savedJSON = try XCTUnwrap(repo.userAttributesContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key])
        let savedAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(savedJSON.utf8))
        let targetAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(targetJson.utf8))
        XCTAssertEqual(savedAttribute, targetAttribute)
    }
    
    func testSaveTimelineFilter_onSecondTime_shouldSaveCorrectly() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive","usePreference":true}}}
        """
        let targetJson = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads","usePreference":false}}}
        """
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveTimelineFilter(key: ContentConsumptionKeysEntity.key, timeline: ContentConsumptionTimeline(mediaType: .images, location: .cameraUploads, usePreference: false))
        
        let decoder = JSONDecoder()
        let savedJSON = try XCTUnwrap(repo.userAttributesContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key])
        let savedAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(savedJSON.utf8))
        let targetAttribute = try decoder.decode(ContentConsumptionEntity.self, from: Data(targetJson.utf8))
        XCTAssertEqual(savedAttribute, targetAttribute)
    }
    
    func testSaveTimelineFilter_withCrossPlatformData_shouldChangeOnlyiOSBlock() async throws {
        let json = """
            {"ios":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let targetJson = """
            {"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive"}},"android":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json?.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveTimelineFilter(key: ContentConsumptionKeysEntity.key, timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: nil))
        
        XCTAssertNotNil(repo.userAttributesContainer[.contentConsumptionPreferences])
        let updatedJsonData = try XCTUnwrap(repo.userAttributesContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key]).sorted()
        XCTAssertEqual(updatedJsonData, try XCTUnwrap(targetJson).sorted())
    }
    
    func testSaveTimelineFilter_withOnlyHavingCrossPlatformData_shouldAddiOSBlockCorrectlyWithOtherPlatformData() async throws {
        let json = """
            {"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}}}
        """.trim
        let targetJson = """
            {"web":{"timeline":{"mediaType":"images","location":"cameraUploads"}},"ios":{"timeline":{"mediaType":"videos","location":"cloudDrive"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.contentConsumptionPreferences: [ContentConsumptionKeysEntity.key: try XCTUnwrap(json?.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveTimelineFilter(key: ContentConsumptionKeysEntity.key, timeline: ContentConsumptionTimeline(mediaType: .videos, location: .cloudDrive, usePreference: nil))
        
        XCTAssertNotNil(repo.userAttributesContainer[.contentConsumptionPreferences])
        let updatedJsonData = try XCTUnwrap(repo.userAttributesContainer[.contentConsumptionPreferences]?[ContentConsumptionKeysEntity.key]).sorted()
        XCTAssertEqual(updatedJsonData, try XCTUnwrap(targetJson).sorted())
    }
    
    // MARK: - Scheduled meeting onboarding
    
    func testRetrieveScheduledMeetingOnboardingAttribute_haveNoInitialData_shouldBeNil() async throws {
        let repo = MockUserAttributeRepository()
        let sut = UserAttributeUseCase(repo: repo)
        
        let scheduledMeetingOnboardingEntity = try await sut.retrieveScheduledMeetingOnBoardingAttrubute()
        
        XCTAssertNil(scheduledMeetingOnboardingEntity)
    }
    
    func testRetrieveScheduledMeetingOnboardingAttribute_haveInitialData_shouldBeNotNilAndHaveShownMeetingTabShouldBeFalse() async throws {
        let json = """
            {"ios":{"record":{"currentTip":"createMeeting"}}}
        """
        let repo = MockUserAttributeRepository(userAttributesContainer: [.appsPreferences: [ScheduledMeetingOnboardingKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        let scheduledMeetingOnboardingEntity = try await sut.retrieveScheduledMeetingOnBoardingAttrubute()
        
        XCTAssertNotNil(scheduledMeetingOnboardingEntity)
        XCTAssertEqual(scheduledMeetingOnboardingEntity?.ios.record.currentTip.rawValue, "createMeeting")
    }
    
    func testRetrieveScheduledMeetingOnboarding_onFirstTime_shouldSaveCorrectly() async throws {
        let json = ""
        let targetJson = """
            {"ios":{"record":{"currentTip":"initial"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.appsPreferences: [ScheduledMeetingOnboardingKeysEntity.key: try XCTUnwrap(json.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveScheduledMeetingOnBoardingRecord(
            key: ScheduledMeetingOnboardingKeysEntity.key,
            record: ScheduledMeetingOnboardingRecord(currentTip: .initial)
        )
        
        XCTAssertNotNil(repo.userAttributesContainer[.appsPreferences])
        let updatedJsonData = try XCTUnwrap(repo.userAttributesContainer[.appsPreferences]?[ScheduledMeetingOnboardingKeysEntity.key]).sorted()
        XCTAssertEqual(updatedJsonData, try XCTUnwrap(targetJson).sorted())
    }
    
    func testSaveScheduledMeetingOnboarding_onSecondTime_shouldSaveCorrectly() async throws {
        let json = """
            {"ios":{"record":{"currentTip":"initial"}}}
        """.trim
        let targetJson = """
            {"ios":{"record":{"currentTip":"createMeeting"}}}
        """.trim
        let repo = MockUserAttributeRepository(userAttributesContainer: [.appsPreferences: [ScheduledMeetingOnboardingKeysEntity.key: try XCTUnwrap(json?.base64Encoded)]])
        let sut = UserAttributeUseCase(repo: repo)
        
        try await sut.saveScheduledMeetingOnBoardingRecord(
            key: ScheduledMeetingOnboardingKeysEntity.key,
            record: ScheduledMeetingOnboardingRecord(currentTip: .createMeeting)
        )
        
        XCTAssertNotNil(repo.userAttributesContainer[.appsPreferences])
        let updatedJsonData = try XCTUnwrap(repo.userAttributesContainer[.appsPreferences]?[ScheduledMeetingOnboardingKeysEntity.key]).sorted()
        XCTAssertEqual(updatedJsonData, try XCTUnwrap(targetJson).sorted())
    }
}
