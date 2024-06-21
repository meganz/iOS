import Combine
@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentationMock
@testable import MEGATest
import XCTest

final class ScheduleMeetingViewModelTests: XCTestCase {
    
    class Harness {
        let router: MockScheduleMeetingRouter
        let viewConfiguration: any ScheduleMeetingViewConfigurable
        let accountUseCase: MockAccountUseCase
        let preferenceUseCase: MockPreferenceUseCase
        let remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase
        let tracker = MockTracker()
        let sut: ScheduleMeetingViewModel
        
        init(
            router: MockScheduleMeetingRouter = .init(),
            viewConfiguration: some ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
            accountUseCase: MockAccountUseCase = .init(),
            preferenceUseCase: MockPreferenceUseCase = .init(),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase = .disabled
        ) {
            self.router = router
            self.viewConfiguration = viewConfiguration
            self.accountUseCase = accountUseCase
            self.preferenceUseCase = preferenceUseCase
            self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
            sut = .init(
                router: router,
                viewConfiguration: viewConfiguration,
                accountUseCase: accountUseCase,
                preferenceUseCase: preferenceUseCase,
                remoteFeatureFlagUseCase: remoteFeatureFlagUseCase,
                tracker: tracker
            )
        }
        
    }
    
    func testStartDateFormatted_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)
        
        XCTAssertEqual(viewModel.startDateFormatted, dateString)
    }
    
    func testEndDateFormatted_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)
        
        XCTAssertEqual(viewModel.endDateFormatted, dateString)
    }
    
    func testMinimumEndDate_givenStartDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(
            viewModel.minimunEndDate,
            sampleDate.addingTimeInterval(ScheduleMeetingViewModel.Constants.minDurationFiveMinutes)
        )
    }
    
    func testTrimmedMeetingName_givenNameWithSpacesAndNewLines_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "   Test  \n   ")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    
    func testTrimmedMeetingName_givenNameWithoutSpacesAndNewLines_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    
    func testIsNewMeeting_givenNewMeeting_shouldBeTrue() {
        let viewModel = Harness().sut
        XCTAssertTrue(viewModel.isNewMeeting)
    }
    
    func testIsNewMeeting_givenEditingAMeeting_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(type: .edit)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.isNewMeeting)
    }
    
    func testParticipantCount_givenNoParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantsCount, 0)
    }
    
    func testParticipantCount_givenThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantsCount, participantHandles.count)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingName)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingName)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditing_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingLink)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingLink)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowEditingCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingCalendarInvite)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingCalendarInvite)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowAllowNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    
    func testShouldAllowEditingWaitingRoom_givenAllowEditingWaitingRoom_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingWaitingRoom: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingWaitingRoom)
    }
    
    func testShouldAllowEditingWaitingRoom_givenNotAllowEditingWaitingRoom_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingWaitingRoom: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingWaitingRoom)
    }
    
    func testShouldAllowEditingMeetingName_givenAllowedToAddMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingDescription)
    }
    
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingDescription)
    }
    
    func testStartDate_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.startDate, sampleDate)
    }
    
    func testEndDate_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.endDate, sampleDate)
    }
    
    func testMeetingName_givenName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.meetingName, "Test")
    }
    
    func testMeetingDescription_givenDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.meetingDescription, "Test")
    }
    
    func testCalendarInviteEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.calendarInviteEnabled)
    }
    
    func testCalendarInviteEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.calendarInviteEnabled)
    }
    
    func testAllowNonHostsToAddParticipantsEnabled_whenCreatingNewScheduledMeeting_shouldBeFalseByDefault() {
        let viewConfiguration = ScheduleMeetingNewViewConfiguration(chatRoomUseCase: MockChatRoomUseCase(),
                                                                    chatLinkUseCase: MockChatLinkUseCase(),
                                                                    scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    
    func testtWaitingRoomEnabled_whenCreatingNewScheduledMeeting_shouldBeFalseByDefault() {
        let viewModel = Harness(
            viewConfiguration: ScheduleMeetingNewViewConfiguration(
                chatRoomUseCase: MockChatRoomUseCase(),
                chatLinkUseCase: MockChatLinkUseCase(),
                scheduledMeetingUseCase: MockScheduledMeetingUseCase()
            )
        ).sut
        XCTAssertFalse(viewModel.waitingRoomEnabled)
    }
    
    func testWaitingRoomEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.waitingRoomEnabled)
    }
    
    func testWaitingRoomEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.waitingRoomEnabled)
    }
    
    func testMeetingLinkEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.meetingLinkEnabled)
    }
    
    func testMeetingLinkEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.meetingLinkEnabled)
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: true)
        
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndWaitingRoomEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeFalse() {
        let harness = Harness(
            viewConfiguration: MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: true),
            preferenceUseCase: .init(dict: [.waitingRoomWarningBannerDismissed: true])
        )
        
        evaluate(isInverted: true) {
            harness.sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomNotEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false, allowNonHostsToAddParticipantsEnabled: true)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomEnabledAndAllowNonHostsToAddParticipantsNotEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: false)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomNotEnabledAndAllowNonHostsToAddParticipantsNotEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false, allowNonHostsToAddParticipantsEnabled: false)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomDisabledThenEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeFalseThenTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false, allowNonHostsToAddParticipantsEnabled: true)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.waitingRoomEnabled = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testShowWaitingRoomWarningBanner_givenWaitingRoomEnabledAndAllowNonHostsToAddParticipantsDisabledThenEnabled_shouldBeFalseThenTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: false)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
        
        sut.allowNonHostsToAddParticipantsEnabled = true
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    
    func testMeetingNameTooLong_givenLongMeetingName_shouldBeTrue() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertTrue(viewModel.meetingNameTooLong)
    }
    
    func testMeetingNameTooLong_givenShortMeetingName_shouldBeFalse() {
        let name = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.meetingNameTooLong)
    }
    
    func testMeetingDescriptionTooLong_givenLongMeetingDescription_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertTrue(viewModel.meetingDescriptionTooLong)
    }
    
    func testMeetingDescriptionTooLong_givenShortMeetingDescription_shouldBeFalse() {
        let description = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: description)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = description
        XCTAssertFalse(viewModel.meetingDescriptionTooLong)
    }
    
    func testRightBarButtonEnabled_withEmptyMeetingName_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = ""
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testRightBarButtonEnabled_withTooLongMeetingName_shouldBeFalse() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testRightBarButtonEnabled_withTooLongMeetingDescription_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    
    func testParticipantHandleList_withEmptyHandleList_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantHandleList, [])
    }
    
    func testParticipantHandleList_withThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantHandleList, participantHandles)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayTwentyNine_shouldBeTrue() {
        let date = sampleDate(withDay: 29)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(29))
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirty_shouldBeTrue() {
        let date = sampleDate(withDay: 30)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [30])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(30))
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirtyOne_shouldBeTrue() {
        let date = sampleDate(withDay: 31)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [31])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(31))
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDaySixteen_shouldBeTrue() {
        let date = sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionNever_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionDaily_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionWeekly_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testRules_givenInvalidOption_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.rules, ScheduledMeetingRulesEntity(frequency: .invalid))
    }
    
    func testRules_givenDailyOption_shouldBeTrue() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.rules, rules)
    }
    
    func testSubmitButtonTapped_withShowMessageCompletion_shouldMatch() {
        let harness = Harness()
        harness.sut.submitButtonTapped()
        
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
        }
    }
    
    func testSubmitButtonTapped_withShowMessageForOccurrenceCompletion_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageForOccurrence(message: "", occurrence: ScheduledMeetingOccurrenceEntity())
        )
        let harness = Harness(viewConfiguration: viewConfiguration)
        harness.sut.submitButtonTapped()
        
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
            && harness.router.updatedOccurrence_caledTimes == 1
        }
    }
    
    func testSubmitButtonTapped_withShowMessageAndNavigateToInfoCompletion_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageAndNavigateToInfo(message: "", scheduledMeeting: ScheduledMeetingEntity())
        )
        let harness = Harness(viewConfiguration: viewConfiguration)
        harness.sut.submitButtonTapped()
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
            && harness.router.showMeetingInfo_calledTimes == 1
        }
    }
    
    func testStartsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startsDidTap()
        XCTAssertTrue(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    
    func testStartsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDatePickerVisible = true
        viewModel.startsDidTap()
        XCTAssertFalse(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    
    func testEndsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.endsDidTap()
        XCTAssertTrue(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    
    func testEndsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.endDatePickerVisible = true
        viewModel.endsDidTap()
        XCTAssertFalse(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    
    func testCancelDidTap_hasUpdatedDetails_shouldMatch() {
        let harness = Harness()
        harness.sut.meetingName = "Test"
        harness.sut.cancelDidTap()
        evaluate {
            harness.router.dismiss_calledTimes == 1
        }
    }
    
    func testCancelDidTap_noDetailsUpdated_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            meetingName: "Test",
            shouldAllowEditingMeetingName: true
        )
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = "Test 123"
        viewModel.cancelDidTap()
        XCTAssertTrue(viewModel.showDiscardAlert)
    }
    
    func testDiscardChangesTap_onUserTap_shouldMatch() {
        let harness = Harness()
        harness.sut.discardChangesTap()
        evaluate {
            harness.router.dismiss_calledTimes == 1
        }
    }
    
    func testKeepEditingTap_onUserTap_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.keepEditingTap()
        XCTAssertFalse(viewModel.showDiscardAlert)
    }
    
    func testAddParticipantsTap_onUserTap_shouldMatch() {
        let harness = Harness()
        harness.sut.addParticipantsTap()
        XCTAssertEqual(harness.router.showAddParticipants_calledTimes, 1)
    }
    
    func testEndRecurrenceDetailText_withEndDate_shouldMatch() {
        let sampleDate = sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, until: sampleDate, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.endRecurrenceDetailText(), viewModel.dateFormatter.localisedString(from: sampleDate))
    }
    
    func testEndRecurrenceDetailText_withNoEndDate_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(
            viewModel.endRecurrenceDetailText(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        )
    }
    
    func testSubmitButtonTapped_forNewMeeting_shouldTrackEvent() {
        let harness = Harness(viewConfiguration: MockScheduleMeetingViewConfiguration(type: .new))
        
        harness.sut.submitButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingCreateConfirmButtonEvent()
            ]
        )
    }
    
    func testSubmitButtonTapped_forEditMeeting_shouldNotTrackEvent() {
        let harness = Harness(viewConfiguration: MockScheduleMeetingViewConfiguration(type: .edit))
        harness.sut.submitButtonTapped()
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testShowRecurrenceOptionsView_onShow_shouldTrackEvent() {
        let harness = Harness()
        harness.sut.showRecurrenceOptionsView()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingSettingRecurrenceButtonEvent()
            ]
        )
    }
    
    func testOnMeetingLinkEnabledChange_onEnabled_shouldTrackEvent() {
        let harness = Harness()
        
        harness.sut.onMeetingLinkEnabledChange(true)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingSettingEnableMeetingLinkButtonEvent()
            ]
        )
    }
    
    func testOnMeetingLinkEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        
        harness.sut.onMeetingLinkEnabledChange(false)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testOnCalendarInviteEnabledChange_onEnabled_shouldTrackEvent() {
        let harness = Harness()
        harness.sut.onCalendarInviteEnabledChange(true)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingSettingSendCalendarInviteButtonEvent()
            ]
        )
    }
    
    func testOnCalendarInviteEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onCalendarInviteEnabledChange(false)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testOnWaitingRoomEnabledChange_onEnabled_shouldTrackEvent() {
        let harness = Harness()
        harness.sut.onWaitingRoomEnabledChange(true)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                WaitingRoomEnableButtonEvent()
            ]
        )
    }
    
    func testOnWaitingRoomEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onWaitingRoomEnabledChange(false)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testOnAllowNonHostsToAddParticipantsEnabledChange_onEnabled_shouldTrackEvent() {
        let harness = Harness()
        harness.sut.onAllowNonHostsToAddParticipantsEnabledChange(true)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingSettingEnableOpenInviteButtonEvent()
            ]
        )
    }
    
    func testOnAllowNonHostsToAddParticipantsEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onAllowNonHostsToAddParticipantsEnabledChange(false)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    
    func testFreePlanTimeLimitation_durationShorterThan60minutesAndUserIsPro_viewShouldNotBeShown() {
        let viewModel = Harness(accountUseCase: .proI).sut
        let date = Date.now
        viewModel.startDate = date
        viewModel.endDate = date.addingTimeInterval(300)
        XCTAssertFalse(viewModel.showLimitDurationView)
    }
    
    func testFreePlanTimeLimitation_durationLongerThan60minutesAndUserIsPro_viewShouldNotBeShown() {
        let viewModel = Harness(accountUseCase: .proI).sut
        let date = Date.now
        viewModel.startDate = date
        viewModel.endDate = date.addingTimeInterval(3601)
        XCTAssertFalse(viewModel.showLimitDurationView)
    }
    
    @MainActor
    func testFreePlanTimeLimitation_durationShorterThan60minutesAndUserIsFree_viewShouldNotBeShown() async {
        let harness = Harness(
            accountUseCase: .free,
            remoteFeatureFlagUseCase: .enabled
        )
        await harness.sut.viewAppeared()
        let date = Date.now
        harness.sut.startDate = date
        harness.sut.endDate = date.addingTimeInterval(300)
        XCTAssertFalse(harness.sut.showLimitDurationView)
    }
    
    @MainActor
    func testFreePlanTimeLimitation_durationLongerThan60minutesAndUserIsFree_viewShouldBeShown() async {
        let harness = Harness(accountUseCase: .free, remoteFeatureFlagUseCase: .enabled)
        await harness.sut.viewAppeared()
        let date = Date.now
        harness.sut.startDate = date
        harness.sut.endDate = date.addingTimeInterval(3601)
        XCTAssertTrue(harness.sut.showLimitDurationView)
    }
    
    func testFreePlanTimeLimitation_upgradeAccountIsTapped_shouldShowUpgradeAccountView() {
        let harness = Harness(accountUseCase: .free)
        harness.sut.upgradePlansViewTapped()
        XCTAssertEqual(harness.router.upgradeAccount_calledTimes, 1)
    }
    
    func testUpgradeAccount_ButtonTapped_IsTracked() {
        let harness = Harness(accountUseCase: .free)
        harness.sut.upgradePlansViewTapped()
        XTAssertTrackedAnalyticsEventsEqual(harness.tracker.trackedEventIdentifiers, [MockScheduleMeetingViewConfiguration.Event()])
    }
    
    // MARK: - Private methods.
    
    private func tooLongDescription() -> String {
        "MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:: MEGA protects your communications with our end-to-end (user controlled) encryption system providing essential safety assurances:"
    }
    
    private func sampleDate(withDay day: Int = 16) -> Date {
        guard day >= 1 && day <= 31 else {
            fatalError("Unsupported value")
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "\(day)/05/2023")!
    }
}

extension MockAccountUseCase {
    static var free: Self {
        level(.free)
    }
    
    static var proI: Self {
        level(.proI)
    }
    
    static func level(_ proLevel: AccountTypeEntity) -> Self {
        MockAccountUseCase(currentAccountDetails: AccountDetailsEntity.build(proLevel: proLevel))
    }
}

extension MockRemoteFeatureFlagUseCase {
    static var enabled: MockRemoteFeatureFlagUseCase {
        MockRemoteFeatureFlagUseCase(valueToReturn: true)
    }
    
    static var disabled: MockRemoteFeatureFlagUseCase {
        MockRemoteFeatureFlagUseCase(valueToReturn: false)
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
    var upgradeAccount_calledTimes = 0
    
    func showSpinner() {
        showSpinner_calledTimes += 1
    }
    
    func hideSpinner() {
        hideSpinner_calledTimes += 1
    }
    
    func dismiss(animated: Bool) async {
        dismiss_calledTimes += 1
    }
    
    func showSuccess(message: String) {
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
    
    func showUpgradeAccount(_ account: AccountDetailsEntity) {
        upgradeAccount_calledTimes += 1
    }
}
