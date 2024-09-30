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
    
    @MainActor
    final class Harness {
        let router = MockScheduleMeetingRouter()
        let viewConfiguration: any ScheduleMeetingViewConfigurable
        let accountUseCase: MockAccountUseCase
        let preferenceUseCase: MockPreferenceUseCase
        let remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase
        let tracker = MockTracker()
        let sut: ScheduleMeetingViewModel
        
        init(
            viewConfiguration: some ScheduleMeetingViewConfigurable = MockScheduleMeetingViewConfiguration(),
            accountUseCase: MockAccountUseCase = .init(),
            preferenceUseCase: MockPreferenceUseCase = .init(),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase = .disabled
        ) {
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
                tracker: tracker,
                chatRoomUseCase: MockChatRoomUseCase(),
                chatUseCase: MockChatUseCase(),
                shareLinkHandler: { _ in }
            )
        }
    }
    
    @MainActor
    func testStartDateFormatted_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)
        
        XCTAssertEqual(viewModel.startDateFormatted, dateString)
    }
    @MainActor
    func testEndDateFormatted_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        let dateString = viewModel.dateFormatter.localisedString(from: sampleDate)
        + " "
        + viewModel.timeFormatter.localisedString(from: sampleDate)
        
        XCTAssertEqual(viewModel.endDateFormatted, dateString)
    }
    @MainActor
    func testMinimumEndDate_givenStartDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(
            viewModel.minimunEndDate,
            sampleDate.addingTimeInterval(ScheduleMeetingViewModel.Constants.minDurationFiveMinutes)
        )
    }
    @MainActor
    func testTrimmedMeetingName_givenNameWithSpacesAndNewLines_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "   Test  \n   ")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    @MainActor
    func testTrimmedMeetingName_givenNameWithoutSpacesAndNewLines_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.trimmedMeetingName, "Test")
    }
    @MainActor
    func testIsNewMeeting_givenNewMeeting_shouldBeTrue() {
        let viewModel = Harness().sut
        XCTAssertTrue(viewModel.isNewMeeting)
    }
    @MainActor
    func testIsNewMeeting_givenEditingAMeeting_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(type: .edit)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.isNewMeeting)
    }
    @MainActor
    func testParticipantCount_givenNoParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantsCount, 0)
    }
    @MainActor
    func testParticipantCount_givenThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantsCount, participantHandles.count)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingName)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingMeetingName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingName: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingName)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditing_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingRecurrenceOption)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingRecurrenceOption: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingRecurrenceOption)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedEditingEndRecurrenceOption_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingEndRecurrenceOption: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingEndRecurrenceOption)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditingMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingLink)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingLink_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingLink: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingLink)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditingParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingParticipants)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingParticipants: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingParticipants)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowEditingCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingCalendarInvite)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedToCalendarInvite_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingCalendarInvite: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingCalendarInvite)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowAllowNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedNonHostsToAddParticipants_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingAllowNonHostsToAddParticipants: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingAllowNonHostsToAddParticipants)
    }
    @MainActor
    func testShouldAllowEditingWaitingRoom_givenAllowEditingWaitingRoom_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingWaitingRoom: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingWaitingRoom)
    }
    @MainActor
    func testShouldAllowEditingWaitingRoom_givenNotAllowEditingWaitingRoom_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingWaitingRoom: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingWaitingRoom)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenAllowedToAddMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.shouldAllowEditingMeetingDescription)
    }
    @MainActor
    func testShouldAllowEditingMeetingName_givenNotAllowedToEditMeetingDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(shouldAllowEditingMeetingDescription: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.shouldAllowEditingMeetingDescription)
    }
    @MainActor
    func testStartDate_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(startDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.startDate, sampleDate)
    }
    @MainActor
    func testEndDate_givenSampleDate_shouldMatch() {
        let sampleDate = sampleDate()
        let viewConfiguration = MockScheduleMeetingViewConfiguration(endDate: sampleDate)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.endDate, sampleDate)
    }
    @MainActor
    func testMeetingName_givenName_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.meetingName, "Test")
    }
    @MainActor
    func testMeetingDescription_givenDescription_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "Test")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.meetingDescription, "Test")
    }
    @MainActor
    func testCalendarInviteEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.calendarInviteEnabled)
    }
    @MainActor
    func testCalendarInviteEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(calendarInviteEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.calendarInviteEnabled)
    }
    @MainActor
    func testAllowNonHostsToAddParticipantsEnabled_whenCreatingNewScheduledMeeting_shouldBeFalseByDefault() {
        let viewConfiguration = ScheduleMeetingNewViewConfiguration(chatRoomUseCase: MockChatRoomUseCase(),
                                                                    chatLinkUseCase: MockChatLinkUseCase(),
                                                                    scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    @MainActor
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    @MainActor
    func testAllowNonHostsToAddParticipantsEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(allowNonHostsToAddParticipantsEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.allowNonHostsToAddParticipantsEnabled)
    }
    @MainActor
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
    @MainActor
    func testWaitingRoomEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.waitingRoomEnabled)
    }
    @MainActor
    func testWaitingRoomEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.waitingRoomEnabled)
    }
    @MainActor
    func testMeetingLinkEnabled_givenSettingIsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: true)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertTrue(viewModel.meetingLinkEnabled)
    }
    @MainActor
    func testMeetingLinkEnabled_givenSettingIsDisabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingLinkEnabled: false)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertFalse(viewModel.meetingLinkEnabled)
    }
    @MainActor
    func testShowWaitingRoomWarningBanner_givenWaitingRoomEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: true)
        
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    @MainActor
    func testShowWaitingRoomWarningBanner_givenBannerDismissedBeforeAndWaitingRoomEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeFalse() {
        let harness = Harness(
            viewConfiguration: MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: true),
            preferenceUseCase: .init(dict: [.waitingRoomWarningBannerDismissed: true])
        )
        
        evaluate(isInverted: true) {
            harness.sut.showWaitingRoomWarningBanner == true
        }
    }
    @MainActor
    func testShowWaitingRoomWarningBanner_givenWaitingRoomNotEnabledAndAllowNonHostsToAddParticipantsEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false, allowNonHostsToAddParticipantsEnabled: true)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    @MainActor
    func testShowWaitingRoomWarningBanner_givenWaitingRoomEnabledAndAllowNonHostsToAddParticipantsNotEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: true, allowNonHostsToAddParticipantsEnabled: false)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    @MainActor
    func testShowWaitingRoomWarningBanner_givenWaitingRoomNotEnabledAndAllowNonHostsToAddParticipantsNotEnabled_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(waitingRoomEnabled: false, allowNonHostsToAddParticipantsEnabled: false)
        let sut = Harness(viewConfiguration: viewConfiguration).sut
        
        evaluate(isInverted: true) {
            sut.showWaitingRoomWarningBanner == true
        }
    }
    @MainActor
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
    @MainActor
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
    @MainActor
    func testMeetingNameTooLong_givenLongMeetingName_shouldBeTrue() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertTrue(viewModel.meetingNameTooLong)
    }
    @MainActor
    func testMeetingNameTooLong_givenShortMeetingName_shouldBeFalse() {
        let name = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingName: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.meetingNameTooLong)
    }
    @MainActor
    func testMeetingDescriptionTooLong_givenLongMeetingDescription_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertTrue(viewModel.meetingDescriptionTooLong)
    }
    @MainActor
    func testMeetingDescriptionTooLong_givenShortMeetingDescription_shouldBeFalse() {
        let description = "Test"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: description)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = description
        XCTAssertFalse(viewModel.meetingDescriptionTooLong)
    }
    @MainActor
    func testRightBarButtonEnabled_withEmptyMeetingName_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = ""
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    @MainActor
    func testRightBarButtonEnabled_withTooLongMeetingName_shouldBeFalse() {
        let name = "MEGA protects your communications with our end-to-end (user controlled)"
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: name)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = name
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    @MainActor
    func testRightBarButtonEnabled_withTooLongMeetingDescription_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(meetingDescription: "")
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingDescription = tooLongDescription()
        XCTAssertFalse(viewModel.isRightBarButtonEnabled)
    }
    @MainActor
    func testParticipantHandleList_withEmptyHandleList_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: [])
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantHandleList, [])
    }
    @MainActor
    func testParticipantHandleList_withThreeParticipants_shouldMatch() {
        let participantHandles: [HandleEntity] = [100, 101, 102]
        let viewConfiguration = MockScheduleMeetingViewConfiguration(participantHandleList: participantHandles)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.participantHandleList, participantHandles)
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayTwentyNine_shouldBeTrue() {
        let date = sampleDate(withDay: 29)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(29))
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirty_shouldBeTrue() {
        let date = sampleDate(withDay: 30)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [30])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(30))
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirtyOne_shouldBeTrue() {
        let date = sampleDate(withDay: 31)
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [31])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.Scheduled.Create.MonthlyRecurrenceOption.BeyondTheLastDayOfTheMonthSelected.footNote(31))
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDaySixteen_shouldBeTrue() {
        let date = sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDate = date
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionNever_shouldBeFalse() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionDaily_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    @MainActor
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionWeekly_shouldBeFalse() {
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    @MainActor
    func testRules_givenInvalidOption_shouldBeTrue() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.rules, ScheduledMeetingRulesEntity(frequency: .invalid))
    }
    @MainActor
    func testRules_givenDailyOption_shouldBeTrue() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.rules, rules)
    }
    @MainActor
    func testSubmitButtonTapped_withShowMessageCompletion_shouldMatch() async {
        let harness = Harness()
        await harness.sut.submitButtonTapped()
        
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
        }
    }
    @MainActor
    func testSubmitButtonTapped_withShowMessageForOccurrenceCompletion_shouldMatch() async {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageForOccurrence(
                message: "",
                occurrence: ScheduledMeetingOccurrenceEntity(),
                parent: ScheduledMeetingEntity()
            )
        )
        let harness = Harness(viewConfiguration: viewConfiguration)
        await harness.sut.submitButtonTapped()
        
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
            && harness.router.updatedOccurrence_caledTimes == 1
        }
    }
    @MainActor
    func testSubmitButtonTapped_withShowMessageAndNavigateToInfoCompletion_shouldMatch() async {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            completion: .showMessageAndNavigateToInfo(message: "", scheduledMeeting: ScheduledMeetingEntity())
        )
        let harness = Harness(viewConfiguration: viewConfiguration)
        await harness.sut.submitButtonTapped()
        evaluate {
            harness.router.showSpinner_calledTimes == 1
            && harness.router.hideSpinner_calledTimes == 1
            && harness.router.dismiss_calledTimes == 1
            && harness.router.showSuccessMessage_calledTimes == 1
            && harness.router.showMeetingInfo_calledTimes == 1
        }
    }
    @MainActor
    func testStartsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startsDidTap()
        XCTAssertTrue(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    @MainActor
    func testStartsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.startDatePickerVisible = true
        viewModel.startsDidTap()
        XCTAssertFalse(viewModel.startDatePickerVisible)
        XCTAssertFalse(viewModel.endDatePickerVisible)
    }
    @MainActor
    func testEndsDidTap_givenThePickerNotShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.endsDidTap()
        XCTAssertTrue(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    @MainActor
    func testEndsDidTap_givenThePickerShown_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.endDatePickerVisible = true
        viewModel.endsDidTap()
        XCTAssertFalse(viewModel.endDatePickerVisible)
        XCTAssertFalse(viewModel.startDatePickerVisible)
    }
    @MainActor
    func testCancelDidTap_hasUpdatedDetails_shouldMatch() async {
        let harness = Harness()
        harness.sut.meetingName = "Test"
        await harness.sut.cancelDidTap()
        evaluate {
            harness.router.dismiss_calledTimes == 1
        }
    }
    @MainActor
    func testCancelDidTap_noDetailsUpdated_shouldMatch() async {
        let viewConfiguration = MockScheduleMeetingViewConfiguration(
            meetingName: "Test",
            shouldAllowEditingMeetingName: true
        )
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.meetingName = "Test 123"
        await viewModel.cancelDidTap()
        XCTAssertTrue(viewModel.showDiscardAlert)
    }
    @MainActor
    func testDiscardChangesTap_onUserTap_shouldMatch() {
        let harness = Harness()
        harness.sut.discardChangesTap()
        evaluate {
            harness.router.dismiss_calledTimes == 1
        }
    }
    @MainActor
    func testKeepEditingTap_onUserTap_shouldMatch() {
        let viewConfiguration = MockScheduleMeetingViewConfiguration()
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        viewModel.keepEditingTap()
        XCTAssertFalse(viewModel.showDiscardAlert)
    }
    @MainActor
    func testAddParticipantsTap_onUserTap_shouldMatch() {
        let harness = Harness()
        harness.sut.addParticipantsTap()
        XCTAssertEqual(harness.router.showAddParticipants_calledTimes, 1)
    }
    @MainActor
    func testEndRecurrenceDetailText_withEndDate_shouldMatch() {
        let sampleDate = sampleDate()
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, until: sampleDate, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(viewModel.endRecurrenceDetailText(), viewModel.dateFormatter.localisedString(from: sampleDate))
    }
    @MainActor
    func testEndRecurrenceDetailText_withNoEndDate_shouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [29])
        let viewConfiguration = MockScheduleMeetingViewConfiguration(rules: rules)
        let viewModel = Harness(viewConfiguration: viewConfiguration).sut
        XCTAssertEqual(
            viewModel.endRecurrenceDetailText(),
            Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never
        )
    }
    @MainActor
    func testSubmitButtonTapped_forNewMeeting_shouldTrackEvent() async {
        let harness = Harness(viewConfiguration: MockScheduleMeetingViewConfiguration(type: .new))
        
        await harness.sut.submitButtonTapped()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingCreateConfirmButtonEvent()
            ]
        )
    }
    @MainActor
    func testSubmitButtonTapped_forEditMeeting_shouldNotTrackEvent() async {
        let harness = Harness(viewConfiguration: MockScheduleMeetingViewConfiguration(type: .edit))
        await harness.sut.submitButtonTapped()
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    @MainActor
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
    @MainActor
    func testOnMeetingLinkEnabledChange_onEnabled_shouldTrackEvent() {
        let harness = Harness()
        
        harness.sut.onMeetingLinkEnabledChange(true)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: [
                MockScheduleMeetingViewConfiguration.Event(eventName: "meetingLinkEnabled")
            ]
        )
    }
    @MainActor
    func testOnMeetingLinkEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        
        harness.sut.onMeetingLinkEnabledChange(false)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    @MainActor
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
    @MainActor
    func testOnCalendarInviteEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onCalendarInviteEnabledChange(false)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    @MainActor
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
    @MainActor
    func testOnWaitingRoomEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onWaitingRoomEnabledChange(false)
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    @MainActor
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
    @MainActor
    func testOnAllowNonHostsToAddParticipantsEnabledChange_onDisabled_shouldNotTrackEvent() {
        let harness = Harness()
        harness.sut.onAllowNonHostsToAddParticipantsEnabledChange(false)
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: harness.tracker.trackedEventIdentifiers,
            with: []
        )
    }
    @MainActor
    func testFreePlanTimeLimitation_durationShorterThan60minutesAndUserIsPro_viewShouldNotBeShown() {
        let viewModel = Harness(accountUseCase: .proI).sut
        let date = Date.now
        viewModel.startDate = date
        viewModel.endDate = date.addingTimeInterval(300)
        XCTAssertFalse(viewModel.showLimitDurationView)
    }
    @MainActor
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
    @MainActor
    func testFreePlanTimeLimitation_upgradeAccountIsTapped_shouldShowUpgradeAccountView() {
        let harness = Harness(accountUseCase: .free)
        harness.sut.upgradePlansViewTapped()
        XCTAssertEqual(harness.router.upgradeAccount_calledTimes, 1)
    }
    @MainActor
    func testUpgradeAccount_ButtonTapped_IsTracked() {
        let harness = Harness(accountUseCase: .free)
        harness.sut.upgradePlansViewTapped()
        XCTAssertTrackedAnalyticsEventsEqual(harness.tracker.trackedEventIdentifiers, [MockScheduleMeetingViewConfiguration.Event()])
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
