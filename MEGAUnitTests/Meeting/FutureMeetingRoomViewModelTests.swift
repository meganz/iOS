import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class FutureMeetingRoomViewModelTests: XCTestCase {
    
    func testComputedProperty_title() {
        let title = "Meeting Title"
        let scheduledMeeting = ScheduledMeetingEntity(title: title)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssert(viewModel.title == title)
    }
    
    func testComputedProperty_time() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        guard let startDate = dateFormatter.date(from: "2015-04-01T11:42:00") else {
            return
        }

        let endDate = startDate.advanced(by: 3600)
        
        let scheduledMeeting = ScheduledMeetingEntity(startDate: startDate, endDate: endDate)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssertTrue(viewModel.time == "11:42 AM - 12:42 PM" || viewModel.time == "11:42 - 12:42")
    }
    
    func testComputedProperty_unreadChatsCount() {
        let unreadMessagesCount = 10
        let chatListItem = ChatListItemEntity(unreadCount: unreadMessagesCount)
        let chatUseCase = MockChatUseCase(items: [chatListItem])
        let viewModel = FutureMeetingRoomViewModel(chatUseCase: chatUseCase)
        XCTAssertTrue(viewModel.unreadChatCount == unreadMessagesCount)
    }
    
    func testComputedProperty_noUnreadChatsCount() {
        let viewModel = FutureMeetingRoomViewModel()
        XCTAssertTrue(viewModel.unreadChatCount == nil)
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
    
}
