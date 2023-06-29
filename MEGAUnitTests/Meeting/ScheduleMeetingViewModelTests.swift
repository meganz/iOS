import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ScheduleMeetingViewModelTests: XCTestCase {
    
    func testStartDateFormatted_givenSampleDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)

        XCTAssertEqual(viewModel.startDateFormatted, dateString)
    }
    
    func testEndDateFormatted_givenSampleDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)

        XCTAssertEqual(viewModel.endDateFormatted, dateString)
    }
    
    func testMinimunEndDate_givenStartDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(
            viewModel.minimunEndDate,
            sampleDate.addingTimeInterval(ScheduleMeetingViewModel.Constants.minDurationFiveMinutes)
        )
    }
    
    func testTrimmedMeetingName_givenNameWithSpacesAndNewLines_shouldMatch() throws {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "   Test  \n   ")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    
    func testTrimmedMeetingName_givenNameWithoutSpacesAndNewLines_shouldMatch() throws {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    
    func testIsNewMeeting_givenNewMeeting_shouldBeTrue() throws {
        let viewModel = ScheduleMeetingViewModel()
        XCTAssertTrue(viewModel.isNewMeeting)
    }
    
    func testIsNewMeeting_givenEditingAMeeting_shouldBeFalse() throws {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(type: .edit)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.isNewMeeting)
    }
    
    func testParticipantCount_givenNoParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.participantsCount, 0)
    }
    
    func testParticipantCount_givenThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.participantsCount, participantHandles.count)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingName)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingName)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditing_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingLink)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingLink)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingCalendarInvite)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingCalendarInvite)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowAllowNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowedToAddMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingDescription)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingDescription)
    }
    
    func testStartDate_givenSampleDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.startDate, sampleDate)
    }
    
    func testEndDate_givenSampleDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.endDate, sampleDate)
    }
    
    func testMeetingName_givenName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.meetingName, "Test")
    }
    
    func testMeetingDescription_givenDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "Test")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.meetingDescription, "Test")
    }
    
    func testCalendarInviteEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.calendarInviteEnabled)
    }
    
    func testCalendarInviteEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.calendarInviteEnabled)
    }
    
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    
    func testMeetingLinkEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: true)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertTrue(viewModel.meetingLinkEnabled)
    }
    
    func testMeetingLinkEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: false)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertFalse(viewModel.meetingLinkEnabled)
    }
    
    func testMeetingNameTooLong_givenLongMeetingName_shouldBeTrue() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingName = name
        XCTAssertTrue(viewModel.meetingNameTooLong)
    }
    
    func testMeetingNameTooLong_givenShortMeetingName_shouldBeFalse() {
        let name = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.meetingNameTooLong)
    }
    
    func testMeetingDescriptionTooLong_givenLongMeetingDescription_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertTrue(viewModel.meetingDescriptionTooLong)
    }
    
    func testMeetingDescriptionTooLong_givenShortMeetingDescription_shouldBeFalse() {
        let description = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: description)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingDescription = description
        XCTAssertFalse(viewModel.meetingDescriptionTooLong)
    }
    
    func testRightBarButtonEnabled_withEmptyMeetingName_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingDescription = ""
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testRightBarButtonEnabled_withTooLongMeetingName_shouldBeFalse() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: name)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testRightBarButtonEnabled_withTooLongMeetingDescription_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testParticipantHandleList_withEmptyHandleList_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.participantHandleList, [])
    }
    
    func testParticipantHandleList_withThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.participantHandleList, participantHandles)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayTwentyNine_shouldBeTrue() throws {
        let date = try sampleDate(withDay: 29)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayTwentyNineSelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirty_shouldBeTrue() throws {
        let date = try sampleDate(withDay: 30)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [30])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtySelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirtyOne_shouldBeTrue() throws {
        let date = try sampleDate(withDay: 31)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [31])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtyFirstSelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDaySixteen_shouldBeTrue() throws {
        let date = try sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startDate = date
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionNever_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionDaily_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionWeekly_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testRules_givenInvalidOption_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.rules, ScheduledMeetingRulesEntity(frequency: .invalid))
    }
    
    func testRules_givenDailyOption_shouldBeTrue() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.rules, rules)
    }
    
    func testSubmitButtonTapped_withShowMessageCompletion_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: MockScheduleMeetingViewConfiguration())
        viewModel.submitButtonTapped()
        
        evaluate {
            router.showSpinner_calledTimes == 1
            && router.hideSpinner_calledTimes == 1
            && router.dismiss_calledTimes == 1
            && router.showSuccessMessage_calledTimes == 1
        }
    }
    
    func testSubmitButtonTapped_withShowMessageForOccurrenceCompletion_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageForOccurrence(message: "", occurrence: ScheduledMeetingOccurrenceEntity())
        )
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: viewConfiguration)
        viewModel.submitButtonTapped()
        
        evaluate {
            router.showSpinner_calledTimes == 1
            && router.hideSpinner_calledTimes == 1
            && router.dismiss_calledTimes == 1
            && router.showSuccessMessage_calledTimes == 1
            && router.updatedOccurrence_caledTimes == 1
        }
    }
    
    func testSubmitButtonTapped_withShowMessageAndNavigateToInfoCompletion_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageAndNavigateToInfo(message: "", scheduledMeeting: ScheduledMeetingEntity())
        )
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: viewConfiguration)
        viewModel.submitButtonTapped()
        
        evaluate {
            router.showSpinner_calledTimes == 1
            && router.hideSpinner_calledTimes == 1
            && router.dismiss_calledTimes == 1
            && router.showSuccessMessage_calledTimes == 1
            && router.showMeetingInfo_calledTimes == 1
        }
    }
    
    func testStartsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startsDidTap()
        XCTAssertTrue(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    
    func testStartsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.startDatePickerVisible = true
        viewModel.startsDidTap()
        XCTAssertFalse(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    
    func testEndsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.endsDidTap()
        XCTAssertTrue(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    
    func testEndsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.endDatePickerVisible = true
        viewModel.endsDidTap()
        XCTAssertFalse(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    
    func testCancelDidTap_hasUpdatedDetails_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: viewConfiguration)
        viewModel.meetingName = "Test"
        viewModel.cancelDidTap()
        evaluate {
            router.dismiss_calledTimes == 1
        }
    }
    
    func testCancelDidTap_noDetailsUpdated_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            meetingName: "Test",
            shouldAllowEditingMeetingName: true
        )
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.meetingName = "Test 123"
        viewModel.cancelDidTap()
        XCTAssertTrue(viewModel.showDiscardAlert)
    }
    
    func testDiscardChangesTap_onUserTap_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: viewConfiguration)
        viewModel.discardChangesTap()
        evaluate {
            router.dismiss_calledTimes == 1
        }
    }
    
    func testKeepEditingTap_onUserTap_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        viewModel.keepEditingTap()
        XCTAssertFalse(viewModel.showDiscardAlert)
    }
    
    func testAddParticipantsTap_onUserTap_shouldMatch() {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = ScheduleMeetingViewModel(router: router, viewConfiguration: viewConfiguration)
        viewModel.addParticipantsTap()
        XCTAssertEqual(router.showAddParticipants_calledTimes, 1)
    }
    
    func testEndRecurrenceDetailText_withEndDate_shouldMatch() throws {
        let sampleDate = try sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, until: sampleDate, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(viewModel.endRecurrenceDetailText(), viewModel.dateFormatter.localisedString(from: sampleDate))
    }
    
    func testEndRecurrenceDetailText_withNoEndDate_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = ScheduleMeetingViewModel(viewConfiguration: viewConfiguration)
        XCTAssertEqual(
            viewModel.endRecurrenceDetailText(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        )
    }
    
    // MARK: - Private methods.
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
    
    private func tooLongDescription() -> String {
        "MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:"
    }

    private func sampleDate(withDay day: Int = 16) throws -> Date {
        guard day >= 1 && day <= 31 else { throw GenericErrorEntity() }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return try XCTUnwrap(dateFormatter.date(from: "\(day)/05/2023"))
    }
}

