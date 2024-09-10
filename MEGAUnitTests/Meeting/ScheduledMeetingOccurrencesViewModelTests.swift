import Combine
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ScheduledMeetingOccurrencesViewModelTests: XCTestCase {
    
    @MainActor
    struct Harness {
        let router = MockScheduledMeetingOccurrencesRouter()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: 100))
        let sut: ScheduledMeetingOccurrencesViewModel
        let scheduledMeetingUseCase: MockScheduledMeetingUseCase
        
        init(
            meetingsList: [ScheduledMeetingEntity] = [],
            meetingError: ScheduleMeetingErrorEntity? = nil
        ) {
            scheduledMeetingUseCase = MockScheduledMeetingUseCase(
                scheduledMeetingsList: meetingsList,
                scheduleMeetingError: meetingError
            )
            sut = ScheduledMeetingOccurrencesViewModel(
                router: router,
                scheduledMeeting: ScheduledMeetingEntity(),
                scheduledMeetingUseCase: scheduledMeetingUseCase,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomAvatarViewModel: nil
            )
        }
        
        func makeOccurrence() -> ScheduleMeetingOccurrence {
            .init(
                id: "1",
                date: "2023/6/12",
                title: "Meeting Title",
                time: "12:00"
            )
        }
        
        func assignOccurence() {
            let occurrence = makeOccurrence()
            sut.selectedOccurrence = occurrence
            sut.displayOccurrences = [occurrence]
            sut.occurrences = [ScheduledMeetingOccurrenceEntity()]
        }
    }

    @MainActor
    func test_cancelEntityScheduledMeeting_meetingCancelledSuccess() async {
        let harness = Harness(meetingsList: [ScheduledMeetingEntity()])
        await harness.sut.cancelScheduledMeeting()
        evaluate { harness.router.showSuccessMessageAndDismiss_calledTimes == 1 }
    }
    
    @MainActor
    func test_cancelEntireScheduledMeeting_meetingCancelledError() async {
        let harness = Harness(meetingError: ScheduleMeetingErrorEntity.generic)
        await harness.sut.cancelScheduledMeeting()
        evaluate { harness.router.showErrorMessage_calledTimes == 1 }
    }
    
    @MainActor
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledSuccess() async {
        let harness = Harness(meetingsList: [ScheduledMeetingEntity()])
        harness.assignOccurence()
        await harness.sut.cancelScheduledMeetingOccurrence()
        evaluate { harness.router.showSuccessMessage_calledTimes == 1 }
    }
    
    @MainActor
    func test_cancelScheduledMeetingOccurrence_occurrenceCancelledError() async {
        let harness = Harness(meetingError: ScheduleMeetingErrorEntity.generic)
        harness.assignOccurence()
        await harness.sut.cancelScheduledMeetingOccurrence()
        evaluate {
            harness.router.showErrorMessage_calledTimes == 1
        }
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
