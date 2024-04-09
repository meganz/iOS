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