final class MockScheduleMeetingRouter: ScheduleMeetingRouting {
    var showSpinner_calledTimes = 0
    var hideSpinner_calledTimes = 0
    var dismiss_calledTimes = 0
    var showSuccessMessage_calledTimes = 0
    var updatedOccurrence_caledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var discardChanges_calledTimes = 0
    var showAddParticipants_calledTimes = 0
    var scheduleMettingRulesEntityPublisher = PassthroughSubject<ScheduledMeetingRulesEntity, Never>()
    var endRecurrenceScheduleMettingRulesEntityPublisher = PassthroughSubject<ScheduledMeetingRulesEntity, Never>()
    var updatedMeeting_calledTimes = 0

    func showSpinner() {
        showSpinner_calledTimes += 1
    }
    
    func hideSpinner() {
        hideSpinner_calledTimes += 1
    }
    
    func dismiss(animated: Bool) async {
        dismiss_calledTimes += 1
    }
    
    func showSuccess(message: String) async {
        showSuccessMessage_calledTimes += 1
    }
    
    func updated(occurrence: ScheduledMeetingOccurrenceEntity) {
        updatedOccurrence_caledTimes += 1
    }
    
    func showMeetingInfo(for scheduledMeeting: MEGADomain.ScheduledMeetingEntity) {
        showMeetingInfo_calledTimes += 1
    }
    
    func discardChanges() {
        discardChanges_calledTimes += 1
    }
    
    func showAddParticipants(alreadySelectedUsers: [MEGADomain.UserEntity], newSelectedUsers: @escaping (([MEGADomain.UserEntity]?) -> Void)) {
        showAddParticipants_calledTimes += 1
    }
    
    func showRecurrenceOptionsView(rules: ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<ScheduledMeetingRulesEntity, Never>? {
        scheduleMettingRulesEntityPublisher.eraseToAnyPublisher()
    }
    
    func showEndRecurrenceOptionsView(rules: MEGADomain.ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<MEGADomain.ScheduledMeetingRulesEntity, Never>? {
        endRecurrenceScheduleMettingRulesEntityPublisher.eraseToAnyPublisher()
    }
    
    func updated(meeting: ScheduledMeetingEntity) {
        updatedMeeting_calledTimes += 1
    }
}
