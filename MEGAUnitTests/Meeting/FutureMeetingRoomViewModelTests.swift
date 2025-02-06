@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGATest
import XCTest

final class FutureMeetingRoomViewModelTests: XCTestCase {
    
    private let router = MockChatRoomsListRouter()
    private let chatUseCase = MockChatUseCase()
    private let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(chatId: 100))
    private let callUseCase = MockCallUseCase(call: CallEntity(chatId: 100, callId: 1))
    
    @MainActor
    func testComputedProperty_title() {
        let title = "Meeting Title"
        let scheduledMeeting = ScheduledMeetingEntity(title: title)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        XCTAssert(viewModel.title == title)
    }
    
    @MainActor
    func testComputedProperty_unreadChatsCount() {
        let unreadMessagesCount = 10
        let chatRoomEntity = ChatRoomEntity(unreadCount: unreadMessagesCount)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoomEntity)
        let viewModel = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase)
        XCTAssertTrue(viewModel.unreadCountString == "\(unreadMessagesCount)")
    }
    
    @MainActor
    func testComputedProperty_noUnreadChatsCount() {
        let viewModel = FutureMeetingRoomViewModel()
        XCTAssertTrue(viewModel.unreadCountString.isEmpty)
    }
    
    @MainActor
    func testComputedProperty_noLastMessageTimestampAvailable() {
        let viewModel = FutureMeetingRoomViewModel()
        XCTAssertTrue(viewModel.lastMessageTimestamp == nil)
    }
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
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
    
    @MainActor
    func testStartOrJoinCallActionTapped_startCall() {
        chatUseCase.isCallInProgress = false
        let callController = MockCallController()
        
        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callController: callController)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinCallActionTapped_joinCallUserNoPresentCallKitNoRinging_startCallCalled() {
        chatUseCase.isCallInProgress = true
        callUseCase.call = CallEntity(status: .userNoPresent)
        let callController = MockCallController()

        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase, callController: callController)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinCallActionTapped_joinCallUserNoPresentCallKitRinging_answerCallCalled() {
        chatUseCase.isCallInProgress = true
        callUseCase.call = CallEntity(status: .userNoPresent)
        let callController = MockCallController()
        let callsManager = MockCallsManager()
        callsManager.addCall(CallActionSync(chatRoom: ChatRoomEntity(chatId: 100)), withUUID: .testUUID)

        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase, callController: callController, callsManager: callsManager)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(callController.answerCall_CalledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinCallActionTapped_joinCallCallAlreadyParticipating_showCallUI() {
        chatUseCase.isCallInProgress = true
        callUseCase.call = CallEntity(status: .inProgress)
        let callController = MockCallController()
        let callsManager = MockCallsManager()
        callsManager.addCall(CallActionSync(chatRoom: .testChatRoomEntity), withUUID: .testUUID)

        let viewModel = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase, callController: callController, callsManager: callsManager)

        viewModel.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinMeetingTapped_onExistsActiveCall_shouldPresentMeetingAlreadyExists() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isExistingActiveCall: true)
        let sut = FutureMeetingRoomViewModel(router: router, chatUseCase: chatUseCase)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentMeetingAlreadyExists_calledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinMeetingTapped_onNoActiveCallAndShouldOpenWaitRoom_shouldPresentWaitingRoom() {
        let router = MockChatRoomsListRouter()
        let chatRoomUseCase = MockChatRoomUseCase(shouldOpenWaitRoom: true)
        let sut = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentWaitingRoom_calledTimes == 1)
    }
    
    @MainActor
    func testTime_forOneOffMeeting_shouldMatch() throws {
        let dateSet = try randomDateSet()
        let scheduledMeeting = ScheduledMeetingEntity(startDate: dateSet.startDate, endDate: dateSet.endDate)
        let viewModel = FutureMeetingRoomViewModel(scheduledMeeting: scheduledMeeting)
        shouldMatch(time: time(for: dateSet), inFutureMeetingRoomViewModel: viewModel)
    }
    
    @MainActor
    func testTime_forRecurringMeeting_shouldMatch() throws {
        let dateSet = try randomDateSet()
        let nextOccurrence = ScheduledMeetingOccurrenceEntity(startDate: dateSet.startDate, endDate: dateSet.endDate)
        let viewModel = FutureMeetingRoomViewModel(nextOccurrence: nextOccurrence)
        shouldMatch(time: time(for: dateSet), inFutureMeetingRoomViewModel: viewModel)
    }
    
    @MainActor
    func test_cancelMeetingWithMessagesInChat_stringsShouldMatch() {
        let viewModel = FutureMeetingRoomViewModel()
        viewModel.chatHasMessages = true
        let cancelMeetingAlertData = viewModel.cancelMeetingAlertData()
        XCTAssertTrue(cancelMeetingAlertData.message == Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withMessages)
        XCTAssertTrue(cancelMeetingAlertData.primaryButtonTitle == Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withMessages)
    }
    
    @MainActor
    func test_cancelMeetingWithoutMessagesInChat_stringsShouldMatch() {
        let viewModel = FutureMeetingRoomViewModel()
        viewModel.chatHasMessages = false
        let cancelMeetingAlertData = viewModel.cancelMeetingAlertData()
        XCTAssertTrue(cancelMeetingAlertData.message == Strings.Localizable.Meetings.Scheduled.CancelAlert.Description.withoutMessages)
        XCTAssertTrue(cancelMeetingAlertData.primaryButtonTitle == Strings.Localizable.Meetings.Scheduled.CancelAlert.Option.Confirm.withoutMessages)
    }
    
    @MainActor
    func test_cancelScheduledMeeting_meetingCancelledSuccess() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let viewModel = FutureMeetingRoomViewModel(router: router, scheduledMeetingUseCase: scheduledMeetingUseCase)
        viewModel.chatHasMessages = true
        viewModel.cancelScheduledMeeting()
        evaluate { self.router.showSuccessMessage_calledTimes == 1 }
    }
    
    @MainActor
    func test_cancelScheduledMeeting_meetingCancelledError() {
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduleMeetingError: ScheduleMeetingErrorEntity.generic)
        let viewModel = FutureMeetingRoomViewModel(router: router, scheduledMeetingUseCase: scheduledMeetingUseCase)
        viewModel.cancelScheduledMeeting()
        evaluate { self.router.showErrorMessage_calledTimes == 1 }
    }
    
    @MainActor
    func testEditContextMenuOption_onOpenContextMenu_shouldShowEditOptionAtTheSecondPosition() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let tracker = MockTracker()
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
        
        let title = sut.contextMenuOptions?[safe: 1]?.title
        
        XCTAssertEqual(title, Strings.Localizable.edit)
    }
    
    @MainActor
    func testEditContextMenuOption_onEdit_shouldTrackerEvent() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let tracker = MockTracker()
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
        
        sut.contextMenuOptions?[safe: 1]?.action()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingEditMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func testEditContextMenuOption_onEdit_shouldRouteToEditScreen() {
        let router = MockChatRoomsListRouter()
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let tracker = MockTracker()
        let sut = FutureMeetingRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, tracker: tracker)
        
        sut.contextMenuOptions?[safe: 1]?.action()
        
        XCTAssertEqual(router.editMeeting_calledTimes, 1)
    }
    
    @MainActor
    func testCancelContextMenuOption_onCancel_shouldTrackerEvent() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let tracker = MockTracker()
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase, tracker: tracker)
        
        sut.contextMenuOptions?.last?.action()
        
        assertTrackAnalyticsEventCalled(
            trackedEventIdentifiers: tracker.trackedEventIdentifiers,
            with: [
                ScheduledMeetingCancelMenuItemEvent()
            ]
        )
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountLessThanZero_shouldBePositiveWithPlus() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(unreadCount: -1))
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase)

        XCTAssertEqual(sut.unreadCountString, "1+")
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountGreaterThanZeroAndLessThan100_shouldBePositiveWithoutPlus() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(unreadCount: 50))
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase)
        
        XCTAssertEqual(sut.unreadCountString, "50")
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountGreaterThan99_shouldBe99WithPlu() {
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(unreadCount: 123))
        let sut = FutureMeetingRoomViewModel(chatRoomUseCase: chatRoomUseCase)

        XCTAssertEqual(sut.unreadCountString, "99+")
    }
    
    // MARK: - Private methods
    
    private func evaluate(expression: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in expression() }
        let expectation = expectation(for: predicate, evaluatedWith: nil)
        wait(for: [expectation], timeout: 5)
    }
    
    @MainActor
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
