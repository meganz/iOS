@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGASDKRepoMock
import MEGATest
import XCTest

final class ScheduleMeetingOccurrenceNotificationTests: XCTestCase {
    
    func testLoadMessage_givenAlertTypeScheduledMeetingNew_shouldReturnCorrectMessage() async throws {
        let alert = MockUserAlert(type: .scheduledMeetingNew)
        let startDate = try XCTUnwrap(sampleDate(from: "15/01/2024 09:10"))
        let endDate = try XCTUnwrap(sampleDate(from: "15/01/2024 09:40"))
        let chatRoomUseCase = MockChatRoomUseCase(
            chatRoomEntity: ChatRoomEntity()
        )
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(
            scheduledMeetingsList: [
                ScheduledMeetingEntity(
                    startDate: startDate,
                    endDate: endDate
                )
            ]
        )
        let sut = makeScheduleMeetingOccurrenceNotification(
            alert: alert,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
        let expectedMessage = "[B] updated[/B] an occurrence to\nMon, Jan 15, 2024 from 9:10 AM to 9:40 AM"
        
        try await sut.loadMessage()
                
        XCTAssertEqual(sut.message?.string, expectedMessage)
    }
    
    // MARK: - Private
    
    private func makeScheduleMeetingOccurrenceNotification(
        alert: MEGAUserAlert = MockUserAlert(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        createAttributedStringForBoldTags: @escaping (String) -> NSAttributedString? = {string in NSAttributedString(string: string)},
        alternateMessage: @escaping () -> NSAttributedString? = { return nil },
        file: StaticString = #file,
        line: UInt = #line
    ) -> ScheduleMeetingOccurrenceNotification {
        let sut = ScheduleMeetingOccurrenceNotification(
            alert: alert,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatRoomUseCase: chatRoomUseCase,
            createAttributedStringForBoldTags: createAttributedStringForBoldTags,
            alternateMessage: alternateMessage
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
    
    // MARK: - Private methods.
    
    private func sampleDate(from string: String = "15/01/2024 09:10") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        return dateFormatter.date(from: string)
    }
}
