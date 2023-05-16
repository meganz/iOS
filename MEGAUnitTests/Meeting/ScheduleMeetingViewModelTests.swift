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
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssertTrue(router.showMeetingInfo_calledTimes == 1)
        } else {
            XCTFail()
        }
    }
    
    func test_scheduleMeetingCreationComplete_errorFound_viewShouldDismiss() {
        let router = MockScheduleMeetingRouter()
        let scheduleMeetingUseCase = MockScheduledMeetingUseCase(createdScheduledMeetingError: ScheduleMeetingErrorEntity.invalidArguments)
        let viewModel = ScheduleMeetingViewModel(router: router, scheduledMeetingUseCase: scheduleMeetingUseCase, chatLinkUseCase: MockChatLinkUseCase(), chatRoomUseCase: MockChatRoomUseCase())
        
        viewModel.createDidTap()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut{
            XCTAssertTrue(router.hideSpinner_calledTimes == 1)
        } else {
            XCTFail()
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
    
    private func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}

final class MockScheduleMeetingRouter: ScheduleMeetingRouting {
    var showSpinner_calledTimes = 0
    var hideSpinner_calledTimes = 0
    var showMeetingInfo_calledTimes = 0
    var discardChanges_calledTimes = 0
    var showAddParticipants_calledTimes = 0
    var scheduleMettingRulesEntityPublisher: PassthroughSubject<ScheduledMeetingRulesEntity, Never>?
    
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
}
