import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class FutureMeetingRoomViewModelTests: XCTestCase {
    
    private let router = MockChatRoomsListRouter()
    private let chatUseCase = MockChatUseCase()
    private let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: 100))
    private let callUseCase = MockCallUseCase(call: CallEntity(chatId: 100, callId: 1))
    
    func testComputedProperty_title() {
        let title = "Meeting Title"
        let scheduledMeeting = ScheduledMeetingEntity(title: title)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssert(viewModel.title == title)
    }
    
    func testComputedProperty_unreadChatsCount() {
        let unreadMessagesCount = 10
        let chatRoomEntity = ChatRoomEntity(unreadCount: unreadMessagesCount)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase)
        XCTAssertTrue(viewModel.unreadCountString == "\(unreadMessagesCount)")
    }
    
    func testComputedProperty_noUnreadChatsCount() {
        let viewModel = FutureMeetingRoomViewModel()
        XCTAssertTrue(viewModel.unreadCountString.isEmpty)
    }
    
    func testComputedProperty_noLastMessageTimestampAvailable() {
        let viewModel = FutureMeetingRoomViewModel()
        XCTAssertTrue(viewModel.lastMessageTimestamp == nil)
    }
    
    func testComputedProperty_lastMessageTimestampToday() {
        guard let date = Calendar
            .autoupdatingCurrent
            .date(bySettingHour: 0, minute: 1, second: 0, of: Date()) else {
            return
        }
        
        let chatListItem = ChatListItemEntity(lastMessageDate: date)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.lastMessageTimestamp == "00:01")
    }
    
    func testComputedProperty_lastMessageYesterday() {
        guard let today = Calendar
            .autoupdatingCurrent
            .date(bySettingHour: 0, minute: 1, second: 0, of: Date()),
              let yesterday = Calendar
            .autoupdatingCurrent
            .date(byAdding: .day, value: -1, to: today) else {
            return
        }
        
        let chatListItem = ChatListItemEntity(lastMessageDate: yesterday)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.lastMessageTimestamp == DateFormatter.fromTemplate("EEE").localisedString(from: yesterday))
    }
    
    func testComputedProperty_lastMessageReceivedSixDaysBack() {
        guard let today = Calendar
            .autoupdatingCurrent
            .date(bySettingHour: 0, minute: 1, second: 0, of: Date()),
              let pastDate = Calendar
            .autoupdatingCurrent
            .date(byAdding: .day, value: -6, to: today) else {
            return
        }
        
        let chatListItem = ChatListItemEntity(lastMessageDate: pastDate)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.lastMessageTimestamp == DateFormatter.fromTemplate("EEE").localisedString(from: pastDate))
    }
    
    func testComputedProperty_lastMessageTimestampReceivedSevenDaysBack() {
        guard let today = Calendar
            .autoupdatingCurrent
            .date(bySettingHour: 0, minute: 1, second: 0, of: Date()),
              let pastDate = Calendar
            .autoupdatingCurrent
            .date(byAdding: .day, value: -7, to: today) else {
            return
        }
        
        let chatListItem = ChatListItemEntity(lastMessageDate: pastDate)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.lastMessageTimestamp == DateFormatter.fromTemplate("ddyyMM").localisedString(from: pastDate))
    }
    
    func testComputedProperty_lastMessageTimestampReceivedMoreThanSevenDaysBack() {
        guard let today = Calendar
            .autoupdatingCurrent
            .date(bySettingHour: 0, minute: 1, second: 0, of: Date()),
              let pastDate = Calendar
            .autoupdatingCurrent
            .date(byAdding: .day, value: -10, to: today) else {
            return
        }
        
        let chatListItem = ChatListItemEntity(lastMessageDate: pastDate)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.lastMessageTimestamp == DateFormatter.fromTemplate("ddyyMM").localisedString(from: pastDate))
    }
    
    func testStartOrJoinCallActionTapped_startCall() {
        chatUseCase.isCallActive = false
        callUseCase.callCompletion = .success(callUseCase.call)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    func testStartOrJoinCallActionTapped_startCallError() {
        chatUseCase.isCallActive = false
        callUseCase.callCompletion = .failure(.generic)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.showCallError_calledTimes == 1)
    }
    
    func testStartOrJoinCallActionTapped_startCallTooManyParticipants() {
        chatUseCase.isCallActive = false
        callUseCase.callCompletion = .failure(.tooManyParticipants)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.showCallError_calledTimes == 1)
    }
    
    func testStartOrJoinCallActionTapped_joinCall() {
        chatUseCase.isCallActive = true
        callUseCase.callCompletion = .success(callUseCase.call)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    func testStartOrJoinCallActionTapped_joinCallError() {
        chatUseCase.isCallActive = true
        callUseCase.callCompletion = .failure(.generic)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.showCallError_calledTimes == 1)
    }
    
    func testStartOrJoinCallActionTapped_joinCallTooManyParticipants() {
        chatUseCase.isCallActive = true
        callUseCase.callCompletion = .failure(.tooManyParticipants)
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.showCallError_calledTimes == 1)
    }
    
    func testTime_forOneOffMeeting_shouldMatch() throws {
        let dateSet = try randomDateSet()
        let scheduledMeeting = ScheduledMeetingEntity(startDate: dateSet.startDate, endDate: dateSet.endDate)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        shouldMatch(time: time(for: dateSet), inFutureMeetingRoomViewModel: viewModel)
    }
    
    func testTime_forRecurringMeeting_shouldMatch() throws {
        let dateSet = try randomDateSet()
        let nextOccurrence = ScheduledMeetingOccurrenceEntity(startDate: dateSet.startDate, endDate: dateSet.endDate)
        let viewModel = FutureMeetingRoomViewModel(nextOccurrence: nextOccurrence)
        shouldMatch(time: time(for: dateSet), inFutureMeetingRoomViewModel: viewModel)
    }
    
    // MARK: - Private methods
    
    private func shouldMatch(time: String, inFutureMeetingRoomViewModel futureMeetingRoomViewModel: FutureMeetingRoomViewModel) {
        let predicate = NSPredicate { _, _ in
            futureMeetingRoomViewModel.time == time
        }
        
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 10)
    }
    
    private func randomDateSet() throws -> (startDate: Date, endDate: Date) {
        let randomDay = UInt.random(in: 1...31)
        let startDate = try XCTUnwrap(SampleDate(day: randomDay, hour: 09, minute: 10))
        let endDate = try XCTUnwrap(SampleDate(day: randomDay, hour: 10, minute: 10))
        return (startDate, endDate)
    }
    
    private func time(for dateSet: (startDate: Date, endDate: Date) ) -> String {
        "\(self.time(for: dateSet.startDate)) - \(self.time(for: dateSet.endDate))"
    }
    
    private func SampleDate(day: UInt, hour: UInt, minute: UInt) -> Date? {
        guard day > 0, day <= 31, hour <= 24, minute <= 60 else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let dayString = String(format: "%02d", day)
        let hourString = String(format: "%02d", hour)
        let minuteString = String(format: "%02d", minute)
        return dateFormatter.date(from: "\(dayString)/05/2023 \(hourString):\(minuteString)")
    }
    
    private func time(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}
