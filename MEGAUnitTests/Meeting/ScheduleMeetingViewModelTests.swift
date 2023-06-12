import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock
import Combine

final class ScheduleMeetingViewModelTests: XCTestCase {
    func test_configureCreateButton_titleEmpty_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingName = ""
        XCTAssertTrue(viewModel.createButtonEnabled == false)
    }
    
    func test_configureCreateButton_titleLenghtExceeded_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingName = randomString(length: ScheduleMeetingViewModel.Constants.meetingNameMaxLenght + 1)
        XCTAssertTrue(viewModel.createButtonEnabled == false)
    }
    
    func test_configureCreateButton_descriptionLenghtExceeded_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingDescription = randomString(length: ScheduleMeetingViewModel.Constants.meetingDescriptionMaxLenght + 1)
        XCTAssertTrue(viewModel.createButtonEnabled == false)
    }
    
    func test_configureCreateButton_titleNotEmpty_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingName = randomString(length: ScheduleMeetingViewModel.Constants.meetingNameMaxLenght - 1)
        XCTAssertTrue(viewModel.createButtonEnabled == true)
    }
    
    func test_configureCreateButton_titleNotEmptyAndDescriptionLenghtExceeded_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingName = randomString(length: ScheduleMeetingViewModel.Constants.meetingNameMaxLenght - 1)
        viewModel.meetingDescription = randomString(length: ScheduleMeetingViewModel.Constants.meetingDescriptionMaxLenght + 1)
        XCTAssertTrue(viewModel.createButtonEnabled == false)
    }
    
    func test_configureCreateButton_titleNotEmptyAndDescriptionLenghtNotExceeded_buttonShouldBeDisabled() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.meetingName = randomString(length: ScheduleMeetingViewModel.Constants.meetingNameMaxLenght - 1)
        viewModel.meetingDescription = randomString(length: ScheduleMeetingViewModel.Constants.meetingDescriptionMaxLenght - 1)
        XCTAssertTrue(viewModel.createButtonEnabled == true)
    }
    
    func test_scheduleMeetingCreationComplete_completedSuccessfully_viewShouldDismiss() {
        let router = MockScheduleMeetingRouter()
        let viewModel = ScheduleMeetingViewModel(router: router, scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.createDidTap()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.showMeetingInfo_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func test_scheduleMeetingCreationComplete_errorFound_viewShouldDismiss() {
        let router = MockScheduleMeetingRouter()
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(createdScheduledMeetingError: ScheduleMeetingErrorEntity.invalidArguments)
        let viewModel = ScheduleMeetingViewModel(router: router, scheduledMeetingUseCase: scheduleMeetingUseCase, chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.createDidTap()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.hideSpinner_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func test_cancelButton_didTap_confirmDiscardAlertShown() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.cancelDidTap()
        XCTAssertTrue(viewModel.showDiscardAlert == true)
    }
    
    func test_discardButton_confirmDiscardChanges_viewShouldDismiss() {
        let router = MockScheduleMeetingRouter()
        let viewModel = ScheduleMeetingViewModel(router: router, scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.discardChangesTap()
        XCTAssertTrue(router.discardChanges_calledTimes == 1)
    }
    
    func test_discardButton_keepEditing_confirmDiscardAlertHide() {
        let viewModel = ScheduleMeetingViewModel(router: MockScheduleMeetingRouter(), scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.keepEditingTap()
        XCTAssertTrue(viewModel.showDiscardAlert == false)
    }
    
    func test_addParticipantButton__confirmDiscardAlertShown() {
        let router = MockScheduleMeetingRouter()
        let viewModel = ScheduleMeetingViewModel(router: router, scheduledMeetingUseCase: MockScheduledMeetingUseCase(), chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.addParticipantsTap()
        XCTAssertTrue(router.showAddParticipants_calledTimes == 1)
    }
    
    func testCreateDidTap_neverReccurrence_createScheduleMeetingEntityshouldBeNil() {
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase()
        let viewModel = ScheduleMeetingViewModel(scheduledMeetingUseCase: scheduleMeetingUseCase)
        viewModel.createDidTap()
        XCTAssert(scheduleMeetingUseCase.createScheduleMeetingEntity == nil)
    }
    
    func testCreateDidTap_dailyReccurrence_createScheduleMeetingEntityRulesShouldMatch() {
        let rules = ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7))
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase()
        let viewModel = ScheduleMeetingViewModel(rules: rules, scheduledMeetingUseCase: scheduleMeetingUseCase)
        let predicate = NSPredicate { _, _ in
            scheduleMeetingUseCase.createScheduleMeetingEntity?.rules == rules
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        viewModel.createDidTap()
        wait(for: [expectation], timeout: 6)
    }
    
    func testCreateDidTap_weeklyReccurrence_createScheduleMeetingEntityRulesShouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        let rules = ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [2])
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase()
        let viewModel = ScheduleMeetingViewModel(rules: rules, scheduledMeetingUseCase: scheduleMeetingUseCase)
        viewModel.startDate = date
        let predicate = NSPredicate { _, _ in
            scheduleMeetingUseCase.createScheduleMeetingEntity?.rules == rules
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        viewModel.createDidTap()
        wait(for: [expectation], timeout: 6)
    }
    
    func testCreateDidTap_monthlyReccurrence_createScheduleMeetingEntityRulesShouldMatch() throws {
        let date = try XCTUnwrap(sampleDate())
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly, monthDayList: [16])
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase()
        let viewModel = ScheduleMeetingViewModel(rules: rules, scheduledMeetingUseCase: scheduleMeetingUseCase)
        viewModel.startDate = date
        let predicate = NSPredicate { _, _ in
            scheduleMeetingUseCase.createScheduleMeetingEntity?.rules == rules
        }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        viewModel.createDidTap()
        wait(for: [expectation], timeout: 6)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayTwentyNine_shouldBeTrue() throws {
        let date = try XCTUnwrap(sampleDate(withDay: 29))
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewModel = ScheduleMeetingViewModel(rules: rules)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayTwentyNineSelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirty_shouldBeTrue() throws {
        let date = try XCTUnwrap(sampleDate(withDay: 30))
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewModel = ScheduleMeetingViewModel(rules: rules)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtySelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDayThirtyOne_shouldBeTrue() throws {
        let date = try XCTUnwrap(sampleDate(withDay: 31))
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewModel = ScheduleMeetingViewModel(rules: rules)
        viewModel.startDate = date
        XCTAssert(viewModel.monthlyRecurrenceFootnoteViewText == Strings.Localizable.Meetings.ScheduleMeeting.Create.MonthlyRecurrenceOption.DayThirtyFirstSelected.footNote)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionMonthlyDaySixteen_shouldBeTrue() throws {
        let date = try XCTUnwrap(sampleDate())
        let rules = ScheduledMeetingRulesEntity(frequency: .monthly)
        let viewModel = ScheduleMeetingViewModel(rules: rules)
        viewModel.startDate = date
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionNever_shouldBeFalse() {
        let viewModel = ScheduleMeetingViewModel(rules: ScheduledMeetingRulesEntity(frequency: .invalid))
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionDaily_shouldBeFalse() {
        let viewModel = ScheduleMeetingViewModel(rules: ScheduledMeetingRulesEntity(frequency: .daily, weekDayList: Array(1...7)))
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testShowMonthlyRecurrenceFootnoteView_recurrenceOptionWeekly_shouldBeFalse() {
        let viewModel = ScheduleMeetingViewModel(rules: ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1]))
        XCTAssertNil(viewModel.monthlyRecurrenceFootnoteViewText)
    }
    
    func testEndRecurrenceDetailText_untilDateIsNotSet_shouldShowNever() {
        let viewModel = ScheduleMeetingViewModel(rules: ScheduledMeetingRulesEntity(frequency: .weekly, weekDayList: [1]))
        XCTAssertEqual(viewModel.endRecurrenceDetailText(), Strings.Localizable.Meetings.ScheduleMeeting.Create.SelectedRecurrenceOption.never)
    }
    
    func testEndRecurrenceDetailText_untilDateIsSet_shouldShowDate() throws {
        let date = try XCTUnwrap(sampleDate(withDay: 31))
        let viewModel = ScheduleMeetingViewModel(rules: ScheduledMeetingRulesEntity(until: date))
        XCTAssertEqual(viewModel.endRecurrenceDetailText(), viewModel.dateFormatter.localisedString(from: try XCTUnwrap(viewModel.rules.until)))
    }

    // MARK: - Private methods.
    
    private func sampleDate(withDay day: Int = 16) -> Date? {
        guard day >= 1 && day <= 31 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        return dateFormatter.date(from: "\(day)/05/2023")
    }
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }
}

final class MockScheduleMeetingRouter: ScheduleMeetingRouting {
    var showSpinner_calledTimes = 0
    var hideSpinner_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var discardChanges_calledTimes = 0
    var showAddParticipants_calledTimes = 0
    var scheduleMettingRulesEntityPublisher: PassthroughSubject<ScheduledMeetingRulesEntity, Never>?
    var endRecurrenceScheduleMettingRulesEntityPublisher: PassthroughSubject<ScheduledMeetingRulesEntity, Never>?

    func showSpinner() {
        showSpinner_calledTimes += 1
    }
    
    func hideSpinner() {
        hideSpinner_calledTimes += 1
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
        scheduleMettingRulesEntityPublisher?.eraseToAnyPublisher()
    }
    
    func showEndRecurrenceOptionsView(rules: MEGADomain.ScheduledMeetingRulesEntity, startDate: Date) -> AnyPublisher<MEGADomain.ScheduledMeetingRulesEntity, Never>? {
        endRecurrenceScheduleMettingRulesEntityPublisher?.eraseToAnyPublisher()
    }
}
