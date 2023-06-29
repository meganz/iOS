@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ScheduledMeetingOccurrencesViewModelTests: XCTestCase {
    private let router = MockScheduledMeetingOccurrencesRouter()
    private let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: 100))
    private let scheduleMeetingOccurence = ScheduleMeetingOccurence(id: "1", date: "2023/6/12", title: "Meeting Title", time: "12:00")

    func test_cancelEntiryScheduledMeeting_meetingCancelledSuccess() {
        let updatedScheduledMeeting = ScheduledMeetingEntity()
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(updatedScheduledMeeting: updatedScheduledMeeting)
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.cancelScheduledMeeting()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.showSuccessMessageAndDismiss_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func test_cancelEntireScheduledMeeting_meetingCancelledError() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(updatedScheduledMeetingError: ScheduleMeetingErrorEntity.generic)
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.cancelScheduledMeeting()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.showErrorMessage_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledSuccess() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(updatedScheduledMeeting: ScheduledMeetingEntity())
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(chatId: 100), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.selectedOccurrence = scheduleMeetingOccurence
        viewModel.displayOccurrences = [scheduleMeetingOccurence]
        viewModel.occurrences = [ScheduledMeetingOccurrenceEntity()]
        viewModel.cancelScheduledMeetingOccurrence()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.showSuccessMessage_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
    
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledError() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(updatedScheduledMeetingError: ScheduleMeetingErrorEntity.generic)
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.selectedOccurrence = scheduleMeetingOccurence
        viewModel.displayOccurrences = [scheduleMeetingOccurence]
        viewModel.occurrences = [ScheduledMeetingOccurrenceEntity()]
        viewModel.cancelScheduledMeetingOccurrence()
        if XCTWaiter.wait(for: [expectation(description: "Wait for response")], timeout: 0.5) == .timedOut {
            XCTAssertTrue(router.showErrorMessage_calledTimes == 1)
        } else {
            XCTFail("Expected to time out!")
        }
    }
}

final class MockScheduledMeetingOccurrencesRouter: ScheduledMeetingOccurrencesRouting {
    var showErrorMessage_calledTimes = 0
    var showSuccessMessage_calledTimes = 0
    var showSuccessMessageAndDismiss_calledTimes = 0
    
    func showErrorMessage(_ message: String) {
        showErrorMessage_calledTimes += 1
    }
    
    func showSuccessMessage(_ message: String) {
        showSuccessMessage_calledTimes += 1
    }
    
    func showSuccessMessageAndDismiss(_ message: String) {
        showSuccessMessageAndDismiss_calledTimes += 1
    }
}
