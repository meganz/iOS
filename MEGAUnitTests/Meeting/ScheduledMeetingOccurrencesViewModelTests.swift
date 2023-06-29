import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ScheduledMeetingOccurrencesViewModelTests: XCTestCase {
    private let router = MockScheduledMeetingOccurrencesRouter()
    private let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: 100))
    private let scheduleMeetingOccurence = ScheduleMeetingOccurence(id: "1", date: "2023/6/12", title: "Meeting Title", time: "12:00")

    func test_cancelEntiryScheduledMeeting_meetingCancelledSuccess() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.cancelScheduledMeeting()
        
        evaluate { self.router.showSuccessMessageAndDismiss_calledTimes == 1 }
    }
    
    func test_cancelEntireScheduledMeeting_meetingCancelledError() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduleMeetingError: ScheduleMeetingErrorEntity.generic)
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.cancelScheduledMeeting()
        evaluate { self.router.showErrorMessage_calledTimes == 1 }
    }
    
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledSuccess() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(chatId: 100), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.selectedOccurrence = scheduleMeetingOccurence
        viewModel.displayOccurrences = [scheduleMeetingOccurence]
        viewModel.occurrences = [ScheduledMeetingOccurrenceEntity()]
        viewModel.cancelScheduledMeetingOccurrence()
        evaluate { self.router.showSuccessMessage_calledTimes == 1 }
    }
    
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledError() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduleMeetingError: ScheduleMeetingErrorEntity.generic)
        let viewModel = ScheduledMeetingOccurrencesViewModel(router: router, scheduledMeeting: ScheduledMeetingEntity(), scheduledMeetingUseCase: scheduledMeetingUseCase, chatRoomUseCase: chatRoomUseCase, chatRoomAvatarViewModel: nil)
        viewModel.selectedOccurrence = scheduleMeetingOccurence
        viewModel.displayOccurrences = [scheduleMeetingOccurence]
        viewModel.occurrences = [ScheduledMeetingOccurrenceEntity()]
        viewModel.cancelScheduledMeetingOccurrence()
        evaluate {
            self.router.showErrorMessage_calledTimes == 1
        }
    }
    
    // MARK: - Private methods
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
}

final class MockScheduledMeetingOccurrencesRouter: ScheduledMeetingOccurrencesRouting {
    var showErrorMessage_calledTimes = 0
    var showSuccessMessage_calledTimes = 0
    var showSuccessMessageAndDismiss_calledTimes = 0
    lazy var occurrencePublisher = PassthroughSubject<ScheduledMeetingOccurrenceEntity, Never>()
    
    func showErrorMessage(_ message: String) {
        showErrorMessage_calledTimes += 1
    }
    
    func showSuccessMessage(_ message: String) {
        showSuccessMessage_calledTimes += 1
    }
    
    func showSuccessMessageAndDismiss(_ message: String) {
        showSuccessMessageAndDismiss_calledTimes += 1
    }
    
    func edit(occurrence: ScheduledMeetingOccurrenceEntity) -> AnyPublisher<ScheduledMeetingOccurrenceEntity, Never> {
        occurrencePublisher.eraseToAnyPublisher()
    }
}
